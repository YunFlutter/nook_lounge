import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const textColor = AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentDeepOrange,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      cardColor: AppColors.bgCard,
      dividerColor: AppColors.borderDefault,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
      ),
      textTheme: TextTheme(
        displaySmall: AppTypography.headingH1.copyWith(color: textColor),
        headlineMedium: AppTypography.headingH2.copyWith(color: textColor),
        headlineSmall: AppTypography.headingH3.copyWith(color: textColor),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: textColor),
        bodySmall: AppTypography.bodySmall.copyWith(color: textColor),
        labelSmall: AppTypography.caption.copyWith(color: textColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primaryDefault,
          foregroundColor: AppColors.textInverse,
          textStyle: AppTypography.headingH2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
