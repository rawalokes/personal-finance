import 'package:drift/drift.dart';

import '../../finance/finance.dart';
import '../audit_log.dart';
import '../clock.dart';
import '../db/database.dart';
import '../mappers.dart';
import '../undo.dart';
import 'transaction_repo.dart';

/// What the loan form collects. A null [ratePct] means "Not entered".
/// A repayment above the loan's payoff amount (outstanding + this period's
/// interest).
class RepaymentTooLarge implements Exception {
  const RepaymentTooLarge(this.max);
  final Paisa max;
}

class LoanInput {
  const LoanInput({
    required this.loanTypeId,
    required this.name,
    required this.lender,
    required this.principal,
    required this.outstanding,
    required this.ratePct,
    required this.method,
    required this.installment,
    required this.frequency,
    this.startDate,
    this.maturityDate,
    this.nextDueDate,
    this.repaymentAccountId,
    this.feesAndPrepayment,
  });

  final String loanTypeId;
  final String name;
  final String lender;
  final Paisa principal;
  final Paisa outstanding;
  final double? ratePct;
  final InterestMethod method;
  final Paisa installment;
  final LoanFrequency frequency;
  final IsoDate? startDate;
  final IsoDate? maturityDate;
  final IsoDate? nextDueDate;
  final String? repaymentAccountId;
  final String? feesAndPrepayment;
}

/// Loans and their repayments. A repayment is an ordinary `loan_repayment`
/// transaction written through [TransactionRepository], so the engine moves
/// the balance, the outstanding and the due date together.
class LoanRepository {
  LoanRepository(this._db, this._audit, this._transactions, {required this._clock, required this._newId});

  final AppDatabase _db;
  final AuditLog _audit;
  final TransactionRepository _transactions;
  final Clock _clock;
  final IdGen _newId;

  Future<Loan?> find(String id) async {
    final row = await (_db.select(_db.loans)..where((l) => l.id.equals(id))).getSingleOrNull();
    return row == null ? null : loanFromRow(row);
  }

  Future<Loan> get(String id) async => (await find(id))!;

  /// This loan's repayments (and disbursements), newest first.
  Stream<List<Txn>> watchRepayments(String loanId) => (_db.select(_db.transactions)
        ..where((t) => t.loanId.equals(loanId))
        ..orderBy([(t) => OrderingTerm.desc(t.date), (t) => OrderingTerm.desc(t.time)]))
      .watch()
      .map((rows) => rows.map(txnFromRow).toList());

  Future<(Loan, UndoAction)> add(LoanInput i) async {
    final loan = Loan(
      id: _newId(),
      loanTypeId: i.loanTypeId,
      name: i.name.trim(),
      lender: i.lender.trim(),
      principal: i.principal,
      outstanding: i.outstanding,
      ratePct: i.method == InterestMethod.none ? 0 : i.ratePct,
      method: i.method,
      installment: i.installment,
      frequency: i.frequency,
      startDate: i.startDate,
      maturityDate: i.maturityDate,
      nextDueDate: i.nextDueDate,
      repaymentAccountId: i.repaymentAccountId,
      feesAndPrepayment: (i.feesAndPrepayment?.trim().isEmpty ?? true) ? null : i.feesAndPrepayment!.trim(),
    );
    await _db.transaction(() async {
      final count = (await _db.select(_db.loans).get()).length;
      await _db.into(_db.loans).insert(loanToCompanion(loan, sortOrder: count));
      await _audit.write(
        action: 'loan.add',
        entity: 'loan',
        entityId: loan.id,
        summary: 'Added loan ${loan.name} · ${auditMoney(loan.outstanding)} outstanding',
      );
    });
    final undo = UndoAction(() => _db.transaction(() async {
          final used = await (_db.select(_db.transactions)..where((t) => t.loanId.equals(loan.id))..limit(1)).get();
          if (used.isEmpty) {
            await (_db.delete(_db.loans)..where((l) => l.id.equals(loan.id))).go();
          } else {
            await (_db.update(_db.loans)..where((l) => l.id.equals(loan.id)))
                .write(const LoansCompanion(closed: Value(true)));
          }
          await _audit.write(action: 'loan.undo', entity: 'loan', entityId: loan.id, summary: 'Undid the last change');
        }));
    return (loan, undo);
  }

  /// Saves edited terms. Undo restores the previous terms.
  Future<UndoAction> update(Loan loan) async {
    final before = await get(loan.id);
    await _db.transaction(() async {
      await _replace(loan);
      await _audit.write(action: 'loan.edit', entity: 'loan', entityId: loan.id, summary: 'Edited loan ${loan.name}');
    });
    return UndoAction(() => _db.transaction(() async {
          await _replace(before);
          await _audit.write(action: 'loan.undo', entity: 'loan', entityId: loan.id, summary: 'Undid the last change');
        }));
  }

  Future<void> _replace(Loan l) async {
    final order = (await (_db.select(_db.loans)..where((r) => r.id.equals(l.id))).getSingle()).sortOrder;
    await _db.into(_db.loans).insertOnConflictUpdate(loanToCompanion(l, sortOrder: order));
  }

  /// Records a payment of [amount]: interest first, the rest off the
  /// principal (spec §5.4). Only the interest counts as spending. A payment
  /// above what is owed is refused: the extra would leave the account with
  /// no record of where it went.
  Future<UndoAction> recordRepayment(
    String loanId, {
    required Paisa amount,
    required IsoDate date,
    required String fromAccountId,
  }) async {
    final loan = await get(loanId);
    final max = payoffAmount(loan);
    if (loan.outstanding <= 0 || amount > max) throw RepaymentTooLarge(max);
    final split = splitRepayment(loan, amount);
    return _transactions.add(
      Txn(
        id: _newId(),
        date: date,
        time: _clock.hhmm(),
        title: '${loan.name} installment',
        type: TxType.loanRepayment,
        direction: Direction.debit,
        accountId: fromAccountId,
        loanId: loan.id,
        amount: amount,
        principal: split.principal,
        interest: split.interest,
      ),
      summary: 'Recorded repayment ${loan.name} · ${auditMoney(amount)}',
    );
  }
}
