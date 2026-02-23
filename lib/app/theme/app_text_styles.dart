import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_typography.dart';

class AppTextStyles {
  const AppTextStyles._();

  // Headings
  static final TextStyle headingH1 = AppTypography.headingH1.copyWith(
    color: AppColors.textPrimary,
  );
  static final TextStyle headingH2 = AppTypography.headingH2.copyWith(
    color: AppColors.textPrimary,
  );
  static final TextStyle headingH2Secondary = AppTypography.headingH2.copyWith(
    color: AppColors.textSecondary,
  );
  static final TextStyle headingH3 = AppTypography.headingH3.copyWith(
    color: AppColors.textPrimary,
  );

  // Dialog
  static final TextStyle dialogTitle = AppTypography.headingH1.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle dialogBody = AppTypography.headingH3.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  static final TextStyle dialogTitleCompact = AppTypography.headingH2.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle dialogBodyCompact = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  static final TextStyle dialogButtonPrimary = AppTypography.bodyLarge.copyWith(
    color: AppColors.textInverse,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle dialogButtonOutline = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle dialogDanger = AppTypography.bodyMedium.copyWith(
    color: AppColors.badgeRedText,
    fontWeight: FontWeight.w800,
  );

  // Body
  static final TextStyle bodyPrimary = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
  );
  static final TextStyle bodyPrimaryStrong = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle bodyPrimaryHeavy = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle bodySecondaryStrong = AppTypography.bodyLarge.copyWith(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle bodyMutedStrong = AppTypography.bodyLarge.copyWith(
    color: AppColors.textMuted,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle bodyHintStrong = AppTypography.bodyLarge.copyWith(
    color: AppColors.textHint,
    fontWeight: FontWeight.w700,
  );

  // Caption
  static final TextStyle captionPrimary = AppTypography.caption.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle captionPrimaryHeavy = AppTypography.caption.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle captionSecondary = AppTypography.caption.copyWith(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle captionMuted = AppTypography.caption.copyWith(
    color: AppColors.textMuted,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle captionHint = AppTypography.caption.copyWith(
    color: AppColors.textHint,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle captionInverseHeavy = AppTypography.caption.copyWith(
    color: AppColors.textInverse,
    fontWeight: FontWeight.w800,
  );

  // Buttons
  static final TextStyle buttonPrimary = AppTypography.headingH2.copyWith(
    color: AppColors.textInverse,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle buttonSecondary = AppTypography.headingH2.copyWith(
    color: AppColors.textMuted,
    fontWeight: FontWeight.w800,
  );
  static final TextStyle buttonOutline = AppTypography.headingH2.copyWith(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w800,
  );

  static TextStyle chip(Color color) {
    return AppTypography.caption.copyWith(
      color: color,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle labelWithColor(
    Color color, {
    FontWeight weight = FontWeight.w700,
    double? height,
  }) {
    return AppTypography.bodyLarge.copyWith(
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  static TextStyle captionWithColor(
    Color color, {
    FontWeight weight = FontWeight.w700,
    double? height,
  }) {
    return AppTypography.caption.copyWith(
      color: color,
      fontWeight: weight,
      height: height,
    );
  }

  static TextStyle dialogTitleWithSize(double fontSize) {
    return AppTypography.headingH1.copyWith(
      color: AppColors.textPrimary,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle dialogBodyWithSize(double fontSize, {double height = 1.35}) {
    return AppTypography.bodyLarge.copyWith(
      color: AppColors.textPrimary,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: height,
    );
  }

  static TextStyle bodyWithSize(
    double fontSize, {
    required Color color,
    FontWeight weight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) {
    return AppTypography.bodyLarge.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
