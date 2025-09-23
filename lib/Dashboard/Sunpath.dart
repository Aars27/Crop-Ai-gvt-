// Interactive Sun Path Painter
import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveSunPathPainter extends CustomPainter {
  final double sunPosition;

  InteractiveSunPathPainter({
    required this.sunPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the curve path
    final pathPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height - 10);
    path.quadraticBezierTo(size.width / 2, -10, size.width, size.height - 10);

    canvas.drawPath(path, pathPaint);

    // Calculate sun position on curve
    final sunOffset = _calculateSunPositionOnCurve(sunPosition, size);

    // Draw sun shadow/glow effect
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(sunOffset, 15, glowPaint);

    // Draw the sun
    final sunPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sunOffset, 12, sunPaint);

    // Draw sun rays
    final rayPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final startX = sunOffset.dx + math.cos(angle) * 16;
      final startY = sunOffset.dy + math.sin(angle) * 16;
      final endX = sunOffset.dx + math.cos(angle) * 20;
      final endY = sunOffset.dy + math.sin(angle) * 20;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }

    // Draw sun face
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Eyes
    canvas.drawCircle(
        Offset(sunOffset.dx - 4, sunOffset.dy - 2), 1.5, facePaint);
    canvas.drawCircle(
        Offset(sunOffset.dx + 4, sunOffset.dy - 2), 1.5, facePaint);

    // Smile
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromCenter(
        center: Offset(sunOffset.dx, sunOffset.dy + 2),
        width: 8,
        height: 4,
      ),
      0,
      math.pi,
    );
    canvas.drawPath(
        smilePath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
  }

  Offset _calculateSunPositionOnCurve(double t, Size size) {
    // Quadratic bezier curve calculation
    final p0 = Offset(0, size.height - 10);
    final p1 = Offset(size.width / 2, -10);
    final p2 = Offset(size.width, size.height - 10);

    final x = math.pow(1 - t, 2) * p0.dx +
        2 * (1 - t) * t * p1.dx +
        math.pow(t, 2) * p2.dx;
    final y = math.pow(1 - t, 2) * p0.dy +
        2 * (1 - t) * t * p1.dy +
        math.pow(t, 2) * p2.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
