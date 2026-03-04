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

  // Market Code
  // 유지보수 포인트:
  // 거래 코드 관련 글자 스타일은 화면별 숫자 하드코딩 대신 공통 토큰으로 관리합니다.
  static final TextStyle marketCodeInput = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 6,
  );
  static final TextStyle marketCodeDisplay = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 6,
  );
  static final TextStyle marketCodeEmphasis = AppTypography.bodyLarge.copyWith(
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
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
      letterSpacing: AppTypography.letterSpacingFor(fontSize),
    );
  }

  static TextStyle dialogBodyWithSize(double fontSize, {double height = 1.35}) {
    return AppTypography.bodyLarge.copyWith(
      color: AppColors.textPrimary,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: height,
      letterSpacing: AppTypography.letterSpacingFor(fontSize),
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
      // 유지보수 포인트:
      // 수동 지정이 없으면 Figma 규칙(-5%)에 맞춰 자간을 자동 계산합니다.
      letterSpacing: letterSpacing ?? AppTypography.letterSpacingFor(fontSize),
    );
  }
}
