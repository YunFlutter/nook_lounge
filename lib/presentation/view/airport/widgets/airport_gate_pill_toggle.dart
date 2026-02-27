import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';

class AirportGatePillToggle extends StatelessWidget {
  const AirportGatePillToggle({
    required this.gateOpen,
    required this.onTap,
    this.semanticLabel = '비행장 방문 개방 토글',
    super.key,
  });

  final bool gateOpen;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: gateOpen,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 112,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: gateOpen ? AppColors.badgeBlueBg : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _AirportToggleTrackPainter(gateOpen: gateOpen),
                  ),
                ),
              ),
              if (gateOpen)
                const Positioned(
                  left: 12,
                  top: 11,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 14,
                    color: AppColors.bgCard,
                  ),
                ),
              if (gateOpen)
                const Positioned(
                  left: 28,
                  top: 7,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 16,
                    color: AppColors.bgCard,
                  ),
                ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: gateOpen
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flight_rounded,
                    size: 20,
                    color: AppColors.borderStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirportToggleTrackPainter extends CustomPainter {
  const _AirportToggleTrackPainter({required this.gateOpen});

  final bool gateOpen;

  @override
  void paint(Canvas canvas, Size size) {
    if (gateOpen) {
      return;
    }

    final paint = Paint()
      ..color = AppColors.bgCard.withValues(alpha: 0.35)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // 유지보수 포인트:
    // OFF 상태 패턴은 홈/비행장 탭에서 동일하게 유지합니다.
    const gap = 5.0;
    const lineLength = 17.0;
    var y = size.height * 0.25;
    while (y < size.height * 0.75) {
      var x = 8.0;
      while (x < size.width - 8) {
        final end = math.min(x + lineLength, size.width - 8);
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x += lineLength + gap;
      }
      y += 6.0;
    }
  }

  @override
  bool shouldRepaint(covariant _AirportToggleTrackPainter oldDelegate) {
    return oldDelegate.gateOpen != gateOpen;
  }
}
