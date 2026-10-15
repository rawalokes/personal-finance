/// Money helpers. Every amount is an integer number of paisa
/// (1 NPR = 100 paisa) so sums never pick up floating-point error.
typedef Paisa = int;

enum Grouping { lakh, international }

/// U+2212 MINUS SIGN, used instead of '-' in displayed amounts.
const String kMinus = '−';
const String kMaskLong = '••••••';
const String kMaskShort = '••';

Paisa fromRupees(num rupees) => (rupees * 100).round();

/// Whole rupees, rounding half away from zero.
/// Exact rupees for a text field: '228640' or '228640.75' (no grouping).
String plainRupees(Paisa p) {
  final sign = p < 0 ? '-' : '';
  final a = p.abs();
  return a % 100 == 0 ? '$sign${a ~/ 100}' : '$sign${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}';
}

int toWholeRupees(Paisa p) => p >= 0 ? (p + 50) ~/ 100 : -((-p + 50) ~/ 100);

/// Groups the digits of |n|: lakh `12,34,56,789` or international `123,456,789`.
String groupDigits(int n, Grouping grouping) {
  final s = n.abs().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final size = grouping == Grouping.lakh ? 2 : 3;
  final parts = <String>[];
  while (rest.length > size) {
    parts.insert(0, rest.substring(rest.length - size));
    rest = rest.substring(0, rest.length - size);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

final _prefix = RegExp(r'^(NPR|Rs\.?)\s*', caseSensitive: false);
final _separators = RegExp(r'[,\s]');
final _amount = RegExp(r'^(\d{1,13})(?:\.(\d{1,2}))?$');

/// Parses what a person types into an amount field. Returns null for
/// anything that is not a non-negative amount with at most 2 decimals.
Paisa? parseNpr(String input) {
  final s = input.trim().replaceFirst(_prefix, '').replaceAll(_separators, '');
  final m = _amount.firstMatch(s);
  if (m == null) return null;
  final whole = int.parse(m.group(1)!);
  final fraction = (m.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

final _trailingZeros = RegExp(r'\.?0+$');

class MoneyFormat {
  const MoneyFormat({this.grouping = Grouping.lakh, this.masked = false});

  final Grouping grouping;

  /// "Hide balances" is on: every amount is replaced by dots.
  final bool masked;

  /// `NPR 1,42,350`, `−NPR 500`, or `NPR ••••••` when masked.
  String npr(Paisa p) => masked ? 'NPR $kMaskLong' : '${_sign(p)}NPR ${_digits(p)}';

  /// `1,42,350` without the currency.
  String plain(Paisa p) => masked ? kMaskLong : '${_sign(p)}${_digits(p)}';

  /// Compact: `1.42L`, `12K`, `950`.
  String short(Paisa p) {
    if (masked) return kMaskShort;
    final rupees = toWholeRupees(p);
    final a = rupees.abs();
    final String body;
    if (a >= 100000) {
      body = '${(a / 100000).toStringAsFixed(2).replaceFirst(_trailingZeros, '')}L';
    } else if (a >= 1000) {
      body = '${(a / 1000).round()}K';
    } else {
      body = '$a';
    }
    return '${rupees < 0 ? kMinus : ''}$body';
  }

  /// List-row style: `+ NPR 1,500`. [sign] is '+', [kMinus] or ''.
  /// When masked the sign is hidden too.
  String signed(Paisa amount, String sign) =>
      masked || sign.isEmpty ? npr(amount) : '$sign ${npr(amount.abs())}';

  String _sign(Paisa p) => toWholeRupees(p) < 0 ? kMinus : '';
  String _digits(Paisa p) => groupDigits(toWholeRupees(p), grouping);
}
