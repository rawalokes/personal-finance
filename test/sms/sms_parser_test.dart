import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/seed.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/sms/mask.dart';
import 'package:paisa/sms/parser.dart';

import '../data/sample_data.dart';

final _received = DateTime(2026, 10, 14, 9, 13);

SmsContext sampleContext() => SmsContext(
      accounts: sampleAccounts,
      loans: sampleLoans,
      categories: seedCategories,
      incomeTypes: [
        IncomeType(
          id: 'salary', name: 'Monthly Salary', icon: 'brief', color: 0xFF0B7A53, recurring: true,
          frequency: IncomeFrequency.monthly, expectedAmount: fromRupees(92789), defaultAccountId: 'nabil',
        ),
        ...seedIncomeTypes.skip(1),
      ],
      history: sampleTransactions,
      trustedSenders: const ['NABIL_ALERT', 'NIC_ASIA', 'GIBL', 'SBL_ALERT', 'eSewa', 'Khalti'],
    );

SmsDraft parse(String sender, String body) =>
    parseSms(sender: sender, body: body, receivedAt: _received, ctx: sampleContext())!;

void main() {
  group('masking (spec §6 step 2)', () {
    test('balances become ●●●●●● and account numbers keep only the last 4 digits', () {
      const raw = 'Dear Customer, your A/C 0123456784821 has been debited by NPR 2,450.00 on 14/10/2026 08:41. '
          'Rmks: POS BHAT-BHATENI. Avl Bal NPR 1,42,350.00.';
      final m = maskSms(raw);
      expect(m, contains('A/C ##4821'));
      expect(m, contains('Avl Bal NPR ●●●●●●'));
      expect(m, isNot(contains('0123456784821')));
      expect(m, isNot(contains('1,42,350')));
      expect(m, contains('NPR 2,450.00'), reason: 'the amount itself stays');
      expect(m, contains('14/10/2026 08:41'), reason: 'dates and times stay');
    });

    test('masked card numbers and "Balance:" forms are handled too', () {
      final m = maskSms('Card XXXX-XXXX-XXXX-5512 used for Rs. 1,850 at DARAZ. Balance: Rs 23,410.50');
      expect(m, contains('##5512'));
      expect(m, contains('Balance: Rs ●●●●●●'));
      expect(m, isNot(contains('23,410')));
    });

    test('the hash ignores what masking removes, so repeats match', () {
      expect(smsHash('NABIL_ALERT', 'Bal NPR 1,000.00 x'), smsHash('NABIL_ALERT', 'Bal NPR 2,000.00 x'));
      expect(smsHash('NABIL_ALERT', 'A'), isNot(smsHash('GIBL', 'A')));
    });
  });

  group('parsing the mockup messages', () {
    test('salary credit: income · Monthly Salary, high confidence', () {
      final d = parse('NABIL_ALERT',
          'Dear Customer, your A/C ##4821 has been credited by NPR 92,789.00 on 14/10/2026 09:12. Rmks: SAL ASOJ 2083 HIMAL TECH. Avl Bal NPR ●●●●●●. -Nabil Bank');
      expect(d.accountId, 'nabil');
      expect(d.direction, Direction.credit);
      expect(d.amount, fromRupees(92789));
      expect(d.type, TxType.income);
      expect(d.incomeTypeId, 'salary');
      expect(d.date, '2026-10-14');
      expect(d.time, '09:12');
      expect(d.confidence, SmsConfidence.high);
      expect(d.institution, 'Nabil Bank');
      expect(d.reason, contains('SAL'));
    });

    test('POS purchase at a known merchant: expense · Groceries, high', () {
      final d = parse('NABIL_ALERT',
          'Dear Customer, your A/C ##4821 has been debited by NPR 2,450.00 on 14/10/2026 08:41. Rmks: POS BHAT-BHATENI SUPERMARKET MAHARAJGUNJ. Avl Bal NPR ●●●●●●.');
      expect(d.type, TxType.expense);
      expect(d.categoryId, 'groceries');
      expect(d.merchant, 'Bhat-Bhateni Supermarket Maharajgunj');
      expect(d.amount, fromRupees(2450));
      expect(d.confidence, SmsConfidence.high);
    });

    test('a transfer to another own account (##2290): transfer to NIC Asia, medium', () {
      final d = parse('NABIL_ALERT',
          'A/C ##4821 debited by NPR 15,000.00 on 13/10/2026 19:20. Rmks: FONEPAY TRF TO NIC ASIA ##2290 SELF. Avl Bal NPR ●●●●●●.');
      expect(d.accountId, 'nabil');
      expect(d.type, TxType.transfer);
      expect(d.counterAccountId, 'nic');
      expect(d.confidence, SmsConfidence.medium);
      expect(d.date, '2026-10-13');
    });

    test('loan EMI: loan repayment on the scooter loan (installment matches), high', () {
      final d = parse('GIBL',
          'GIBL: Dear Customer, NPR 11,501.00 debited from A/C ##3307 on 13/10/2026 06:05 towards LOAN EMI RECOVERY LN-0042. Thank you.');
      expect(d.accountId, 'gibl');
      expect(d.type, TxType.loanRepayment);
      expect(d.loanId, 'L1');
      expect(d.confidence, SmsConfidence.high);
    });

    test('wallet refund: refund, category from history (QFX → Entertainment), medium', () {
      final d = parse('eSewa',
          'eSewa: Rs. 1,500.00 refunded to your wallet on 12/10/2026 21:14 for QFX Cinemas booking BK-55821 (cancelled). Ref 8XK2P.');
      expect(d.accountId, 'esewa');
      expect(d.direction, Direction.credit);
      expect(d.type, TxType.refund);
      expect(d.categoryId, 'fun');
      expect(d.confidence, SmsConfidence.medium);
    });

    test('a reversed wallet payment: reversal, credit, high', () {
      final d = parse('Khalti',
          'Khalti: Payment of Rs 640.00 to PATHAO on 11/10/2026 18:32 has been reversed to your wallet. Txn ID KH-91F2.');
      expect(d.accountId, 'khalti');
      expect(d.type, TxType.reversal);
      expect(d.direction, Direction.credit);
      expect(d.confidence, SmsConfidence.high);
    });

    test('wallet payment to a ride app: expense · Transport', () {
      final d = parse('Khalti', 'Khalti: Rs 380.00 paid to PATHAO NEPAL on 14/10/2026. Txn ID KH-A71C.');
      expect(d.type, TxType.expense);
      expect(d.direction, Direction.debit);
      expect(d.categoryId, 'transport');
      expect(d.merchant, 'Pathao Nepal');
    });

    test('card bill: credit card payment to the Nabil Visa (##5512)', () {
      final d = parse('NABIL_ALERT', 'A/C ##4821 debited by NPR 18,640.00 on 14/10/2026. Rmks: CC PAYMENT ##5512. Avl Bal NPR ●●●●●●.');
      expect(d.accountId, 'nabil', reason: 'the paying account, not the card that shares the sender');
      expect(d.type, TxType.ccPayment);
      expect(d.counterAccountId, 'cc');
      expect(d.confidence, SmsConfidence.high);
    });

    test('ATM: cash withdrawal into Cash in hand', () {
      final d = parse('NABIL_ALERT', 'A/C ##4821 debited by NPR 10,000.00 on 14/10/2026 at ATM NEW ROAD KTM. Avl Bal NPR ●●●●●●.');
      expect(d.type, TxType.cashWithdrawal);
      expect(d.counterAccountId, 'cash');
    });

    test('loan disbursement credit is debt, not income', () {
      final d = parse('NIC_ASIA', 'NIC ASIA: NPR 50,000.00 credited to A/C ##2290 on 14/10/2026. Rmks: LOAN DISB LN-7781 TOPUP. Avl Bal NPR ●●●●●●.');
      expect(d.accountId, 'nic');
      expect(d.type, TxType.loanDisbursement);
      expect(d.loanId, 'L2', reason: 'the open loan from the same bank');
      expect(d.confidence, SmsConfidence.medium);
    });
  });

  group('what is not a transaction, or not trusted', () {
    test('OTPs and promotions are ignored', () {
      final ctx = sampleContext();
      expect(parseSms(sender: 'NABIL_ALERT', body: 'Your OTP is 482913. Do not share it.', receivedAt: _received, ctx: ctx), isNull);
      expect(parseSms(sender: 'eSewa', body: 'Get 10% cashback on Dashain shopping!', receivedAt: _received, ctx: ctx), isNull);
    });

    test('messages from senders you have not approved are ignored', () {
      expect(
        parseSms(sender: 'RANDOM', body: 'NPR 5,000.00 credited to your A/C ##4821.', receivedAt: _received, ctx: sampleContext()),
        isNull,
      );
    });

    test('senders match without case and with operator prefixes', () {
      expect(isTrustedSender('AD-NABIL_ALERT', sampleContext()), isTrue);
      expect(isTrustedSender('esewa', sampleContext()), isTrue);
    });

    test('an unknown account number is low confidence and leaves the account empty', () {
      final d = parse('NABIL_ALERT', 'Your A/C ##9999 has been debited by NPR 700.00 on 14/10/2026. Rmks: POS SOMEWHERE.');
      expect(d.accountId, isNull);
      expect(d.confidence, SmsConfidence.low);
    });

    test('an unknown merchant is an expense in Other, low confidence', () {
      final d = parse('NABIL_ALERT', 'Your A/C ##4821 has been debited by NPR 700.00 on 14/10/2026. Rmks: POS KATHMANDU KITCHENWARE.');
      expect(d.type, TxType.expense);
      expect(d.categoryId, 'other');
      expect(d.confidence, SmsConfidence.low);
    });

    test('without a date in the message, the received date and time are used', () {
      final d = parse('Khalti', 'Khalti: Rs 120.00 paid to PATHAO. Txn ID KH-1.');
      expect(d.date, '2026-10-14');
      expect(d.time, '09:13');
    });
  });
}
