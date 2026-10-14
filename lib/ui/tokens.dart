import 'package:flutter/material.dart';

/// Colour tokens from spec §8, plus the extra roles the mockup uses
/// (pri-d, mint-ink, pos-ink, blu, scrim, net-worth bar shades, hero card).
@immutable
class PaisaColors extends ThemeExtension<PaisaColors> {
  const PaisaColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.attentionBg,
    required this.attentionLine,
    required this.attentionInk,
    required this.positive,
    required this.positiveBg,
    required this.positiveInk,
    required this.red,
    required this.redBg,
    required this.amber,
    required this.amberBg,
    required this.blue,
    required this.blueBg,
    required this.scrim,
    required this.toastAction,
    required this.reservedBar,
    required this.lockedBar,
    required this.heroCardStart,
    required this.heroCardEnd,
    required this.heroCardSub,
  });

  final Brightness brightness;
  final Color bg, surface, surface2, ink, ink2, ink3, line;
  final Color primary, onPrimary, primaryPressed;
  final Color attentionBg, attentionLine, attentionInk;
  final Color positive, positiveBg, positiveInk;
  final Color red, redBg, amber, amberBg, blue, blueBg;
  final Color scrim, toastAction;
  final Color reservedBar, lockedBar;
  final Color heroCardStart, heroCardEnd, heroCardSub;

  static const night = PaisaColors(
    brightness: Brightness.dark,
    bg: Color(0xFF0B0D10),
    surface: Color(0xFF171A1F),
    surface2: Color(0xFF20242A),
    ink: Color(0xFFF4F5F7),
    ink2: Color(0xFFC4C9D0),
    ink3: Color(0xFF9BA1AA),
    line: Color(0xFF262A31),
    primary: Color(0xFF4FE3B0),
    onPrimary: Color(0xFF0B0D10),
    primaryPressed: Color(0xFF3CCB9B),
    attentionBg: Color(0xFF10201A),
    attentionLine: Color(0xFF2A3B33),
    attentionInk: Color(0xFFF4F5F7),
    positive: Color(0xFF4FE3B0),
    positiveBg: Color(0xFF10261E),
    positiveInk: Color(0xFF7FEBC6),
    red: Color(0xFFFF8A80),
    redBg: Color(0xFF2A1616),
    amber: Color(0xFFFFC46B),
    amberBg: Color(0xFF2A2110),
    blue: Color(0xFF8FB4FF),
    blueBg: Color(0xFF152036),
    scrim: Color(0x99000000),
    toastAction: Color(0xFF3CCB9B),
    reservedBar: Color(0xFF2FA57F),
    lockedBar: Color(0xFF1E6B55),
    heroCardStart: Color(0xFF1F3B66),
    heroCardEnd: Color(0xFF12233D),
    heroCardSub: Color(0xFFB8C6DC),
  );

  static const light = PaisaColors(
    brightness: Brightness.light,
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF0F3),
    ink: Color(0xFF0B0D10),
    ink2: Color(0xFF3A3F47),
    ink3: Color(0xFF5F6670),
    line: Color(0xFFE1E4E8),
    primary: Color(0xFF0B7F5B),
    onPrimary: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF086A4C),
    attentionBg: Color(0xFFE3F6EE),
    attentionLine: Color(0xFFBFE9D7),
    attentionInk: Color(0xFF0B0D10),
    positive: Color(0xFF0B7F5B),
    positiveBg: Color(0xFFE3F6EE),
    positiveInk: Color(0xFF075C42),
    red: Color(0xFFC0362C),
    redBg: Color(0xFFFCEAE8),
    amber: Color(0xFF8F5400),
    amberBg: Color(0xFFFCF0DA),
    blue: Color(0xFF1F4FC4),
    blueBg: Color(0xFFE8EEFB),
    scrim: Color(0x66000000),
    toastAction: Color(0xFF7FEBC6),
    reservedBar: Color(0xFF2FA57F),
    lockedBar: Color(0xFF1E6B55),
    heroCardStart: Color(0xFFDDE8F7),
    heroCardEnd: Color(0xFFDDE8F7),
    heroCardSub: Color(0xFF3A4E6B),
  );

  /// Tokens are fixed; switching theme swaps the whole palette.
  @override
  PaisaColors copyWith() => this;

  @override
  PaisaColors lerp(PaisaColors? other, double t) => other == null || t < 0.5 ? this : other;
}

/// Spacing, radii and sizes from spec §8 and the mockup CSS.
abstract final class PaisaSize {
  static const double gutter = 16, screenPad = 20;
  static const double radiusCard = 22, radiusSheet = 28, radiusInput = 16, radiusDialog = 24, radiusToast = 14;
  static const double touchMin = 44, buttonHeight = 50, buttonSmallHeight = 44;
  static const double inputHeight = 50, inputBigHeight = 64, rowMinHeight = 64, topBarHeight = 64;
  static const double navItemMinHeight = 58;
}
