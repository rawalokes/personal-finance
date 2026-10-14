import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

/// Draws one of [PaisaIcons] as a round-capped stroke, like the mockup's
/// `.i` SVGs. Decorative unless [semanticLabel] is given.
class PaisaIcon extends StatelessWidget {
  const PaisaIcon(this.path, {super.key, this.size = 22, this.color, this.strokeWidth = 1.8, this.semanticLabel});

  final String path;

  /// 22 default, 19 small (`.i.s`), 16 extra-small (`.i.xs`).
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _StrokePainter(path, color ?? IconTheme.of(context).color ?? const Color(0xFFF4F5F7), strokeWidth),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: icon)
        : Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.data, this.color, this.strokeWidth);

  static final _cache = <String, Path>{};
  final String data;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache.putIfAbsent(data, () => parseSvgPathData(data));
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.data != data || old.color != color || old.strokeWidth != strokeWidth;
}
