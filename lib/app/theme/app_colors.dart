import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// 유지보수 포인트:
  /// 아래 값들은 Figma Color 섹션 노드 기준으로 정리했습니다.
  /// BG(682:1469), Text(682:1491), Primary(682:1474),
  /// Accent(682:1478), Border(682:1482), Nav(682:1485)

  // Base
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // BG
  static const Color bgPrimary = Color(0xFFFBFAF7);
  static const Color bgSecondary = Color(0xFFF7F6F2);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgPlane = Color(0xFFEAF1F4);

  // Text
  static const Color textPrimary = Color(0xFF5F4F24);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9AA0A6);
  static const Color textHint = Color(0xFFB7BEC6);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textAccent = Color(0xFF91ACEC);

  // Primary
  static const Color primaryDefault = Color(0xFF1AB97F);
  static const Color primaryHover = Color(0xFF129B76);
  static const Color primaryPressed = Color(0xFF0B7D6A);

  // Accent
  static const Color accentOrange = Color(0xFFFFDD99);
  static const Color accentDeepOrange = Color(0xFFE76F51);

  // Border
  static const Color borderDefault = Color(0xFFDADADA);
  static const Color borderFocus = Color(0xFF129B76);

  // Navigation
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFFF6A15A);
  static const Color navActiveBg = Color(0xFFFFF1E6);
  static const Color navInactive = Color(0xFF9A8F85);
  static const Color navBorder = Color(0xFFEEEAE4);
}
