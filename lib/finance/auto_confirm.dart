import 'models.dart';

/// Only these may be saved straight from SMS (spec §6 step 7).
const Set<TxType> kAutoConfirmableTypes = {TxType.expense, TxType.income, TxType.refund, TxType.reversal};

/// The single place that decides whether an SMS skips the Inbox.
/// Everything else waits for the user; AI never approves.
bool shouldAutoConfirm({
  required Account? account,
  required SmsConfidence confidence,
  required bool possibleDuplicate,
  required TxType suggestedType,
}) =>
    account != null &&
    account.autoUpdateFromSms &&
    !account.archived &&
    confidence == SmsConfidence.high &&
    !possibleDuplicate &&
    kAutoConfirmableTypes.contains(suggestedType);
