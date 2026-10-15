import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../records.dart';
import '../undo.dart';
import 'transaction_repo.dart';

/// The account types offered in the Add account sheet, with the engine kind,
/// group and seeded account-type id (config list `account_types`) each maps to.
enum AccountTypeChoice {
  wallet('Digital wallet', AccountKind.wallet, AccountGroup.liquid, 'a4'),
  bank('Bank account', AccountKind.bank, AccountGroup.liquid, 'a1'),
  savings('Savings account', AccountKind.savings, AccountGroup.reserved, 'a2'),
  cash('Cash', AccountKind.cash, AccountGroup.liquid, 'a3'),
  creditCard('Credit card', AccountKind.creditCard, AccountGroup.liability, 'a6'),
  fixedDeposit('Fixed deposit', AccountKind.fixedDeposit, AccountGroup.locked, 'a5');

  const AccountTypeChoice(this.label, this.kind, this.group, this.accountTypeId);
  final String label;
  final AccountKind kind;
  final AccountGroup group;
  final String accountTypeId;
}

class NewAccountInput {
  const NewAccountInput({
    required this.name,
    required this.type,
    required this.balance,
    this.lastDigits = '',
    this.smsSender = '',
    this.autoUpdateFromSms = false,
  });

  final String name;
  final AccountTypeChoice type;

  /// Current balance, or the amount owed for a credit card.
  final Paisa balance;
  final String lastDigits;
  final String smsSender;
  final bool autoUpdateFromSms;
}

class ReconcileResult {
  const ReconcileResult({required this.difference, this.undo});

  /// Actual minus what Paisa showed. 0 = balances matched.
  final Paisa difference;

  /// Null when nothing was adjusted.
  final UndoAction? undo;
}

/// Last 4 digits of whatever was typed, or null.
String? maskDigits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
}

/// "eSewa — personal" → "eSewa"; "Nabil Bank — savings" + 4821 → "Nabil Bank ••4821".
/// Falls back to the full name if that short name is already taken.
String deriveShortName(String name, String? mask, Iterable<String> taken) {
  final base = name.trim().split(' — ').first.split(' ').where((w) => w.isNotEmpty).take(2).join(' ');
  final short = mask == null ? base : '$base ••$mask';
  return taken.contains(short) ? name.trim() : short;
}

class AccountRepository {
  AccountRepository(this._db, this._audit, this._transactions, {required this._clock, required this._newId});

  final AppDatabase _db;
  final AuditLog _audit;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGen _newId;

  /// Every account, archived ones included, in display order.
  Stream<List<Account>> watchAll() => (_db.select(_db.accounts)
        ..orderBy([(a) => OrderingTerm.asc(a.sortOrder), (a) => OrderingTerm.asc(a.rowId)]))
      .watch()
      .map((rows) => rows.map(accountFromRow).toList());

  Future<Account> get(String id) async =>
      accountFromRow(await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle());

  /// Adds an account with its current balance. Auto-update is only kept on
  /// when an SMS sender is given (nothing could match otherwise). A sender
  /// not yet known is added to the Banks & wallets list.
  Future<(Account, UndoAction)> add(NewAccountInput input) async {
    final sender = input.smsSender.trim();
    final mask = maskDigits(input.lastDigits);
    final name = input.name.trim();
    late Account account;
    String? addedBankId;
    await _db.transaction(() async {
      final existing = await _db.select(_db.accounts).get();
      final shortName = deriveShortName(name, mask, existing.map((a) => a.shortName));
      account = Account(
        id: _newId(),
        name: name,
        shortName: shortName,
        institution: shortName.split(' ••').first,
        accountTypeId: input.type.accountTypeId,
        group: input.type.group,
        kind: input.type.kind,
        maskedNumber: mask,
        smsSender: sender.isEmpty ? null : sender,
        autoUpdateFromSms: input.autoUpdateFromSms && sender.isNotEmpty,
        openingBalance: input.balance,
        balance: input.balance,
        lastReconciled: _clock.today(),
      );
      final nextOrder = existing.fold<int>(-1, (m, a) => a.sortOrder > m ? a.sortOrder : m) + 1;
      await _db.into(_db.accounts).insert(accountToCompanion(account, sortOrder: nextOrder));

      if (sender.isNotEmpty) {
        final banks = await (_db.select(_db.configItems)..where((c) => c.listKey.equals(ConfigList.banks))).get();
        if (!banks.any((b) => b.description.contains(sender))) {
          addedBankId = _newId();
          await _db.into(_db.configItems).insert(configItemToCompanion(
                ConfigItem(
                  id: addedBankId!,
                  listKey: ConfigList.banks,
                  name: account.institution!,
                  description: 'Sender $sender${mask == null ? '' : ' · ##$mask'}',
                ),
                sortOrder: banks.length,
              ));
        }
      }
      await _audit.write(
        action: 'account.add',
        entity: 'account',
        entityId: account.id,
        summary: 'Added account $name${sender.isEmpty ? '' : ' (SMS sender $sender)'}',
      );
    });

    final undo = UndoAction(() => _db.transaction(() async {
          final used = await (_db.select(_db.transactions)
                ..where((t) => t.accountId.equals(account.id) | t.counterAccountId.equals(account.id))
                ..limit(1))
              .get();
          if (used.isEmpty) {
            await (_db.delete(_db.accounts)..where((a) => a.id.equals(account.id))).go();
            if (addedBankId != null) {
              await (_db.delete(_db.configItems)..where((c) => c.id.equals(addedBankId!))).go();
            }
          } else {
            // It already has activity: hide it rather than lose history.
            await _setArchived(account.id, true);
          }
          await _audit.write(action: 'account.undo', entity: 'account', entityId: account.id, summary: 'Undid the last change');
        }));
    return (account, undo);
  }

