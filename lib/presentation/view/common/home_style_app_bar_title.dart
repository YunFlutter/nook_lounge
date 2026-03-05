import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';

class HomeStyleAppBarTitle extends StatelessWidget {
  const HomeStyleAppBarTitle(
    this.title, {
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  final String title;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(
        title,
        maxLines: maxLines,
        overflow: overflow,
        style: AppTextStyles.appBarHomeTitle,
      ),
    );
  }
}
