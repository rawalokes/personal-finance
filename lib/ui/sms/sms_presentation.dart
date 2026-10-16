import '../../finance/finance.dart';
import '../../sms/sms_models.dart';
import '../components/tone.dart';

String confidenceLabel(SmsConfidence c) => switch (c) {
      SmsConfidence.high => 'High confidence',
      SmsConfidence.medium => 'Medium confidence',
      SmsConfidence.low => 'Low confidence',
    };

Tone confidenceTone(SmsConfidence c) => switch (c) {
      SmsConfidence.high => Tone.positive,
      SmsConfidence.medium => Tone.amber,
      SmsConfidence.low => Tone.red,
    };

bool isPossibleDuplicate(SmsMessage m) => m.duplicateOfId != null && m.pending;

/// The small heading on an inbox card.
(String, Tone) inboxHead(SmsMessage m) => switch (m.status) {
      SmsStatus.approved => (m.autoSaved ? 'Auto-saved from SMS' : 'Approved', Tone.positive),
      SmsStatus.rejected => ('Rejected / ignored', Tone.neutral),
      _ when isPossibleDuplicate(m) => ('Possible duplicate', Tone.amber),
      SmsStatus.later => ('Review later', Tone.neutral),
      SmsStatus.review => ('New transaction detected', Tone.blue),
    };

String statusLong(SmsMessage m) => switch (m.status) {
      SmsStatus.approved => m.autoSaved ? 'Auto-saved by the account’s SMS rule' : 'Approved and saved',
      SmsStatus.rejected => 'Ignored — not counted',
      _ => m.edited ? 'Edited · awaiting your approval' : 'Awaiting your approval',
    };

/// "Nabil Bank · A/C ••4821", or "eSewa wallet".
String smsAccountText(SmsMessage m, Account? a) {
  if (a == null) return '${m.institution} · account not matched';
  if (a.maskedNumber != null) return '${m.institution} · A/C ••${a.maskedNumber}';
  return a.kind == AccountKind.wallet ? '${a.shortName} wallet' : a.shortName;
}

/// Types the user can pick for an SMS (adjustments are for reconciling only).
const kSmsTypes = [
  TxType.expense,
  TxType.income,
  TxType.transfer,
  TxType.loanRepayment,
  TxType.ccPayment,
  TxType.cashWithdrawal,
  TxType.refund,
  TxType.reversal,
  TxType.loanDisbursement,
];

bool hasCategory(TxType t) => t == TxType.expense || t == TxType.refund || t == TxType.income;
