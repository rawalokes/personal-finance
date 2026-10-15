import 'package:flutter/material.dart';
import 'package:paisa/ui/theme.dart';
import 'package:paisa/ui/tokens.dart';

/// Wraps [child] in a themed app with a stretched column, like a screen body.
Widget wrap(Widget child, {PaisaColors colors = PaisaColors.night}) => MaterialApp(
      theme: paisaTheme(colors),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [child]),
          ),
        ),
      ),
    );
