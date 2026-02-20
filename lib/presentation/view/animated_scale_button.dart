import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/animation/app_motion.dart';

class AnimatedScaleButton extends StatefulWidget {
  const AnimatedScaleButton({
    required this.child,
    required this.onTap,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  static const _pressedScale = 0.97;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? _pressedScale : 1,
        duration: AppMotion.press,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
