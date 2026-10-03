import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders the puck bitmaps handed to the native Mapbox location component.
class LocationPuckImages {
  /// Bitmap pixels per logical pixel; tune if the puck looks too big/small.
  static const double scale = 3;
  static const double _dotRadius = 7;
  static const double _border = 3;

  static Future<Uint8List> dot(Color color) => _render((canvas, c) {
    _shadow(canvas, c.translate(0, 1), _dotRadius + _border);
    canvas.drawCircle(c, _dotRadius + _border, Paint()..color = Colors.white);
    canvas.drawCircle(c, _dotRadius, Paint()..color = color);
  });

  /// Arrow pointing up; the native component rotates it with the bearing.
  static Future<Uint8List> arrow(Color color) => _render((canvas, c) {
    final path = Path()
      ..moveTo(c.dx, c.dy - 14)
      ..lineTo(c.dx + 10, c.dy + 10)
      ..lineTo(c.dx, c.dy + 5)
      ..lineTo(c.dx - 10, c.dy + 10)
      ..close();
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = color);
  });

  static void _shadow(Canvas canvas, Offset c, double r) => canvas.drawCircle(
    c,
    r,
    Paint()
      ..color = Colors.black.withValues(alpha: .25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );

  static Future<Uint8List> _render(
    void Function(Canvas canvas, Offset center) draw,
  ) async {
    const logical = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    draw(canvas, const Offset(logical / 2, logical / 2));
    final px = (logical * scale).round();
    final image = await recorder.endRecording().toImage(px, px);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
