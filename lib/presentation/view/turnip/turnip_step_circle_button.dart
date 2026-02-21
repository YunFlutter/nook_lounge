import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/presentation/view/animated_scale_button.dart';

class TurnipStepCircleButton extends StatelessWidget {
  const TurnipStepCircleButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.isAccent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isAccent ? AppColors.badgeMintBg : AppColors.bgCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAccent ? AppColors.primaryDefault : AppColors.textMuted,
        ),
      ),
    );
  }
}
