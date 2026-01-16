import 'dart:math';
import 'package:flutter/material.dart';

import '../../../config/theme.dart';

class RiskGauge extends StatelessWidget {
  final int score;

  const RiskGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 120,
      child: CustomPaint(
        painter: _RiskGaugePainter(score: score),
      ),
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  final int score;

  _RiskGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      backgroundPaint,
    );

    // Gradient arc sections
    _drawGradientArc(canvas, center, radius, 0, 0.4, AppTheme.positiveChange);
    _drawGradientArc(canvas, center, radius, 0.4, 0.7, Colors.amber);
    _drawGradientArc(canvas, center, radius, 0.7, 1.0, AppTheme.negativeChange);

    // Indicator needle
    final needleAngle = pi + (score / 100) * pi;
    final needleLength = radius - 25;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center circle
    final centerPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);
  }

  void _drawGradientArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startPercent,
    double endPercent,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    final startAngle = pi + (startPercent * pi);
    final sweepAngle = (endPercent - startPercent) * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
