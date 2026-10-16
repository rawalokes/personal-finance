import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../../sms/mask.dart';
import '../../sms/parser.dart';
import '../../sms/sms_models.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../records.dart';
import '../undo.dart';
import 'transaction_repo.dart';

enum IngestOutcome {
  /// Not a money message, or from a sender you have not approved.
  ignored,

  /// This exact phone message is already in the inbox.
  alreadySeen,

  /// Waiting in "Needs review".
  inbox,

  /// Saved at once by the account's auto-update rule (spec §6 step 7).
  autoSaved,
}

class IngestResult {
  const IngestResult(this.outcome, {this.message, this.undo});
  final IngestOutcome outcome;
  final SmsMessage? message;

  /// Set when [outcome] is [IngestOutcome.autoSaved].
  final UndoAction? undo;
}

/// Confirming would probably count the same payment twice: ask first
/// ("Ignore duplicate" / "Save anyway").
class SmsPossibleDuplicate implements Exception {
  const SmsPossibleDuplicate(this.original);
  final SmsMessage? original;
}

/// Something must be filled in before the message can be confirmed.
class SmsNotReady implements Exception {
  const SmsNotReady(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What the Edit sheet can change.
class SmsEdit {
  const SmsEdit({
    required this.amount,
    required this.accountId,
    this.counterAccountId,
    this.loanId,
    this.partyId,
    required this.date,
    required this.time,
    required this.merchant,
    this.description,
  });

  final Paisa amount;
  final String accountId;
  final String? counterAccountId;
  final String? loanId;

  /// Who paid or was paid; only kept for income, expense and refund.
  final String? partyId;
  final IsoDate date;
  final String time;
  final String merchant;
  final String? description;
}

/// Types that have someone on the other side: who paid (income, refund)
/// or who was paid (expense).
bool hasParty(TxType t) => t == TxType.income || t == TxType.expense || t == TxType.refund;

/// The Transaction Inbox (spec §6). Messages are suggestions; only
/// [confirm] (or an account's auto-update rule) changes balances.
class SmsRepository {
  SmsRepository(this._db, this._audit, this._txns, {required this._clock, required this._newId});

  final AppDatabase _db;
  final AuditLog _audit;
  final TransactionRepository _txns;
  final Clock _clock;
  final String Function() _newId;

  Stream<List<SmsMessage>> watchAll() => (_db.select(_db.smsMessages)
        ..orderBy([(m) => OrderingTerm.desc(m.date), (m) => OrderingTerm.desc(m.time), (m) => OrderingTerm.desc(m.receivedAt)]))
      .watch()
      .map((rows) => rows.map(smsFromRow).toList());

  Future<List<SmsMessage>> list() async => (await _db.select(_db.smsMessages).get()).map(smsFromRow).toList();

  Stream<int> watchPendingCount() {
    final n = _db.smsMessages.id.count();
    return (_db.selectOnly(_db.smsMessages)
          ..addColumns([n])
          ..where(_db.smsMessages.status.isIn([SmsStatus.review.name, SmsStatus.later.name])))
        .watchSingle()
        .map((r) => r.read(n) ?? 0);
  }

  Future<SmsMessage> get(String id) async =>
      smsFromRow(await (_db.select(_db.smsMessages)..where((m) => m.id.equals(id))).getSingle());

  Future<SmsMessage?> find(String id) async {
    final row = await (_db.select(_db.smsMessages)..where((m) => m.id.equals(id))).getSingleOrNull();
    return row == null ? null : smsFromRow(row);
  }

  /// Active banks & wallets with their sender IDs (`Sender A, B · note`).
  Future<List<SmsBank>> banks() async {
    final rows = await (_db.select(_db.configItems)
          ..where((c) => c.listKey.equals(ConfigList.banks) & c.active.equals(true)))
        .get();
    return [
      for (final b in rows)
        if (RegExp(r'Sender\s+([^·]+)').firstMatch(b.description) case final m?)
          SmsBank(b.name, [for (final id in splitSenders(m[1]!)) id.split(RegExp(r'\s')).first]),
    ];
  }

  /// Approved sender IDs: every ID of the active banks & wallets, and every
  /// account's SMS senders.
  Future<List<String>> trustedSenders() async {
    final accounts = await _db.select(_db.accounts).get();
    return {
      for (final b in await banks()) ...b.senders,
      for (final a in accounts)
        if (!a.archived) ...splitSenders(a.smsSender ?? ''),
    }.toList();
  }

  Future<SmsContext> context() async => SmsContext(
        accounts: (await _db.select(_db.accounts).get()).map(accountFromRow).toList(),
        loans: (await _db.select(_db.loans).get()).map(loanFromRow).toList(),
        categories: (await _db.select(_db.expenseCategories).get()).map(categoryFromRow).toList(),
        incomeTypes: (await _db.select(_db.incomeTypes).get()).map(incomeTypeFromRow).toList(),
        history: ((await (_db.select(_db.transactions)
                      ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.time)])
                      ..limit(500))
                    .get())
                .map(txnFromRow)
                .toList()),
        trustedSenders: await trustedSenders(),
        banks: await banks(),
      );

  static String _stamp(DateTime d) =>
      '${toIsoDate(d)}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  /// Spec §6 steps 2–7 for one incoming message.
  Future<IngestResult> ingest({
    required String sender,
    required String body,
    required DateTime receivedAt,
    String? sourceKey,
    bool allowAutoSave = true,
  }) async {
    if (sourceKey != null) {
      final seen = await (_db.select(_db.smsMessages)..where((m) => m.sourceKey.equals(sourceKey))).getSingleOrNull();
      if (seen != null) return const IngestResult(IngestOutcome.alreadySeen);
    }
    final ctx = await context();
    final draft = parseSms(sender: sender, body: body, receivedAt: receivedAt, ctx: ctx);
    if (draft == null) return const IngestResult(IngestOutcome.ignored);
    final hash = smsHash(sender, body);
    final stamp = _stamp(receivedAt);

    // The same physical message arriving twice (live broadcast, then an
    // inbox scan) is one message: same text, same timestamp to the second.
    // A bank repeating the text later is a possible duplicate instead.
    final sameText = await (_db.select(_db.smsMessages)..where((m) => m.bodyHash.equals(hash))).get();
    if (sameText.any((m) => m.receivedAt == stamp)) return const IngestResult(IngestOutcome.alreadySeen);

    // Spec §5.6: same account, amount and direction within 10 minutes, or
    // the same text. Rejected messages don't count.
    final earlier = await (_db.select(_db.smsMessages)
          ..where((m) => m.status.isNotIn([SmsStatus.rejected.name]) & m.date.isBiggerOrEqualValue(toIsoDate(parseIsoDate(draft.date).subtract(const Duration(days: 1))))))
        .get();
    SmsFingerprint fp(SmsRow r) => SmsFingerprint(
          id: r.id,
          accountId: r.accountId,
          amount: r.amount,
          direction: r.direction == 'credit' ? Direction.credit : Direction.debit,
          receivedAt: DateTime.parse('${r.date}T${r.time}:00'),
          bodyHash: r.bodyHash,
        );
    final id = _newId();
    final dupOf = findDuplicate(
      SmsFingerprint(
        id: id,
        accountId: draft.accountId,
        amount: draft.amount,
        direction: draft.direction,
        receivedAt: DateTime.parse('${draft.date}T${draft.time}:00'),
        bodyHash: hash,
      ),
      earlier.map(fp),
    );

    // Two sides of one movement between own accounts: Nabil "debited … to
    // ##2290" and NIC "credited … from ##4821", or a card payment reported
    // by both the bank and the card. Saving both would count it twice.
    final pairOf = dupOf ??
        (draft.type == TxType.transfer || draft.type == TxType.ccPayment
            ? earlier.where((r) {
                if (r.amount != draft.amount || !{'transfer', 'cc_payment'}.contains(r.type)) return false;
                final at = DateTime.parse('${r.date}T${r.time}:00');
                final mine = DateTime.parse('${draft.date}T${draft.time}:00');
                if (at.difference(mine).abs() > const Duration(minutes: 30)) return false;
                final crossed = r.accountId != null && r.accountId == draft.counterAccountId && r.counterAccountId == draft.accountId;
                final sameCard = draft.type == TxType.ccPayment && r.counterAccountId == draft.counterAccountId && r.accountId != draft.accountId;
                return crossed || sameCard;
              }).firstOrNull?.id
            : null);

    final message = SmsMessage(
      id: id,
      sender: sender,
      receivedAt: stamp,
      maskedBody: draft.maskedBody,
      bodyHash: hash,
      sourceKey: sourceKey,
      institution: draft.institution,
      accountId: draft.accountId,
      direction: draft.direction,
      amount: draft.amount,
      merchant: draft.merchant,
      date: draft.date,
      time: draft.time,
      type: draft.type,
      categoryId: draft.categoryId,
      incomeTypeId: draft.incomeTypeId,
      counterAccountId: draft.counterAccountId,
      loanId: draft.loanId,
      confidence: pairOf != null ? SmsConfidence.low : draft.confidence,
      reason: dupOf != null
          ? 'Same amount and account as a message a few minutes earlier. ${draft.reason}'
          : pairOf != null
              ? 'Looks like the other side of a movement already in the inbox. ${draft.reason}'
              : draft.reason,
      duplicateOfId: pairOf,
    );
    try {
      await _db.transaction(() async {
        await _db.into(_db.smsMessages).insert(smsToCompanion(message));
        await _audit.write(
          action: 'sms.detected',
          entity: 'sms',
          entityId: id,
          summary: 'New SMS detected: ${message.merchant}',
          actor: AuditActor.sms,
        );
      });
    } on Object catch (e) {
      // The same message arrived twice at once (broadcast and scan).
      if (e.toString().contains('UNIQUE constraint failed')) return const IngestResult(IngestOutcome.alreadySeen);
      rethrow;
    }

    final account = ctx.accounts.where((a) => a.id == draft.accountId).firstOrNull;
    if (allowAutoSave &&
        shouldAutoConfirm(
      account: account,
      confidence: message.confidence,
      possibleDuplicate: pairOf != null,
      suggestedType: message.type,
    )) {
      try {
        final undo = await _confirm(message, actor: AuditActor.sms, auto: true);
        return IngestResult(IngestOutcome.autoSaved, message: await get(id), undo: undo);
      } on Object {
        // Anything odd goes to review instead; the inbox is the safe place.
      }
    }
    return IngestResult(IngestOutcome.inbox, message: message);
  }

  Future<UndoAction> confirm(String id, {bool force = false}) async {
    final m = await get(id);
    if (!m.pending) throw const SmsNotReady('This message was already handled.');
    if (m.duplicateOfId != null && !force) throw SmsPossibleDuplicate(await find(m.duplicateOfId!));
    return _confirm(m, actor: AuditActor.user, auto: false);
  }

  Future<UndoAction> _confirm(SmsMessage m, {required AuditActor actor, required bool auto}) async {
    if (m.amount <= 0) throw const SmsNotReady('Enter a valid amount before confirming.');
    final accountId = m.accountId;
    if (accountId == null) throw const SmsNotReady('Pick the account this message is about. Tap Edit.');
    final needsCounter = {TxType.transfer, TxType.cashWithdrawal, TxType.ccPayment}.contains(m.type);
    if (needsCounter && (m.counterAccountId == null || m.counterAccountId == accountId)) {
      throw const SmsNotReady('Choose the other account for this transaction. Tap Edit.');
    }
    final needsLoan = m.type == TxType.loanRepayment || m.type == TxType.loanDisbursement;
    Loan? loan;
    if (needsLoan) {
      final row = m.loanId == null ? null : await (_db.select(_db.loans)..where((l) => l.id.equals(m.loanId!))).getSingleOrNull();
      if (row == null) throw const SmsNotReady('Pick which loan this belongs to. Tap Edit.');
      loan = loanFromRow(row);
    }
    RepaymentSplit? split;
    if (m.type == TxType.loanRepayment) {
      if (m.amount > payoffAmount(loan!)) throw const SmsNotReady('This is more than you owe on the loan. Check the amount.');
      split = splitRepayment(loan, m.amount);
    }
    final isExpenseLike = m.type == TxType.expense || m.type == TxType.refund;
    final tx = Txn(
      id: _newId(),
      date: m.date,
      time: m.time,
      title: m.type == TxType.loanRepayment ? '${loan!.name} installment' : m.merchant,
      type: m.type,
      direction: m.direction,
      accountId: accountId,
      counterAccountId: needsCounter ? m.counterAccountId : null,
      categoryId: isExpenseLike ? m.categoryId : null,
      incomeTypeId: m.type == TxType.income ? m.incomeTypeId : null,
      loanId: needsLoan ? loan!.id : null,
      partyId: hasParty(m.type) ? m.partyId : null,
      amount: m.amount,
      principal: split?.principal,
      interest: split?.interest,
      source: TxSource.sms,
      smsId: m.id,
      note: (m.description ?? '').trim().isEmpty ? null : m.description!.trim(),
    );
    late UndoAction undoTx;
    await _db.transaction(() async {
      // Re-read inside the transaction: a second tap must not save twice.
      final now = await get(m.id);
      if (!now.pending) throw const SmsNotReady('This message was already handled.');
      undoTx = await _txns.add(
        tx,
        summary: '${auto ? 'Auto-saved from SMS' : 'Confirmed SMS'}: ${tx.title} · ${auditMoney(tx.amount)}',
        actor: actor,
      );
      await _write(m.copyWith(status: SmsStatus.approved, transactionId: tx.id, autoSaved: auto));
    });
    return UndoAction(() => _db.transaction(() async {
          await undoTx();
          await _write(m.copyWith(status: SmsStatus.review, autoSaved: false, clearTransaction: true));
        }));
  }

  Future<void> _write(SmsMessage m) =>
      (_db.update(_db.smsMessages)..where((r) => r.id.equals(m.id))).write(smsToCompanion(m));

  Future<UndoAction> _setStatus(String id, SmsStatus status, String action, String summary) async {
    final before = await get(id);
    await _db.transaction(() async {
      await _write(before.copyWith(status: status));
      await _audit.write(action: action, entity: 'sms', entityId: id, summary: summary);
    });
    return UndoAction(() => _db.transaction(() async {
          await _write(before);
          await _audit.write(action: 'sms.undo', entity: 'sms', entityId: id, summary: 'Undid the last change');
        }));
  }

  /// Ignore: never counted anywhere; can be restored later.
  Future<UndoAction> reject(String id) async {
    final m = await get(id);
    return _setStatus(id, SmsStatus.rejected, 'sms.reject', 'Ignored SMS: ${m.merchant} · ${auditMoney(m.amount)}');
  }

  /// Bulk ignore: every still-pending message in [ids], in one go and with
  /// one undo. Ones handled meanwhile are left as they are.
  Future<UndoAction> rejectMany(Iterable<String> ids) async {
    final before = <SmsMessage>[];
    await _db.transaction(() async {
      for (final id in ids) {
        final m = await get(id);
        if (!m.pending) continue;
        before.add(m);
        await _write(m.copyWith(status: SmsStatus.rejected));
        await _audit.write(action: 'sms.reject', entity: 'sms', entityId: id, summary: 'Ignored SMS: ${m.merchant} · ${auditMoney(m.amount)}');
      }
    });
    return UndoAction(() => _db.transaction(() async {
          for (final m in before) {
            await _write(m);
            await _audit.write(action: 'sms.undo', entity: 'sms', entityId: m.id, summary: 'Undid the last change');
          }
        }));
  }

  Future<UndoAction> later(String id) => _setStatus(id, SmsStatus.later, 'sms.later', 'Moved an SMS to review later');

  Future<UndoAction> restore(String id) => _setStatus(id, SmsStatus.review, 'sms.restore', 'Restored an SMS to review');

  Future<void> edit(String id, SmsEdit e) async {
    final m = await get(id);
    await _db.transaction(() async {
      await _write(SmsMessage(
        id: m.id,
        sender: m.sender,
        receivedAt: m.receivedAt,
        maskedBody: m.maskedBody,
        bodyHash: m.bodyHash,
        sourceKey: m.sourceKey,
        institution: m.institution,
        accountId: e.accountId,
        direction: m.direction,
        amount: e.amount,
        merchant: e.merchant.trim().isEmpty ? m.merchant : e.merchant.trim(),
        date: e.date,
        time: e.time,
        type: m.type,
        categoryId: m.categoryId,
        incomeTypeId: m.incomeTypeId,
        counterAccountId: e.counterAccountId,
        loanId: e.loanId,
        partyId: hasParty(m.type) ? e.partyId : null,
        confidence: m.confidence,
        reason: m.reason,
        suggestedBy: m.suggestedBy,
        status: m.status,
        duplicateOfId: m.duplicateOfId,
        transactionId: m.transactionId,
        edited: true,
        autoSaved: m.autoSaved,
        description: e.description,
      ));
      await _audit.write(action: 'sms.edit', entity: 'sms', entityId: id, summary: 'Edited SMS details: ${e.merchant}');
    });
  }

  /// Change the suggested type; fills sensible defaults the new type needs.
  Future<void> setType(String id, TxType type) async {
    final m = await get(id);
    var next = m.copyWith(type: type, edited: true);
    if (type == TxType.expense || type == TxType.refund) {
      final ok = m.categoryId != null &&
          await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(m.categoryId!))).getSingleOrNull() != null;
      if (!ok) next = next.copyWith(categoryId: 'other');
    }
    if (type == TxType.income && m.incomeTypeId == null) next = next.copyWith(incomeTypeId: 'other_inc');
    final accounts = (await _db.select(_db.accounts).get()).map(accountFromRow).where((a) => !a.archived).toList();
    if (type == TxType.transfer && (m.counterAccountId == null || m.counterAccountId == m.accountId)) {
      final other = accounts
          .where((a) => a.id != m.accountId && a.group != AccountGroup.liability && a.group != AccountGroup.locked)
          .firstOrNull;
      next = other == null ? next.copyWith(clearCounter: true) : next.copyWith(counterAccountId: other.id);
    }
    if (type == TxType.cashWithdrawal) {
      final cash = accounts.where((a) => a.kind == AccountKind.cash).firstOrNull;
      if (cash != null) next = next.copyWith(counterAccountId: cash.id);
    }
    if (type == TxType.ccPayment) {
      final card = accounts.where((a) => a.kind == AccountKind.creditCard).firstOrNull;
      if (card != null) next = next.copyWith(counterAccountId: card.id);
    }
    if ((type == TxType.loanRepayment || type == TxType.loanDisbursement) && m.loanId == null) {
      final loan = (await _db.select(_db.loans).get()).where((l) => !l.closed).firstOrNull;
      if (loan != null) next = next.copyWith(loanId: loan.id);
    }
    await _db.transaction(() async {
      await _write(next);
      await _audit.write(action: 'sms.type', entity: 'sms', entityId: id, summary: 'Changed type to ${type.wire}: ${m.merchant}');
    });
  }

  /// The category (expense, refund) or income type (income).
  Future<void> setCategory(String id, String categoryOrIncomeTypeId) async {
    final m = await get(id);
    await _write(m.type == TxType.income
        ? m.copyWith(incomeTypeId: categoryOrIncomeTypeId, edited: true)
        : m.copyWith(categoryId: categoryOrIncomeTypeId, edited: true));
  }

  /// An AI suggestion replaces the rules' suggestion, marked as AI; it is
  /// still only a suggestion (spec §9.4 guardrail 3).
  Future<void> applyAiSuggestion(String id, {required TxType type, String? categoryId, String? incomeTypeId, String? counterAccountId, required SmsConfidence confidence, required String reason}) async {
    final m = await get(id);
    await _db.transaction(() async {
      await _write(m.copyWith(
        type: type,
        categoryId: categoryId,
        incomeTypeId: incomeTypeId,
        counterAccountId: counterAccountId,
        confidence: confidence,
        reason: reason,
        suggestedBy: SmsSuggestedBy.ai,
      ));
      await _audit.write(action: 'sms.ai_suggestion', entity: 'sms', entityId: id, summary: 'AI suggested a type for ${m.merchant}', actor: AuditActor.ai);
    });
  }

  /// Keeps the clock in use for future stamping needs (receivedAt for pasted
  /// messages).
  DateTime now() => _clock.now();
}
