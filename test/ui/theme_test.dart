import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:paisa/ui/icons/paisa_icon.dart';
import 'package:paisa/ui/icons/paisa_icons.dart';
import 'package:paisa/ui/theme.dart';
import 'package:paisa/ui/tokens.dart';
import 'package:paisa/ui/typography.dart';

import 'helpers.dart';

void main() {
  test('night tokens match spec §8', () {
    const c = PaisaColors.night;
    expect(c.brightness, Brightness.dark);
    expect(c.bg, const Color(0xFF0B0D10));
    expect(c.surface, const Color(0xFF171A1F));
    expect(c.surface2, const Color(0xFF20242A));
    expect(c.ink, const Color(0xFFF4F5F7));
    expect(c.ink3, const Color(0xFF9BA1AA));
    expect(c.line, const Color(0xFF262A31));
    expect(c.primary, const Color(0xFF4FE3B0));
    expect(c.onPrimary, const Color(0xFF0B0D10));
    expect(c.attentionBg, const Color(0xFF10201A));
    expect(c.red, const Color(0xFFFF8A80));
    expect(c.amber, const Color(0xFFFFC46B));
  });

  test('light tokens match spec §8', () {
    const c = PaisaColors.light;
    expect(c.brightness, Brightness.light);
    expect(c.bg, const Color(0xFFF4F5F7));
    expect(c.surface, const Color(0xFFFFFFFF));
    expect(c.primary, const Color(0xFF0B7F5B));
    expect(c.onPrimary, const Color(0xFFFFFFFF));
    expect(c.red, const Color(0xFFC0362C));
    expect(c.amber, const Color(0xFF8F5400));
  });

  test('typography scale matches spec §8', () {
    expect(PaisaText.balance.fontSize, 50);
    expect(PaisaText.h1.fontSize, 26);
    expect(PaisaText.h2.fontSize, 18);
    expect(PaisaText.h3.fontSize, 15);
    expect(PaisaText.sub.fontSize, 13);
    expect(PaisaText.balance.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(PaisaText.sms.fontFamily, PaisaText.monoFamily);
    expect(PaisaSize.radiusCard, 22);
    expect(PaisaSize.touchMin, 44);
  });

  testWidgets('context.colors reads the active palette', (tester) async {
    PaisaColors? seen;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      seen = context.colors;
      return const SizedBox();
    }), colors: PaisaColors.light));
    expect(seen, same(PaisaColors.light));
  });

  test('every icon path parses to a visible shape', () {
    for (final p in PaisaIcons.all) {
      // Width or height: a row of round-capped dots (`dots`) is flat but visible.
      final b = parseSvgPathData(p).getBounds();
      expect(b.width + b.height, greaterThan(0), reason: p);
    }
  });

  testWidgets('PaisaIcon exposes its label only when given one', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const Row(children: [
      PaisaIcon(PaisaIcons.search, semanticLabel: 'Search transactions'),
      PaisaIcon(PaisaIcons.bell),
    ])));
    expect(find.bySemanticsLabel('Search transactions'), findsOneWidget);
    handle.dispose();
  });
}
