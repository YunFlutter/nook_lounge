import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/animation/app_motion.dart';

class AnimatedFadeSlide extends StatelessWidget {
  const AnimatedFadeSlide({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.screen + delay,
      curve: AppMotion.emphasized,
      builder: (context, value, innerChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - value) * 60,
              offset.dy * (1 - value) * 60,
            ),
            child: innerChild,
          ),
        );
      },
      child: child,
    );
  }
}
