import '../finance/finance.dart';
import 'mask.dart';

/// Everything the rules need to read a bank or wallet SMS (spec §6 step 3–4).
class SmsContext {
  const SmsContext({
    required this.accounts,
    required this.loans,
    required this.categories,
    required this.incomeTypes,
    required this.history,
    required this.trustedSenders,
  });

  final List<Account> accounts;
  final List<Loan> loans;
  final List<ExpenseCategory> categories;
  final List<IncomeType> incomeTypes;

  /// Past transactions; merchants you have categorised before are learned.
  final List<Txn> history;

  /// Approved sender IDs (Settings → Banks & wallets).
  final List<String> trustedSenders;
}

/// What the rules suggest for one message. Only a suggestion: nothing is
/// saved until the user confirms (or the account's auto-update rule does).
class SmsDraft {
  const SmsDraft({
    required this.sender,
    required this.institution,
    required this.accountId,
    required this.direction,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.time,
    required this.type,
    this.categoryId,
    this.incomeTypeId,
    this.counterAccountId,
    this.loanId,
    required this.confidence,
    required this.reason,
    required this.maskedBody,
  });

  final String sender;
  final String institution;
  final String? accountId;
  final Direction direction;
  final Paisa amount;
  final String merchant;
  final IsoDate date;
  final String time;
  final TxType type;
  final String? categoryId;
  final String? incomeTypeId;
  final String? counterAccountId;
  final String? loanId;
  final SmsConfidence confidence;
  final String reason;
  final String maskedBody;
}

String _norm(String s) => s.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// [sender] is [id], or [id] behind a two-letter operator prefix such as
/// "AD-". Anything else (e.g. "FREEESEWA") could be a spoof.
bool senderMatches(String sender, String id) {
  final s = _norm(sender);
  final n = _norm(id);
  if (s.isEmpty || n.isEmpty) return false;
  return s == n || (s.length == n.length + 2 && s.endsWith(n) && RegExp('^[A-Z]{2}').hasMatch(s));
}

/// True when [sender] is an approved sender (case does not matter).
bool isTrustedSender(String sender, SmsContext ctx) => ctx.trustedSenders.any((t) => senderMatches(sender, t));

final _amount = RegExp(r'(?<![A-Za-z])(?:NPR|NRs\.?|Rs\.?|रु\.?)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
final _amountAfter = RegExp(r'(?<![\w.,])(\d[\d,]*(?:\.\d{1,2})?)\s*(?:NPR|NRs)\b', caseSensitive: false);
final _last4 = RegExp(r'##(\d{4})');
final _date = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b');
final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
final _time = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b');

bool _has(String text, String pattern) => RegExp(pattern, caseSensitive: false).hasMatch(text);

Direction? _direction(String b) {
  if (_has(b, r'\bcredited\b|\breceived\b|\bdeposited\b|\brefunded?\b|\breversed\b|\bcashback\b|\bloaded\b|\bcr\b')) {
    // "paid to X … has been reversed to your wallet" is a credit.
    if (_has(b, r'\bdebited\b|\bdr\b') && !_has(b, r'reversed|refund')) return Direction.debit;
    return Direction.credit;
  }
  if (_has(b, r'\bdebited\b|\bpaid\b|\bwithdrawn\b|\bwithdrawal\b|\bspent\b|\bpurchase\b|\bsent\b|\bpayment of\b|\bdr\b|\btransferred\b|\bused\b|transaction of|debit of')) {
    return Direction.debit;
  }
  return null;
}

/// The remark: who or what the money was for.
String _remark(String b) {
  final patterns = [
    r'Rmks?\s*[:\-]\s*([^.]+)',
    r'Remarks?\s*[:\-]\s*([^.]+)',
    r'towards\s+([^.]+)',
    r'paid to\s+(.+?)(?:\s+on\s+\d|\.|$)',
    r'Payment of\s+[^\s]+\s*[\d,.]+\s+to\s+(.+?)(?:\s+on\s+\d|\s+has|\.|$)',
    r'\bfor\s+(.+?)(?:\s+booking|\s+on\s+\d|\(|\.|$)',
    r'\bat\s+(.+?)(?:\.|$)',
    r'\bto\s+(.+?)(?:\s+on\s+\d|\.|$)',
  ];
  for (final p in patterns) {
    final m = RegExp(p, caseSensitive: false).firstMatch(b);
    // Wallet notifications end "… for NEA bill is successful".
    final r = m?[1]?.replaceFirst(RegExp(r'\s+(?:is|was|has been)\s+success\w*.*$', caseSensitive: false), '').trim();
    if (r != null && r.isNotEmpty) return r;
  }
  return '';
}

String _titleCase(String s) => s
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w.split('-').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase()).join('-'))
    .join(' ');

