import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/money.dart';

void main() {
  group('groupDigits', () {
    test('lakh grouping', () {
      expect(groupDigits(0, Grouping.lakh), '0');
      expect(groupDigits(999, Grouping.lakh), '999');
      expect(groupDigits(1000, Grouping.lakh), '1,000');
      expect(groupDigits(142350, Grouping.lakh), '1,42,350');
      expect(groupDigits(2500000, Grouping.lakh), '25,00,000');
      expect(groupDigits(123456789, Grouping.lakh), '12,34,56,789');
    });
    test('international grouping', () {
      expect(groupDigits(1234567, Grouping.international), '1,234,567');
      expect(groupDigits(142350, Grouping.international), '142,350');
    });
  });

  test('toWholeRupees rounds half away from zero', () {
    expect(toWholeRupees(9278933), 92789);
    expect(toWholeRupees(1379067), 13791);
    expect(toWholeRupees(50), 1);
    expect(toWholeRupees(49), 0);
    expect(toWholeRupees(-150), -2);
  });

  test('fromRupees converts to integer paisa', () {
    expect(fromRupees(142350), 14235000);
    expect(fromRupees(11.25), 1125);
  });

  group('MoneyFormat', () {
    const f = MoneyFormat();
    test('npr uses lakh grouping and a real minus sign', () {
      expect(f.npr(fromRupees(142350)), 'NPR 1,42,350');
      expect(f.npr(fromRupees(-500)), '${kMinus}NPR 500');
      expect(f.npr(40), 'NPR 0');
    });
    test('international grouping', () {
      expect(const MoneyFormat(grouping: Grouping.international).npr(fromRupees(142350)), 'NPR 142,350');
    });
    test('plain omits the currency', () {
      expect(f.plain(fromRupees(92789)), '92,789');
    });
    test('short uses L and K', () {
      expect(f.short(fromRupees(142350)), '1.42L');
      expect(f.short(fromRupees(500000)), '5L');
      expect(f.short(fromRupees(2500000)), '25L');
      expect(f.short(fromRupees(12400)), '12K');
      expect(f.short(fromRupees(999)), '999');
      expect(f.short(fromRupees(-5000)), '${kMinus}5K');
    });
    test('signed is used for list rows', () {
      expect(f.signed(fromRupees(1500), '+'), '+ NPR 1,500');
      expect(f.signed(fromRupees(2450), kMinus), '$kMinus NPR 2,450');
      expect(f.signed(fromRupees(5000), ''), 'NPR 5,000');
    });
    test('masked hides every amount', () {
      const m = MoneyFormat(masked: true);
      expect(m.npr(fromRupees(142350)), 'NPR ••••••');
      expect(m.plain(1), '••••••');
      expect(m.short(1), '••');
      expect(m.signed(fromRupees(1500), '+'), 'NPR ••••••');
    });
  });

  group('parseNpr (Review Focus 1)', () {
    test('accepts grouped, padded, prefixed and decimal input', () {
      expect(parseNpr('1,42,350'), 14235000);
      expect(parseNpr(' 2000 '), 200000);
      expect(parseNpr('1.5'), 150);
      expect(parseNpr('1.05'), 105);
      expect(parseNpr('NPR 500'), 50000);
      expect(parseNpr('Rs. 250.50'), 25050);
    });
    test('rejects anything else with null, never an exception', () {
      for (final bad in ['', 'abc', '-5', '1.505', '1.', '.5', '12345678901234567890']) {
        expect(parseNpr(bad), isNull, reason: bad);
      }
    });
  });
}