  /// Hides the account from totals and pickers; history is kept.
  Future<UndoAction> archive(String id) async {
    final a = await get(id);
    await _db.transaction(() async {
      await _setArchived(id, true);
      await _audit.write(action: 'account.archive', entity: 'account', entityId: id, summary: 'Archived account ${a.name}');
    });
    return UndoAction(() => _db.transaction(() async {
          await _setArchived(id, false);
          await _audit.write(action: 'account.undo', entity: 'account', entityId: id, summary: 'Undid the last change');
        }));
  }

  Future<void> setAutoUpdate(String id, bool on) async {
    final a = await get(id);
    await _db.transaction(() async {
      await (_db.update(_db.accounts)..where((r) => r.id.equals(id)))
          .write(AccountsCompanion(autoUpdateFromSms: Value(on)));
      await _audit.write(
        action: 'account.auto_update',
        entity: 'account',
        entityId: id,
        summary: '${on ? 'Turned on' : 'Turned off'} automatic SMS updates for ${a.shortName}',
      );
    });
  }

  /// Compares [actual] (the balance, or amount owed for a card, from the
  /// bank) with Paisa's balance. A difference is booked as an `adjustment`
  /// transaction, never income or expense.
  Future<ReconcileResult> reconcile(String id, Paisa actual) async {
    final a = await get(id);
    final previous = a.lastReconciled;
    final difference = actual - a.balance;
    if (difference == 0) {
      await _db.transaction(() async {
        await _setReconciled(id, _clock.today());
        await _audit.write(
          action: 'account.reconcile',
          entity: 'account',
          entityId: id,
          summary: 'Reconciled ${a.shortName} — no difference',
        );
      });
      return const ReconcileResult(difference: 0);
    }
    // For a liability the engine treats a positive adjustment as money in,
    // which lowers the debt, so owing more needs a negative adjustment.
    final adjustment = a.group == AccountGroup.liability ? -difference : difference;
    final txUndo = await _transactions.add(
      Txn(
        id: _newId(),
        date: _clock.today(),
        time: _clock.hhmm(),
        title: 'Reconciliation adjustment',
        type: TxType.adjustment,
        accountId: id,
        amount: adjustment,
      ),
      summary: 'Reconciled ${a.shortName} · adjustment ${difference > 0 ? '+' : ''}${auditMoney(difference)}',
    );
    await _setReconciled(id, _clock.today());
    return ReconcileResult(
      difference: difference,
      undo: UndoAction.combine([txUndo, UndoAction(() => _setReconciled(id, previous))]),
    );
  }

  Future<void> _setArchived(String id, bool archived) =>
      (_db.update(_db.accounts)..where((r) => r.id.equals(id))).write(AccountsCompanion(archived: Value(archived)));

  Future<void> _setReconciled(String id, IsoDate? date) => (_db.update(_db.accounts)..where((r) => r.id.equals(id)))
      .write(AccountsCompanion(lastReconciled: Value(date)));
}
