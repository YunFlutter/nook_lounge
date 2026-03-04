import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/app/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const textColor = AppColors.textPrimary;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryDefault,
          brightness: Brightness.light,
        ).copyWith(
          // 유지보수 포인트:
          // Figma 컬러 팔레트 토큰과 Material ColorScheme를 명시적으로 매핑합니다.
          primary: AppColors.primaryDefault,
          onPrimary: AppColors.textInverse,
          primaryContainer: AppColors.primaryHover,
          onPrimaryContainer: AppColors.textInverse,
          secondary: AppColors.accentDeepOrange,
          onSecondary: AppColors.textInverse,
          secondaryContainer: AppColors.accentOrange,
          onSecondaryContainer: AppColors.textPrimary,
          tertiary: AppColors.textAccent,
          onTertiary: AppColors.textInverse,
          surface: AppColors.bgCard,
          onSurface: textColor,
          outline: AppColors.borderDefault,
          outlineVariant: AppColors.navBorder,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      cardColor: AppColors.bgCard,
      dividerColor: AppColors.borderDefault,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.headingH2Secondary,
        toolbarTextStyle: AppTextStyles.bodyPrimaryStrong,
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
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.borderFocus,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppTextStyles.bodyHintStrong,
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
            width: 1.8,
          ),
        ),
        errorStyle: AppTextStyles.captionWithColor(
          AppColors.accentDeepOrange,
          weight: FontWeight.w800,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.accentDeepOrange,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.accentDeepOrange,
            width: 1.8,
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: const WidgetStatePropertyAll(AppColors.white),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStateProperty.resolveWith((states) {
          final isFocused = states.contains(WidgetState.focused);
          return BorderSide(
            color: isFocused ? AppColors.borderFocus : AppColors.borderDefault,
            width: isFocused ? 1.8 : 1,
          );
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        hintStyle: WidgetStatePropertyAll(AppTextStyles.bodyHintStrong),
        textStyle: WidgetStatePropertyAll(AppTextStyles.bodyPrimaryStrong),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyLarge.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: AppTextStyles.dialogTitleCompact,
        contentTextStyle: AppTextStyles.dialogBodyCompact,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.bodyPrimaryStrong,
        subtitleTextStyle: AppTextStyles.captionMuted,
      ),
    );
  }
}
