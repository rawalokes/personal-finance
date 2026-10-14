import 'package:flutter/material.dart';

/// Space Grotesk scale from spec §8 / mockup CSS. Weights such as 650 are set
/// exactly through the variable font's 'wght' axis.
abstract final class PaisaText {
  static const family = 'SpaceGrotesk';
  static const monoFamily = 'JetBrainsMono';
  static const _tabular = [FontFeature.tabularFigures()];

  static FontWeight _weight(int w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8).toInt()];

  static TextStyle _style(double size, int weight, {double tracking = -0.005, double height = 1.4}) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: _weight(weight),
        fontVariations: [FontVariation('wght', weight.toDouble())],
        letterSpacing: size * tracking,
        height: height,
      );

  static final balance = _style(50, 600, tracking: -0.04, height: 1.1).copyWith(fontFeatures: _tabular);
  static final h1 = _style(26, 600, tracking: -0.03, height: 1.2);
  static final h2 = _style(18, 600, tracking: -0.02);
  static final h3 = _style(15, 500);
  static final body = _style(15, 400);
  static final sub = _style(13, 400);
  static final hint = _style(12.5, 400);

  /// Uppercase section caps; apply `.toUpperCase()` to the text.
  static final cap = _style(12, 700, tracking: 0.06);

  /// Form field labels.
  static final label = _style(13, 650);
  static final button = _style(15, 600);
  static final buttonSmall = _style(14, 600);
  static final chip = _style(14, 600);
  static final segment = _style(14, 650);
  static final tag = _style(12, 650);
  static final navLabel = _style(11.5, 650);
  static final sms = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12.5,
    height: 1.55,
    fontVariations: [FontVariation('wght', 400)],
  );

  /// Tabular figures and tighter tracking for any amount.
  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: _tabular, letterSpacing: (base.fontSize ?? 15) * -0.02);
}