/// "POS BHAT-BHATENI SUPERMARKET" → "Bhat-Bhateni Supermarket".
String _merchantName(String remark) {
  var r = remark
      .replaceAll(RegExp(r'##\d{4}'), '')
      .replaceAll(RegExp(r'^(POS|ECOM|QR|FONEPAY|IPS|PMT|PAYMENT)\s+', caseSensitive: false), '')
      .trim();
  if (r.isEmpty) r = remark.trim();
  return r == r.toUpperCase() ? _titleCase(r) : r;
}

/// Built-in hints for common Nepali merchants (top-level category ids).
const _merchantHints = <String, String>{
  'BHAT-BHATENI': 'groceries', 'BHATBHATENI': 'groceries', 'BIG MART': 'groceries', 'BIGMART': 'groceries',
  'SALESBERRY': 'groceries', 'PATHAO': 'transport', 'INDRIVE': 'transport', 'TOOTLE': 'transport',
  'NOC': 'transport', 'FUEL': 'transport', 'PETROL': 'transport', 'NTC': 'utilities', 'NCELL': 'utilities',
  'WORLDLINK': 'utilities', 'VIANET': 'utilities', 'NEA': 'utilities', 'KUKL': 'utilities', 'QFX': 'fun',
  'FCUBE': 'fun', 'NETFLIX': 'subs', 'SPOTIFY': 'subs', 'YOUTUBE': 'subs', 'PHARMACY': 'health',
  'HOSPITAL': 'health', 'CLINIC': 'health', 'SCHOOL': 'education', 'COLLEGE': 'education',
};

/// The first word of a merchant, for matching against history.
String _key(String text) {
  final words = text.toUpperCase().replaceAll(RegExp(r'^(POS|ECOM|QR)\s+'), '').split(RegExp(r'[\s—–,.]+'));
  return words.firstWhere((w) => w.length >= 3, orElse: () => '');
}

String? _categoryFor(String remark, SmsContext ctx) {
  final top = {for (final c in ctx.categories) c.id: c};
  String? topLevel(String? id) {
    final c = top[id];
    if (c == null) return null;
    return c.parentId ?? c.id;
  }

  final key = _key(remark);
  if (key.isNotEmpty) {
    for (final t in ctx.history) {
      if ((t.type == TxType.expense || t.type == TxType.refund) && t.categoryId != null && _key(t.title) == key) {
        final id = topLevel(t.categoryId);
        if (id != null) return id;
      }
    }
  }
  final upper = remark.toUpperCase();
  for (final e in _merchantHints.entries) {
    if (upper.contains(e.key) && top.containsKey(e.value)) return e.value;
  }
  return null;
}

