import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';

class TurnipLoadingDonut extends StatefulWidget {
  const TurnipLoadingDonut({super.key});

  @override
  State<TurnipLoadingDonut> createState() => _TurnipLoadingDonutState();
}

class _TurnipLoadingDonutState extends State<TurnipLoadingDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: 96,
        height: 96,
        child: CustomPaint(painter: _TurnipLoadingDonutPainter()),
      ),
    );
  }
}

class _TurnipLoadingDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..color = AppColors.catalogChipBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.primaryDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.35,
      math.pi * 1.4,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TurnipLoadingDonutPainter oldDelegate) {
    return false;
  }
}
