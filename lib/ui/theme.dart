import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

ThemeData paisaTheme(PaisaColors c) {
  final base = ThemeData(useMaterial3: true, brightness: c.brightness, fontFamily: PaisaText.family);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      error: c.red,
      onError: c.bg,
      surface: c.surface,
      onSurface: c.ink,
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary),
    iconTheme: IconThemeData(color: c.ink, size: 22),
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink, fontFamily: PaisaText.family),
    extensions: [c],
  );
}

extension PaisaThemeX on BuildContext {
  PaisaColors get colors => Theme.of(this).extension<PaisaColors>()!;
}
