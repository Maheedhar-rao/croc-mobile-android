import 'dart:math';
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Animated crocodile loading indicator.
/// The croc "swims" side to side with its jaw opening and closing.
class CrocLoader extends StatefulWidget {
  final double size;
  final String? message;

  const CrocLoader({super.key, this.size = 80, this.message});

  @override
  State<CrocLoader> createState() => _CrocLoaderState();
}

class _CrocLoaderState extends State<CrocLoader>
    with TickerProviderStateMixin {
  late final AnimationController _swimCtrl;
  late final AnimationController _jawCtrl;

  @override
  void initState() {
    super.initState();
    _swimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _jawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swimCtrl.dispose();
    _jawCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_swimCtrl, _jawCtrl]),
          builder: (context, _) {
            final swimOffset = sin(_swimCtrl.value * pi * 2) * 12;
            final jawAngle = _jawCtrl.value * 0.3;

            return Transform.translate(
              offset: Offset(swimOffset, 0),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _CrocPainter(jawAngle: jawAngle),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: C.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            backgroundColor: C.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(C.primary),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _CrocPainter extends CustomPainter {
  final double jawAngle;

  _CrocPainter({required this.jawAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final bodyPaint = Paint()..color = C.primary;
    final darkPaint = Paint()..color = C.primaryDark;
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = C.textPrimary;
    final bellyPaint = Paint()..color = C.primaryLight.withValues(alpha: 0.5);

    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.7, height: h * 0.4),
      bodyPaint,
    );

    // Belly stripe
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + h * 0.03), width: w * 0.5, height: h * 0.18),
      bellyPaint,
    );

    // Tail (triangle on left)
    final tailPath = Path()
      ..moveTo(cx - w * 0.3, cy - h * 0.06)
      ..lineTo(cx - w * 0.48, cy - h * 0.15)
      ..lineTo(cx - w * 0.3, cy + h * 0.06)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);

    // Tail spikes
    final spikePaint = Paint()..color = C.primaryDark.withValues(alpha: 0.4);
    for (var i = 0; i < 3; i++) {
      final sx = cx - w * 0.22 - i * w * 0.06;
      final spikeP = Path()
        ..moveTo(sx - w * 0.02, cy - h * 0.12)
        ..lineTo(sx, cy - h * 0.2)
        ..lineTo(sx + w * 0.02, cy - h * 0.12)
        ..close();
      canvas.drawPath(spikeP, spikePaint);
    }

    // Upper jaw (rotates up)
    canvas.save();
    canvas.translate(cx + w * 0.15, cy);
    canvas.rotate(-jawAngle);
    final upperJaw = Path()
      ..moveTo(0, -h * 0.05)
      ..lineTo(w * 0.32, -h * 0.12)
      ..lineTo(w * 0.32, 0)
      ..lineTo(0, h * 0.02)
      ..close();
    canvas.drawPath(upperJaw, darkPaint);

    // Upper teeth
    final toothPaint = Paint()..color = Colors.white;
    for (var i = 0; i < 4; i++) {
      final tx = w * 0.06 + i * w * 0.065;
      final toothPath = Path()
        ..moveTo(tx, 0)
        ..lineTo(tx + w * 0.015, h * 0.045)
        ..lineTo(tx + w * 0.03, 0)
        ..close();
      canvas.drawPath(toothPath, toothPaint);
    }
    canvas.restore();

    // Lower jaw (rotates down)
    canvas.save();
    canvas.translate(cx + w * 0.15, cy);
    canvas.rotate(jawAngle);
    final lowerJaw = Path()
      ..moveTo(0, h * 0.02)
      ..lineTo(w * 0.30, h * 0.10)
      ..lineTo(w * 0.30, 0)
      ..lineTo(0, -h * 0.02)
      ..close();
    canvas.drawPath(lowerJaw, bodyPaint);

    // Lower teeth
    for (var i = 0; i < 3; i++) {
      final tx = w * 0.08 + i * w * 0.065;
      final toothPath = Path()
        ..moveTo(tx, 0)
        ..lineTo(tx + w * 0.015, -h * 0.04)
        ..lineTo(tx + w * 0.03, 0)
        ..close();
      canvas.drawPath(toothPath, toothPaint);
    }
    canvas.restore();

    // Eyes (bumps on top)
    canvas.drawCircle(
        Offset(cx + w * 0.08, cy - h * 0.2), w * 0.08, bodyPaint);
    canvas.drawCircle(
        Offset(cx + w * 0.20, cy - h * 0.2), w * 0.08, bodyPaint);

    // Eyeballs
    canvas.drawCircle(
        Offset(cx + w * 0.08, cy - h * 0.22), w * 0.05, eyePaint);
    canvas.drawCircle(
        Offset(cx + w * 0.20, cy - h * 0.22), w * 0.05, eyePaint);

    // Pupils
    canvas.drawCircle(
        Offset(cx + w * 0.09, cy - h * 0.22), w * 0.025, pupilPaint);
    canvas.drawCircle(
        Offset(cx + w * 0.21, cy - h * 0.22), w * 0.025, pupilPaint);

    // Nostrils
    canvas.drawCircle(
        Offset(cx + w * 0.35, cy - h * 0.08), w * 0.015, darkPaint);
    canvas.drawCircle(
        Offset(cx + w * 0.38, cy - h * 0.08), w * 0.015, darkPaint);

    // Back ridges
    for (var i = 0; i < 4; i++) {
      final rx = cx - w * 0.08 + i * w * 0.07;
      final ridgePath = Path()
        ..moveTo(rx - w * 0.02, cy - h * 0.18)
        ..lineTo(rx, cy - h * 0.28)
        ..lineTo(rx + w * 0.02, cy - h * 0.18)
        ..close();
      canvas.drawPath(ridgePath, darkPaint);
    }

    // Legs (stubby)
    final legRR = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.15, cy + h * 0.15, w * 0.1, h * 0.12),
      const Radius.circular(4),
    );
    canvas.drawRRect(legRR, bodyPaint);
    final legRR2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + w * 0.08, cy + h * 0.15, w * 0.1, h * 0.12),
      const Radius.circular(4),
    );
    canvas.drawRRect(legRR2, bodyPaint);
  }

  @override
  bool shouldRepaint(_CrocPainter oldDelegate) =>
      oldDelegate.jawAngle != jawAngle;
}
