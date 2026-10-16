import '../finance/finance.dart';

/// Where a detected message is in the Transaction Inbox (spec §4 SmsMessage).
/// `review` and `later` both wait in "Needs review".
enum SmsStatus { review, later, approved, rejected }

enum SmsSuggestedBy { rules, ai }

/// A bank or wallet SMS, stored masked, with the suggested transaction.
class SmsMessage {
  const SmsMessage({
    required this.id,
    required this.sender,
    required this.receivedAt,
    required this.maskedBody,
    required this.bodyHash,
    this.sourceKey,
    required this.institution,
    this.accountId,
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
    this.partyId,
    required this.confidence,
    required this.reason,
    this.suggestedBy = SmsSuggestedBy.rules,
    this.status = SmsStatus.review,
    this.duplicateOfId,
    this.transactionId,
    this.edited = false,
    this.autoSaved = false,
    this.description,
  });

  final String id;
  final String sender;

  /// 'YYYY-MM-DDTHH:mm:ss'
  final String receivedAt;
  final String maskedBody;
  final String bodyHash;

  /// The phone's own id for the message, so a rescan never imports it twice.
  final String? sourceKey;
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

  /// Who paid or was paid (Settings → Parties).
  final String? partyId;
  final SmsConfidence confidence;
  final String reason;
  final SmsSuggestedBy suggestedBy;
  final SmsStatus status;
  final String? duplicateOfId;
  final String? transactionId;
  final bool edited;
  final bool autoSaved;
  final String? description;

  bool get pending => status == SmsStatus.review || status == SmsStatus.later;

  SmsMessage copyWith({
    String? accountId,
    Paisa? amount,
    String? merchant,
    IsoDate? date,
    String? time,
    TxType? type,
    String? categoryId,
    String? incomeTypeId,
    String? counterAccountId,
    String? loanId,
    String? partyId,
    SmsConfidence? confidence,
    String? reason,
    SmsSuggestedBy? suggestedBy,
    SmsStatus? status,
    String? transactionId,
    bool? edited,
    bool? autoSaved,
    String? description,
    bool clearCounter = false,
    bool clearLoan = false,
    bool clearParty = false,
    bool clearTransaction = false,
    bool clearDuplicate = false,
  }) =>
      SmsMessage(
        id: id,
        sender: sender,
        receivedAt: receivedAt,
        maskedBody: maskedBody,
        bodyHash: bodyHash,
        sourceKey: sourceKey,
        institution: institution,
        accountId: accountId ?? this.accountId,
        direction: direction,
        amount: amount ?? this.amount,
        merchant: merchant ?? this.merchant,
        date: date ?? this.date,
        time: time ?? this.time,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        incomeTypeId: incomeTypeId ?? this.incomeTypeId,
        counterAccountId: clearCounter ? null : counterAccountId ?? this.counterAccountId,
        loanId: clearLoan ? null : loanId ?? this.loanId,
        partyId: clearParty ? null : partyId ?? this.partyId,
        confidence: confidence ?? this.confidence,
        reason: reason ?? this.reason,
        suggestedBy: suggestedBy ?? this.suggestedBy,
        status: status ?? this.status,
        duplicateOfId: clearDuplicate ? null : duplicateOfId,
        transactionId: clearTransaction ? null : transactionId ?? this.transactionId,
        edited: edited ?? this.edited,
        autoSaved: autoSaved ?? this.autoSaved,
        description: description ?? this.description,
      );
}
