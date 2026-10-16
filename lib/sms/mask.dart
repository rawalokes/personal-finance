import 'dart:convert';

import 'package:crypto/crypto.dart';

const kMaskedBalance = '●●●●●●';

final _balance = RegExp(
  r'((?:Avl\.?|Avail(?:able)?\.?|Total|Current|Curr\.?|Clear(?:ed)?)?\s*Bal\w*\.?(?:\s+(?:Amt|Amount|is|of))?\.?\s*[:\-]?\s*(?:NPR|NRs\.?|Rs\.?)?\s*)\d[\d,]*(?:\.\d+)?',
  caseSensitive: false,
);

/// "A/C No.0123456784821", "AC0123456784821": an account keyword, then the
/// number (masked or not) ending in 4 digits.
final _keyed = RegExp(r'\b(A/?C|Acc(?:ount)?|Card)(\s*(?:No\.?|Number)?\s*[:.#\-]?\s*)[0-9Xx*#\-]{2,}(\d{4})\b', caseSensitive: false);

/// A run of 8+ characters of digits and mask characters that ends in 4
/// digits: an account or card number ("0123456784821", "XXXX-XXXX-5512").
final _number = RegExp(r'(?<![\w.,])(?:##)?[0-9Xx*#][0-9Xx*#\- ]{3,}(\d{4})(?![\w,]|\.\d)');

/// Spec §6 step 2: account numbers keep their last 4 digits ("##4821") and
/// balances become ●●●●●●. Only the masked text is ever stored.
String maskSms(String body) {
  final noBalance = body.replaceAllMapped(_balance, (m) => '${m[1]}$kMaskedBalance');
  final keyed = noBalance.replaceAllMapped(_keyed, (m) {
    final sep = m[2]!.trim().isEmpty ? ' ' : m[2]!.replaceAll(RegExp(r'[#\s]+$'), ' ');
    return '${m[1]}$sep##${m[3]}';
  });
  return keyed.replaceAllMapped(_number, (m) {
    final run = m[0]!;
    final digits = run.replaceAll(RegExp(r'\D'), '');
    // Short runs are references or amounts, not account numbers.
    if (digits.length < 6 && !run.contains(RegExp('[Xx*#]'))) return run;
    return '##${m[1]}';
  });
}

/// Hash of the masked message, for duplicate detection (spec §5.6).
String smsHash(String sender, String body) =>
    sha256.convert(utf8.encode('${sender.trim().toUpperCase()}\n${maskSms(body).trim()}')).toString();
