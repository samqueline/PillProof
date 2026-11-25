import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders the exact PillProof logo from the uploaded image asset (assets/images/logo.png),
/// with a graceful fallback to vector canvas drawing if the asset is not found.
class PillProofLogoWidget extends StatelessWidget {
  final double size;

  const PillProofLogoWidget({
    super.key,
    this.size = 230,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size * 1.2,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildVectorFallback();
      },
    );
  }

  Widget _buildVectorFallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 0.85,
          child: CustomPaint(
            painter: _PillProofLogoPainter(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pill Proof',
          style: TextStyle(
            fontSize: size * 0.155,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontFamily: 'serif',
            color: const Color(0xFF01579B),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'FAKE OR SAFE?',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00B0FF),
              ),
            ),
            SizedBox(width: 4),
            Text(
              '✓',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00796B),
              ),
            ),
            SizedBox(width: 4),
            Text(
              'KNOW BEFORE YOU TAKE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF01579B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillProofLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);

    final shieldPaint = Paint()
      ..color = const Color(0xFF29B6F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8;

    final shieldFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final shieldPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.04)
      ..cubicTo(size.width * 0.88, size.height * 0.04, size.width * 0.94, size.height * 0.38, size.width * 0.88, size.height * 0.68)
      ..cubicTo(size.width * 0.78, size.height * 0.90, size.width * 0.5, size.height * 1.00, size.width * 0.5, size.height * 1.00)
      ..cubicTo(size.width * 0.5, size.height * 1.00, size.width * 0.22, size.height * 0.90, size.width * 0.12, size.height * 0.68)
      ..cubicTo(size.width * 0.06, size.height * 0.38, size.width * 0.12, size.height * 0.04, size.width * 0.5, size.height * 0.04);

    canvas.drawPath(shieldPath, shieldFill);
    canvas.drawPath(shieldPath, shieldPaint);

    final radarPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(center, size.width * 0.30, radarPaint);
    canvas.drawCircle(center, size.width * 0.20, radarPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFF0288D1).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(Offset(center.dx - size.width * 0.33, center.dy), Offset(center.dx + size.width * 0.33, center.dy), dashPaint);
    canvas.drawLine(Offset(center.dx, center.dy - size.height * 0.38), Offset(center.dx, center.dy + size.height * 0.38), dashPaint);

    // Large Diagonal Blue & White Capsule Pill in Center
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);

    final pillWidth = size.width * 0.52;
    final pillHeight = size.height * 0.24;

    final whiteHalf = Paint()..color = Colors.white;
    final pillStroke = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: pillWidth, height: pillHeight),
      Radius.circular(pillHeight / 2),
    );
    canvas.drawRRect(pillRRect, whiteHalf);

    final blueHalf = Paint()..color = const Color(0xFF0288D1);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -pillHeight / 2, pillWidth / 2, pillHeight));
    canvas.drawRRect(pillRRect, blueHalf);
    canvas.restore();

    canvas.drawRRect(pillRRect, pillStroke);
    canvas.restore();

    // Checkmark
    final checkPaint = Paint()
      ..color = const Color(0xFF00897B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.56)
      ..lineTo(size.width * 0.46, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.28);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