/// Spec §6 steps 3–4. Returns null for messages that are not money
/// movements (OTPs, offers) or that come from senders you have not approved.
SmsDraft? parseSms({
  required String sender,
  required String body,
  required DateTime receivedAt,
  required SmsContext ctx,
}) {
  if (!isTrustedSender(sender, ctx)) return null;
  final b = maskSms(body);
  if (_has(b, r'\bOTP\b|one[- ]time password|verification code')) return null;
  // Offers, and notices about money that has not moved yet.
  if (_has(b, r'\boffers?\b|\bget\s+(?:up to\s+)?(?:rs|npr|nrs)|T&C|apply now|\beligible\b|\bwin\b|\blucky\b')) return null;
  if (_has(b, r'will be (?:refunded|reversed|credited|debited)')) return null;
  final amountMatch = _amount.firstMatch(b) ?? _amountAfter.firstMatch(b);
  final direction = _direction(b);
  if (amountMatch == null || direction == null) return null;
  final amount = parseNpr(amountMatch[1]!);
  if (amount == null || amount <= 0) return null;

  // Account: sender plus last 4 digits; wallets match by sender alone.
  final bySender = [
    for (final a in ctx.accounts)
      if (!a.archived && a.smsSender != null && senderMatches(sender, a.smsSender!)) a,
  ];
  final digits = [for (final m in _last4.allMatches(b)) m[1]!];
  Account? account;
  for (final d in digits) {
    account = bySender.where((a) => a.maskedNumber == d).firstOrNull;
    if (account != null) break;
  }
  if (account == null && digits.isEmpty && bySender.length == 1) account = bySender.single;
  if (account == null && digits.isEmpty) {
    // One sender for a bank account and its card: without digits, prefer the
    // account money moves through.
    final nonCard = bySender.where((a) => a.group != AccountGroup.liability).toList();
    if (nonCard.length == 1) account = nonCard.single;
  }

  final institution = account?.institution ??
      bySender.map((a) => a.institution).nonNulls.firstOrNull ??
      ctx.trustedSenders.firstWhere((t) => senderMatches(sender, t), orElse: () => sender);
  final remark = _remark(b);
  final merchant = _merchantName(remark.isEmpty ? institution : remark);
  final others = [for (final a in ctx.accounts) if (!a.archived && a.id != account?.id) a];
  Account? ownDestination;
  for (final d in digits) {
    ownDestination = others.where((a) => a.maskedNumber == d).firstOrNull;
    if (ownDestination != null) break;
  }
  // A wallet loaded from, or sending to, one of your banks by name: "loaded
  // to your eSewa wallet from Nabil Bank". Liquid accounts first.
  if (ownDestination == null && account?.kind == AccountKind.wallet) {
    final named = [
      for (final a in others)
        if (a.group != AccountGroup.liability &&
            a.kind != AccountKind.cash &&
            (a.institution ?? '').trim().length > 2 &&
            _has(b, '\\b(?:from|to)\\s+(?:your\\s+)?${RegExp.escape(a.institution!.trim())}'))
          a,
    ]..sort((x, y) => x.group.index.compareTo(y.group.index));
    ownDestination = named.firstOrNull;
  }

  // Date and time from the message, else when it arrived. A date that is
  // not a real calendar date, or far from when the SMS arrived (a Bikram
  // Sambat date, a month/day swap), is not trusted.
  var date = toIsoDate(receivedAt);
  var dateTrusted = true;
  IsoDate? valid(int y, int mo, int d) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final dt = DateTime.utc(y, mo, d);
    if (dt.month != mo) return null;
    final received = DateTime.utc(receivedAt.year, receivedAt.month, receivedAt.day);
    return dt.difference(received).inDays.abs() <= 7 ? toIsoDate(dt) : null;
  }

  final dm = _date.firstMatch(b);
  final im = _isoDate.firstMatch(b);
  if (dm != null) {
    final v = valid(int.parse(dm[3]!), int.parse(dm[2]!), int.parse(dm[1]!));
    if (v != null) {
      date = v;
    } else {
      dateTrusted = false;
    }
  } else if (im != null) {
    final v = valid(int.parse(im[1]!), int.parse(im[2]!), int.parse(im[3]!));
    if (v != null) {
      date = v;
    } else {
      dateTrusted = false;
    }
  }
  final tm = _time.firstMatch(b.replaceAll(_date, ''));
  final time = tm != null
      ? '${tm[1]!.padLeft(2, '0')}:${tm[2]}'
      : '${receivedAt.hour.toString().padLeft(2, '0')}:${receivedAt.minute.toString().padLeft(2, '0')}';

  var type = direction == Direction.credit ? TxType.income : TxType.expense;
  var confidence = SmsConfidence.medium;
  String? categoryId, incomeTypeId, counterAccountId, loanId;
  var reason = '';
  final text = '$remark $b';

  if (account?.kind == AccountKind.creditCard && direction == Direction.credit && _has(text, r'PAYMENT|\bPAID\b')) {
    // Paying the card bill, reported by the card: which account paid is in
    // the bank's own SMS, usually a pair of this one.
    type = TxType.ccPayment;
    counterAccountId = account!.id;
    account = null;
    confidence = SmsConfidence.low;
    reason = 'Card bill payment received. Pick the account you paid from, or ignore this if the bank’s debit SMS is already here.';
  } else if (_has(text, r'REVERS|\bFAILED\b')) {
    type = TxType.reversal;
    confidence = SmsConfidence.high;
    reason = '“Reversed” keyword: the original payment failed, so nothing was spent.';
  } else if (_has(text, r'REFUND')) {
    type = TxType.refund;
    categoryId = _categoryFor(remark, ctx) ?? 'other';
    reason = '“Refunded” keyword; a refund lowers spending and is not income.';
  } else if (direction == Direction.credit && _has(text, r'LOAN\s*DISB|DISBURS')) {
    type = TxType.loanDisbursement;
    final open = [for (final l in ctx.loans) if (!l.closed) l];
    loanId = (open.where((l) => account != null && l.lender == account.institution).firstOrNull ?? open.firstOrNull)?.id;
    reason = '“Loan disbursement” remark — this is borrowed money, not income.';
  } else if (direction == Direction.debit && _has(text, r'\bEMI\b|\bLOAN\b')) {
    type = TxType.loanRepayment;
    final open = [for (final l in ctx.loans) if (!l.closed && l.outstanding > 0) l];
    final byAmount = open.where((l) => l.installment == amount).firstOrNull;
    final byAccount = open.where((l) => account != null && l.repaymentAccountId == account.id).firstOrNull;
    final loan = byAmount ?? byAccount ?? open.firstOrNull;
    loanId = loan?.id;
    confidence = byAmount != null ? SmsConfidence.high : SmsConfidence.medium;
    reason = loan == null
        ? '“EMI” or “loan” remark, but no open loan matches. Pick the loan before confirming.'
        : byAmount != null
            ? 'Loan remark and the amount match your ${loan.name} installment.'
            : 'Loan remark; ${loan.name} is paid from this account.';
  } else if (direction == Direction.debit &&
      account?.kind != AccountKind.creditCard &&
      _has(text, r'CC\s*PAY|CARD\s*PAY|CREDIT\s*CARD\s*(?:BILL|PAY)')) {
    type = TxType.ccPayment;
    final card = ownDestination?.group == AccountGroup.liability
        ? ownDestination
        : ctx.accounts.where((a) => !a.archived && a.kind == AccountKind.creditCard).firstOrNull;
    counterAccountId = card?.id;
    confidence = ownDestination?.group == AccountGroup.liability ? SmsConfidence.high : SmsConfidence.medium;
    reason = card == null ? 'Card payment remark; add your credit card to match it.' : 'Card payment remark matches ${card.shortName}.';
  } else if (direction == Direction.debit && _has(text, r'\bATM\b|CASH\s*WITHDRAW')) {
    type = TxType.cashWithdrawal;
    counterAccountId = ctx.accounts.where((a) => !a.archived && a.kind == AccountKind.cash).firstOrNull?.id;
    confidence = SmsConfidence.high;
    reason = 'ATM withdrawal moves money into Cash in hand.';
  } else if (ownDestination != null && ownDestination.group != AccountGroup.liability) {
    type = TxType.transfer;
    counterAccountId = ownDestination.id;
    reason = 'Destination ##${ownDestination.maskedNumber} matches your own ${ownDestination.shortName} account.';
  } else if (direction == Direction.credit) {
    final salary = ctx.incomeTypes.where((t) => t.id == 'salary').firstOrNull;
    if (_has(text, r'\bSAL\b|SALARY|PAYROLL')) {
      incomeTypeId = salary?.id ?? 'other_inc';
      final matches = salary?.expectedAmount != null && salary!.expectedAmount == amount;
      confidence = matches ? SmsConfidence.high : SmsConfidence.medium;
      reason = matches
          ? 'Credit remark “SAL” and the amount matches your expected take-home salary.'
          : 'Credit remark “SAL” marks this as salary.';
    } else if (_has(text, r'INTEREST|\bINT\b') && ctx.incomeTypes.any((t) => t.id == 'interest')) {
      incomeTypeId = 'interest';
      reason = 'Interest credit from the bank.';
    } else {
      incomeTypeId = ctx.incomeTypes.any((t) => t.id == 'other_inc') ? 'other_inc' : ctx.incomeTypes.firstOrNull?.id;
      confidence = SmsConfidence.low;
      reason = 'Money received, but the message does not say what for. Check the type.';
    }
  } else {
    categoryId = _categoryFor(remark, ctx);
    if (categoryId != null) {
      confidence = SmsConfidence.high;
      final name = ctx.categories.where((c) => c.id == categoryId).firstOrNull?.name ?? categoryId;
      reason = '$merchant is a $name merchant in your history.';
    } else {
      categoryId = ctx.categories.any((c) => c.id == 'other') ? 'other' : null;
      confidence = SmsConfidence.low;
      reason = 'A payment to a merchant Paisa does not know yet. Pick the category.';
    }
  }

  if (account == null && type != TxType.ccPayment) {
    confidence = SmsConfidence.low;
    reason = 'No account of yours matches this message. Pick the account before confirming. $reason';
  }
  if (!dateTrusted && confidence == SmsConfidence.high) {
    confidence = SmsConfidence.medium;
    reason = '$reason The date in the message could not be read, so the day it arrived is used.';
  }

  return SmsDraft(
    sender: sender,
    institution: institution,
    accountId: account?.id,
    direction: direction,
    amount: amount,
    merchant: merchant,
    date: date,
    time: time,
    type: type,
    categoryId: categoryId,
    incomeTypeId: incomeTypeId,
    counterAccountId: counterAccountId,
    loanId: loanId,
    confidence: confidence,
    reason: reason.trim(),
    maskedBody: b,
  );
}
