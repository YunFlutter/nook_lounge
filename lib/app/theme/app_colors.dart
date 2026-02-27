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
  static const Color borderStrong = Color(0xFF9AA0A6);

  // Navigation
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFFF6A15A);
  static const Color navActiveBg = Color(0xFFFFF1E6);
  static const Color navInactive = Color(0xFF9A8F85);
  static const Color navBorder = Color(0xFFEEEAE4);

  // Overlay / Shadow
  static const Color shadowSoft = Color(0x14000000);
  static const Color shadowMedium = Color(0x24000000);
  static const Color shadowStrong = Color(0x26000000);

  // Catalog Surface
  static const Color catalogSegmentBg = Color(0xFFF0EDEA);
  static const Color catalogChipBg = Color(0xFFEFEDE8);
  static const Color catalogChipSelectedBg = Color(0xFFFFE2A6);
  static const Color catalogCardBg = Color(0xFFFFFFFF);
  static const Color catalogProgressTrack = Color(0xFFF3F3F3);
  static const Color catalogProgressAccent = Color(0xFFE76F51);
  static const Color catalogSuccessBg = Color(0xFFD7F3E8);
  static const Color catalogSuccessText = Color(0xFF10956A);

  // Catalog Badge
  static const Color badgeBlueBg = Color(0xFFD8EAFF);
  static const Color badgeBlueText = Color(0xFF4F88D9);
  static const Color badgeMintBg = Color(0xFFD8F3EA);
  static const Color badgeMintText = Color(0xFF169E75);
  static const Color badgeRedBg = Color(0xFFFFD8D9);
  static const Color badgeRedText = Color(0xFFE4585D);
  static const Color badgeBeigeBg = Color(0xFFF0E4D8);
  static const Color badgeBeigeText = Color(0xFF7A684E);
  static const Color badgeYellowBg = Color(0xFFFFF0C8);
  static const Color badgeYellowText = Color(0xFF88733C);
  static const Color badgePurpleBg = Color(0xFFE7DBFF);
  static const Color badgePurpleText = Color(0xFF7B59C9);

  // Passport
  static const Color passportPageBg = Color(0xFFFBFBFA);
  static const Color passportTitleBlue = Color(0xFF5B7DE8);
  static const Color passportWelcomePurple = Color(0xFFA983E9);
  static const Color passportCardBg = Color(0xFFD8C29B);
  static const Color passportCardHeaderBg = Color(0xFFB59E7B);
  static const Color passportCardBorder = Color(0xFFEEE0CC);
  static const Color passportLine = Color(0xFF75613E);
  static const Color passportTextMain = Color(0xFF5D4E35);
  static const Color passportTextSub = Color(0xFF766854);
  static const Color passportTextTitle = Color(0xFF6F5A38);
  static const Color passportPhotoBg = Color(0xFFF5F5F5);
  static const Color passportPhotoBorder = Color(0xFFD0D0D0);
  static const Color passportSpotGlow = Color(0xFFFFF7D7);
  static const Color passportSpotRay = Color(0xFFF7D879);
  static const Color passportBurstGlow = Color(0xFFFFF3C4);
  static const Color confettiPurple = Color(0xFFEFA5FF);
  static const Color confettiMint = Color(0xFF88E2CE);
  static const Color confettiYellow = Color(0xFFFFD95C);
  static const Color confettiBlue = Color(0xFFAED9FF);
  static const Color confettiOrange = Color(0xFFFFB57D);

  // Market
  static const Color marketTouchFurniture = Color(0xFF9A6E42);
  static const Color marketTouchWallpaper = Color(0xFFF0B400);
  static const Color marketTouchFlooring = Color(0xFF3D7BE2);
  static const Color marketTouchMusic = Color(0xFF8F50E2);
  static const Color marketTouchFashion = Color(0xFFF2649A);

  // Settings
  static const Color settingsPrimaryButton = Color(0xFF82CAE6);
  static const Color settingsPrimaryButtonPressed = Color(0xFF68B9D7);
  static const Color settingsOverlay = Color(0x66000000);
  static const Color settingsSuccessIcon = Color(0xFFF2CB7C);
  static const Color settingsWarning = Color(0xFFD66D6D);
}
