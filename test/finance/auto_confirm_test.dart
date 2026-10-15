import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/auto_confirm.dart';
import 'package:paisa/finance/ledger.dart';
import 'package:paisa/finance/models.dart';
import 'package:paisa/finance/money.dart';

import 'fixtures.dart';

void main() {
  final khalti = acct('khalti', AccountGroup.liquid, 3500, kind: AccountKind.wallet, sender: 'Khalti', auto: true);

  bool decide(Account? a, {SmsConfidence c = SmsConfidence.high, bool dup = false, TxType t = TxType.expense}) =>
      shouldAutoConfirm(account: a, confidence: c, possibleDuplicate: dup, suggestedType: t);

  test('Khalti 3,500 with auto-update: Dr 450 → 3,050, Cr 250 → 3,300 (acceptance 12)', () {
    var s = LedgerState.from([khalti], const []);
    expect(decide(khalti, t: TxType.expense), isTrue);
    s = applyTransaction(s, tx(TxType.expense, 'khalti', 450, dir: Direction.debit, source: TxSource.sms));
    expect(s.balanceOf('khalti'), fromRupees(3050));
    expect(decide(khalti, t: TxType.income), isTrue);
    s = applyTransaction(s, tx(TxType.income, 'khalti', 250, dir: Direction.credit, source: TxSource.sms));
    expect(s.balanceOf('khalti'), fromRupees(3300));
  });

  test('waits for review when auto-update is off, duplicate, or not high confidence (acceptance 13)', () {
    expect(decide(khalti.copyWith(autoUpdateFromSms: false)), isFalse);
    expect(decide(khalti, dup: true), isFalse);
    expect(decide(khalti, c: SmsConfidence.medium), isFalse);
    expect(decide(khalti, c: SmsConfidence.low), isFalse);
  });

  test('refunds and reversals may auto-confirm; other types never do', () {
    expect(decide(khalti, t: TxType.refund), isTrue);
    expect(decide(khalti, t: TxType.reversal), isTrue);
    for (final t in [TxType.transfer, TxType.loanRepayment, TxType.ccPayment, TxType.cashWithdrawal,
        TxType.loanDisbursement, TxType.adjustment]) {
      expect(decide(khalti, t: t), isFalse, reason: t.wire);
    }
  });

  test('archived or unmatched accounts never auto-confirm', () {
    expect(decide(khalti.copyWith(archived: true)), isFalse);
    expect(decide(null), isFalse);
  });
}
