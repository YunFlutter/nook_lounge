import 'package:flutter/material.dart';

class PassportPalette {
  const PassportPalette._();

  /// 유지보수 포인트:
  /// 이 팔레트는 Figma 노드(682:1391) 기준 "여권 전용" 색상만 모아둔 토큰입니다.
  /// 여권 화면의 색상 변경이 필요하면 아래 상수만 수정하면 됩니다.

  // Base
  static const Color pageBackground = Color(0xFFFBFAF7);

  // Accent
  static const Color titleAccent = Color(0xFF91ACEC);
  static const Color welcomeAccent = Color(0xFFBD85D7);
  static const Color actionGreen = Color(0xFF22CB8C);
  static const Color actionGreenPressed = Color(0xFF1AB97F);

  // Passport Card
  static const Color cardHeaderBackground = Color(0xFFB59E7B);
  static const Color cardDetailBackground = Color(0xFFD8C09A);
  static const Color cardBorder = Color(0xFFEEE0CC);

  // Text
  static const Color textPrimary = Color(0xFF5F4F24);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Photo
  static const Color photoBackground = pageBackground;
  static const Color photoBorder = cardBorder;

  // Shadow
  static const Color shadowSoft = Color(0x145F4F24);
  static const Color shadowMedium = Color(0x245F4F24);
  static const Color shadowStrong = Color(0x265F4F24);

  // Confetti / Burst
  static const Color burstGlow = cardBorder;
  static const Color confettiPurple = welcomeAccent;
  static const Color confettiMint = actionGreen;
  static const Color confettiYellow = cardDetailBackground;
  static const Color confettiBlue = titleAccent;
  static const Color confettiOrange = cardHeaderBackground;
}
