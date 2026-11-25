import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Global Background with soft light-cyan to sky-blue gradient,
/// translucent hexagonal medical honeycomb mesh, and scattered watermark pill/cross icons.
class MedicalMeshBackground extends StatelessWidget {
  final Widget child;

  const MedicalMeshBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF81D4FA), // Light Sky Blue
            Color(0xFFB3E5FC), // Soft Cyan
            Color(0xFFE1F5FE), // Powder Blue
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Translucent Hexagonal Honeycomb Mesh + Scattered Medical Icons
          CustomPaint(
            painter: _HoneycombMeshPainter(),
          ),

          // 2. Foreground Content
          child,
        ],
      ),
    );
  }
}

class _HoneycombMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final hexPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double radius = 28.0;
    final double width = radius * math.sqrt(3);
    final double height = radius * 2;
    final double rowHeight = height * 0.75;

    int rowIndex = 0;
    for (double y = -radius; y < size.height + radius * 2; y += rowHeight) {
      final double xOffset = (rowIndex % 2 == 1) ? width / 2 : 0;
      for (double x = -width; x < size.width + width * 2; x += width) {
        _drawHexagon(canvas, Offset(x + xOffset, y), radius, hexPaint);
      }
      rowIndex++;
    }

    // Scattered semi-transparent medical crosses and pills
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final crossPositions = [
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.22),
      Offset(size.width * 0.12, size.height * 0.65),
      Offset(size.width * 0.86, size.height * 0.72),
      Offset(size.width * 0.50, size.height * 0.88),
    ];

    for (final pos in crossPositions) {
      _drawMedicalCross(canvas, pos, 14, iconPaint);
    }

    final pillPositions = [
      Offset(size.width * 0.88, size.height * 0.12),
      Offset(size.width * 0.10, size.height * 0.42),
      Offset(size.width * 0.84, size.height * 0.48),
      Offset(size.width * 0.20, size.height * 0.84),
    ];

    for (final pos in pillPositions) {
      _drawPillIcon(canvas, pos, 16, iconPaint);
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMedicalCross(Canvas canvas, Offset center, double size, Paint paint) {
    final arm = size / 3;
    final path = Path()
      ..moveTo(center.dx - arm / 2, center.dy - size / 2)
      ..lineTo(center.dx + arm / 2, center.dy - size / 2)
      ..lineTo(center.dx + arm / 2, center.dy - arm / 2)
      ..lineTo(center.dx + size / 2, center.dy - arm / 2)
      ..lineTo(center.dx + size / 2, center.dy + arm / 2)
      ..lineTo(center.dx + arm / 2, center.dy + arm / 2)
      ..lineTo(center.dx + arm / 2, center.dy + size / 2)
      ..lineTo(center.dx - arm / 2, center.dy + size / 2)
      ..lineTo(center.dx - arm / 2, center.dy + arm / 2)
      ..lineTo(center.dx - size / 2, center.dy + arm / 2)
      ..lineTo(center.dx - size / 2, center.dy - arm / 2)
      ..lineTo(center.dx - arm / 2, center.dy - arm / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPillIcon(Canvas canvas, Offset center, double length, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length * 1.8, height: length * 0.9),
      Radius.circular(length * 0.45),
    );
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

