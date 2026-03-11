import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/app/theme/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static const WidgetStateProperty<Color?> _transparentInteractiveOverlay =
      WidgetStatePropertyAll<Color?>(AppColors.transparent);

  static ButtonStyle _buttonStyleWithoutBlink([ButtonStyle? baseStyle]) {
    return (baseStyle ?? const ButtonStyle()).copyWith(
      overlayColor: _transparentInteractiveOverlay,
      splashFactory: NoSplash.splashFactory,
    );
  }

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

    final filledButtonStyle = _buttonStyleWithoutBlink(
      FilledButton.styleFrom(
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.primaryDefault,
        foregroundColor: AppColors.textInverse,
        textStyle: AppTypography.headingH2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      cardColor: AppColors.bgCard,
      dividerColor: AppColors.borderDefault,
      splashFactory: NoSplash.splashFactory,
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
      hoverColor: AppColors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        shadowColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.appBarHomeTitle,
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
      // 유지보수 포인트:
      // 앱 전역 터치 피드백은 잉크 번짐 대신 색/레이아웃 변화로 표현합니다.
      // 특정 화면에서 눌림 오버레이가 꼭 필요하면 개별 스타일에서 다시 켜면 됩니다.
      textButtonTheme: TextButtonThemeData(style: _buttonStyleWithoutBlink()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyleWithoutBlink(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyleWithoutBlink(),
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      iconButtonTheme: IconButtonThemeData(style: _buttonStyleWithoutBlink()),
      navigationBarTheme: const NavigationBarThemeData(
        overlayColor: _transparentInteractiveOverlay,
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
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.textInverse,
          fontWeight: FontWeight.w700,
          // 유지보수 포인트:
          // 스낵바 문구는 화면별 DefaultTextStyle 영향을 받지 않도록
          // 장식(밑줄/취소선)을 명시적으로 비활성화합니다.
          decoration: TextDecoration.none,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
