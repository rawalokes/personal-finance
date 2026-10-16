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

Account _bank(String id, String institution, String mask, String sender) => Account(
      id: id,
      name: '$institution — savings',
      shortName: '$institution ••$mask',
      institution: institution,
      accountTypeId: 'a1',
      group: AccountGroup.liquid,
      kind: AccountKind.bank,
      maskedNumber: mask,
      smsSender: sender,
      openingBalance: 0,
      balance: 0,
      lastReconciled: '2026-10-01',
    );

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

    test('review fixes: more account-number and balance shapes are masked', () {
      for (final (raw, leak) in [
        ('Your A/C No.0123456784821 debited by NPR 500.', '0123456784821'),
        ('AC0123456784821 credited with NPR 500.', '0123456784821'),
        ('NPR 500 debited. Bal Amt: NPR 24,600.00', '24,600'),
        ('Card XXXX5512 used for Rs 900.', 'XXXX5512'),
      ]) {
        final m = maskSms(raw);
        expect(m.contains(leak), isFalse, reason: '"$raw" kept "$leak": $m');
      }
      expect(maskSms('Card XXXX5512 used for Rs 900.'), contains('##5512'));
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

  group('review fixes', () {
    test('a Nepali-calendar date or an impossible date is not trusted: received date, not high confidence', () {
      final bs = parse('NABIL_ALERT', 'Your A/C ##4821 has been debited by NPR 2,450.00 on 2083-06-28. Rmks: POS BHAT-BHATENI.');
      expect(bs.date, '2026-10-14');
      expect(bs.confidence, isNot(SmsConfidence.high));
      final us = parse('NABIL_ALERT', 'Your A/C ##4821 has been debited by NPR 2,450.00 on 10/14/2026. Rmks: POS BHAT-BHATENI.');
      expect(us.date, '2026-10-14');
    });

    test('offers and "will be refunded" notices are not transactions', () {
      final ctx = sampleContext();
      for (final body in [
        'Get Rs 50 cashback on your next eSewa payment!',
        'Dashain offer: Get Rs. 100 cashback on Fonepay QR payments. T&C apply.',
        'Your payment of Rs. 500 to DARAZ has failed. Amount will be refunded within 7 days.',
      ]) {
        expect(parseSms(sender: 'eSewa', body: body, receivedAt: _received, ctx: ctx), isNull, reason: body);
      }
    });

    test('card purchase shapes match the card account', () {
      final d = parse('NABIL_ALERT', 'Card XXXX-XXXX-XXXX-5512 used for Rs. 1,850 at DARAZ on 14/10/2026.');
      expect(d.accountId, 'cc');
      expect(d.direction, Direction.debit);
      expect(d.amount, fromRupees(1850));
      final t = parse('NABIL_ALERT', 'A transaction of NPR 1,140.00 has been made on your Credit Card XXXX5512 at HIMALAYAN JAVA.');
      expect(t.accountId, 'cc');
      expect(t.categoryId, 'fun');
    });

    test('a payment received on the card is a card payment, waiting for the paying account', () {
      final d = parse('NABIL_ALERT', 'Payment of NPR 18,640 received on your Credit Card XXXX5512. Thank you.');
      expect(d.type, TxType.ccPayment);
      expect(d.counterAccountId, 'cc');
      expect(d.accountId, isNull);
      expect(d.confidence, SmsConfidence.low);
    });

    test('more amount shapes: wallet loads, "debit of", amount before currency, numbers before the amount', () {
      expect(parse('eSewa', 'NPR 500.00 has been loaded to your eSewa wallet from Nabil Bank.').direction, Direction.credit);
      expect(parse('NABIL_ALERT', 'Your A/C ##4821 balance is low after debit of NPR 500.00 for POS BIG MART.').amount, fromRupees(500));
      expect(parse('NABIL_ALERT', '450.00 NPR debited from A/C ##4821 on 14/10/2026. Rmks: POS BIG MART.').amount, fromRupees(450));
      expect(parse('NABIL_ALERT', 'For 2 transfers 1 fee applies. A/C ##4821 debited by NPR 500.00. Rmks: POS BIG MART.').amount, fromRupees(500));
    });

    test('only an exact sender, or one with a two-letter operator prefix, is trusted', () {
      final ctx = sampleContext();
      expect(isTrustedSender('FREEESEWA', ctx), isFalse);
      expect(isTrustedSender('LUCKY-KHALTI', ctx), isFalse);
      expect(isTrustedSender('AD-NABIL_ALERT', ctx), isTrue);
      expect(isTrustedSender('NABIL_ALERT', ctx), isTrue);
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

  group('eSewa app notifications and emails', () {
    test('loading the wallet from your own bank is a transfer, not income', () {
      final d = parse('eSewa', 'Load Successful. NPR 1,000.00 has been loaded to your eSewa wallet from Nabil Bank.');
      expect(d.accountId, 'esewa');
      expect(d.direction, Direction.credit);
      expect(d.type, TxType.transfer);
      expect(d.counterAccountId, 'nabil');
    });

    test('a bill payment notification names the biller without "is successful"', () {
      final d = parse(
        'eSewa',
        'Payment Successful. Your payment of NPR 1,200.00 for NEA electricity bill is successful.',
      );
      expect(d.accountId, 'esewa');
      expect(d.type, TxType.expense);
      expect(d.amount, fromRupees(1200));
      expect(d.merchant, 'NEA electricity bill');
      expect(d.categoryId, 'utilities');
    });

    test('money received from a person is income for the wallet', () {
      final d = parse('eSewa', 'Fund Received. You have received NPR 1,500.00 from Ram Bahadur. Remarks: lunch share');
      expect(d.accountId, 'esewa');
      expect(d.direction, Direction.credit);
      expect(d.type, TxType.income);
    });

    test('promotions from the eSewa app are not transactions', () {
      for (final body in [
        'Pay your NEA bill & get Rs 25 cashback this Tihar!',
        'Dashain Dhamaka: up to NPR 500 cashback on recharge. T&C apply.',
      ]) {
        expect(
          parseSms(sender: 'eSewa', body: body, receivedAt: _received, ctx: sampleContext()),
          isNull,
          reason: body,
        );
      }
    });
  });

  group('real Nepali sender IDs (several per bank)', () {
    SmsContext withAccounts(List<Account> accounts, {List<SmsBank> banks = const []}) => SmsContext(
          accounts: accounts,
          loans: const [],
          categories: seedCategories,
          incomeTypes: seedIncomeTypes,
          history: const [],
          trustedSenders: const ['GBIME_ALERT', 'GIBL', 'NIMB', 'NIMB_ALERT', 'eSewa', 'eSewa_Alert'],
          banks: banks,
        );
    final gibl = sampleAccounts.firstWhere((a) => a.id == 'gibl');

    test('splitSenders reads a comma-separated list', () {
      expect(splitSenders(' GBIME_ALERT, GIBL ,,'), ['GBIME_ALERT', 'GIBL']);
    });

    test('an account can list several senders', () {
      final ctx = withAccounts([gibl.copyWith(smsSender: 'GBIME_ALERT, GIBL')]);
      final d = parseSms(sender: 'GBIME_ALERT', body: 'Your A/C ##3307 has been debited by NPR 500.00. Rmks: POS BIG MART.', receivedAt: _received, ctx: ctx)!;
      expect(d.accountId, 'gibl');
    });

    test('an account set up with an old sender ID still matches through its bank', () {
      final ctx = withAccounts([gibl], banks: const [SmsBank('Global IME Bank', ['GBIME_ALERT', 'GIBL'])]);
      final d = parseSms(sender: 'GBIME_ALERT', body: 'Your A/C ##3307 has been debited by NPR 500.00. Rmks: POS BIG MART.', receivedAt: _received, ctx: ctx)!;
      expect(d.accountId, 'gibl');
    });

    test('a bank SMS with no matching account is still read, for review', () {
      final d = parseSms(sender: 'NIMB', body: 'Your A/C ##1234 has been credited by NPR 2,000.00.', receivedAt: _received, ctx: withAccounts(const []));
      expect(d, isNotNull);
      expect(d!.accountId, isNull);
    });
  });

  group('real NIMB and Global IME messages', () {
    final accounts = [
      ...sampleAccounts.where((a) => a.id == 'esewa' || a.id == 'khalti'),
      _bank('nimb', 'Nepal Investment Mega Bank', '0046', 'NIMB'),
      _bank('gibl', 'Global IME Bank', '9168', 'GBIME_ALERT, GIBL'),
    ];
    final ctx = SmsContext(
      accounts: accounts,
      loans: const [],
      categories: seedCategories,
      incomeTypes: seedIncomeTypes,
      history: const [],
      trustedSenders: const ['NIMB', 'GBIME_ALERT', 'GIBL', 'eSewa', 'Khalti'],
    );
    SmsDraft read(String sender, String body, DateTime at) => parseSms(sender: sender, body: body, receivedAt: at, ctx: ctx)!;

    test('NIMB "Dr by NPR … on 12Oct26": a debit from the NIMB account on that day', () {
      final d = read('NIMB', 'AC#017XX0046 Dr by NPR 1440 on 12Oct26 14:52:55 - 136014434,BOALNPKA;0', DateTime(2026, 10, 13, 9));
      expect(d.accountId, 'nimb');
      expect(d.direction, Direction.debit);
      expect(d.amount, fromRupees(1440));
      expect(d.date, '2026-10-12');
      expect(d.time, '14:52');
      expect(d.maskedBody, isNot(contains('017XX0046')));
    });

    test('NIMB debit to ESEWA is a transfer to your eSewa wallet', () {
      final d = read('NIMB', 'AC#017XX0046 Dr by NPR 1300 on 12Oct26 15:01:04 - ESEWA,166708071,9817', DateTime(2026, 10, 12, 15, 2));
      expect(d.type, TxType.transfer);
      expect(d.counterAccountId, 'esewa');
    });

    test('NIMB credit names the sender and keeps the paisa', () {
      final d = read('NIMB', 'AC#017XX0046 Cr by NPR 110216.4 on 15Oct26 17:17:04 - CIPSFIRSTFINTECH COR', DateTime(2026, 10, 15, 17, 18));
      expect(d.direction, Direction.credit);
      expect(d.amount, parseNpr('110216.40'));
      expect(d.date, '2026-10-15');
      expect(d.merchant, 'Cipsfirstfintech Cor');
    });

    test('Global IME credit "by:FonePay:IBFT:…" with an ISO date', () {
      final d = read('GBIME_ALERT', 'Dear user, Your account ##9168 is credited by NPR 50000 on 2026-09-21 11:54:33 by:FonePay:IBFT:1890221321',
          DateTime(2026, 9, 21, 11, 55));
      expect(d.accountId, 'gibl');
      expect(d.direction, Direction.credit);
      expect(d.amount, fromRupees(50000));
      expect(d.date, '2026-09-21');
      expect(d.merchant, 'FonePay IBFT');
    });

    test('Global IME "Payment successful to Khalti with amount …" is a transfer to your Khalti wallet', () {
      final d = read('GBIME_ALERT',
          'Payment successful to Khalti with amount 2,000.00 and remarks MOS/Khalti/9868752880/lks\nFrom a/c : ###9168\nTxn ID : SYAYXMJQTWZ',
          DateTime(2026, 9, 22, 14, 42));
      expect(d.accountId, 'gibl');
      expect(d.direction, Direction.debit);
      expect(d.amount, fromRupees(2000));
      expect(d.type, TxType.transfer);
      expect(d.counterAccountId, 'khalti');
    });

    test('the OTP and "Code successfully validated" messages are not transactions', () {
      for (final (sender, body) in [
        ('GBIME_ALERT', 'Your OTP for GIBL EKYC Request is 648957 and expires in 120 seconds.'),
        ('NIMB', 'Code successfully validated.\nNIMB'),
      ]) {
        expect(parseSms(sender: sender, body: body, receivedAt: DateTime(2026, 10, 15), ctx: ctx), isNull, reason: body);
      }
    });
  });
}
