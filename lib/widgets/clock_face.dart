import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ClockFace extends StatelessWidget {
  final DateTime time;
  final double waterProgress; // 0.0 – 1.0

  const ClockFace({
    super.key,
    required this.time,
    required this.waterProgress,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _ClockPainter(time: time, progress: waterProgress),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;
  final double progress;

  _ClockPainter({required this.time, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = min(cx, cy);
    final ringW = outerR * 0.1;
    final faceR = outerR - ringW - 4;

    // --- Outer ring track ---
    final trackPaint = Paint()
      ..color = AppColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, outerR - ringW / 2, trackPaint);

    // --- Progress arc ---
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: outerR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: outerR - ringW / 2);
    canvas.drawArc(
        rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, progressPaint);

    // --- Clock face ---
    final facePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, faceR, facePaint);

    // subtle shadow ring
    final shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, faceR, shadowPaint);

    // --- Hour tick marks ---
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final isQuarter = i % 3 == 0;
      final outer = faceR - 2;
      final inner = faceR - (isQuarter ? faceR * 0.14 : faceR * 0.08);
      final tickPaint = Paint()
        ..color = isQuarter
            ? AppColors.primary.withOpacity(0.5)
            : AppColors.primaryLight
        ..strokeWidth = isQuarter ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx + outer * cos(angle), cy + outer * sin(angle)),
        Offset(cx + inner * cos(angle), cy + inner * sin(angle)),
        tickPaint,
      );
    }

    // --- Minute marks (subtle dots) ---
    for (int i = 0; i < 60; i++) {
      if (i % 5 == 0) continue;
      final angle = (i * 6 - 90) * pi / 180;
      final r = faceR - faceR * 0.05;
      canvas.drawCircle(
        Offset(cx + r * cos(angle), cy + r * sin(angle)),
        1.2,
        Paint()..color = AppColors.ringTrack,
      );
    }

    // --- Hands ---
    final h = time.hour % 12;
    final m = time.minute;
    final s = time.second;

    final hourAngle =
        (h * 30 + m * 0.5 - 90) * pi / 180;
    final minuteAngle =
        (m * 6 + s * 0.1 - 90) * pi / 180;
    final secondAngle = (s * 6 - 90) * pi / 180;

    // Hour hand
    _drawHand(canvas, center, hourAngle, faceR * 0.48, 6, AppColors.textPrimary);
    // Minute hand
    _drawHand(canvas, center, minuteAngle, faceR * 0.65, 4, AppColors.textPrimary);
    // Second hand
    _drawHand(canvas, center, secondAngle, faceR * 0.72, 1.5, AppColors.primary);

    // Center dot
    canvas.drawCircle(center, 7, Paint()..color = AppColors.primary);
    canvas.drawCircle(center, 3.5, Paint()..color = Colors.white);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + length * cos(angle),
        center.dy + length * sin(angle),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.time.second != time.second ||
      old.time.minute != time.minute ||
      old.progress != progress;
}
