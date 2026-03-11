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
    return Text(
      title,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTextStyles.headingH3.copyWith(
        color: AppColors.textSecondary
      ),
    );
  }
}
