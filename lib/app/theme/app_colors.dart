import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  /// 유지보수 포인트:
  /// 아래 값들은 Figma Color 섹션 노드 기준으로 정리했습니다.
  /// BG(682:1469), Text(682:1491), Primary(682:1474),
  /// Accent(682:1478), Border(682:1482), Nav(682:1485)

  // Base
  static const Color black = textPrimary;
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // BG
  static const Color bgPrimary = Color(0xFFFBFAF7);
  static const Color bgSecondary = Color(0xFFF7F6F2);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgPlane = Color(0xFFB5DFF1);

  // Text
  static const Color textPrimary = Color(0xFF5F4F24);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9AA0A6);
  static const Color textHint = textMuted;
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
  // 유지보수 포인트:
  // 그림자/오버레이도 팔레트 톤 일관성을 위해 textPrimary 기반 알파를 사용합니다.
  static const Color shadowSoft = Color(0x145F4F24);
  static const Color shadowMedium = Color(0x245F4F24);
  static const Color shadowStrong = Color(0x265F4F24);

  // Catalog Surface
  static const Color catalogSegmentBg = bgSecondary;
  static const Color catalogChipBg = bgSecondary;
  static const Color catalogChipSelectedBg = navActiveBg;
  static const Color catalogCardBg = bgCard;
  static const Color catalogProgressTrack = navBorder;
  static const Color catalogProgressAccent = accentDeepOrange;
  static const Color catalogSuccessBg = bgPlane;
  static const Color catalogSuccessText = primaryHover;

  // Catalog Badge
  static const Color badgeBlueBg = bgPlane;
  static const Color badgeBlueText = textAccent;
  static const Color badgeMintBg = bgPlane;
  static const Color badgeMintText = primaryDefault;
  static const Color badgeRedBg = navActiveBg;
  static const Color badgeRedText = accentDeepOrange;
  static const Color badgeBeigeBg = bgSecondary;
  static const Color badgeBeigeText = textPrimary;
  static const Color badgeYellowBg = accentOrange;
  static const Color badgeYellowText = textPrimary;
  static const Color badgePurpleBg = navActiveBg;
  static const Color badgePurpleText = textAccent;

  // Passport
  static const Color passportPageBg = bgPrimary;
  static const Color passportTitleBlue = textAccent;
  static const Color passportWelcomePurple = textAccent;
  static const Color passportCardBg = accentOrange;
  static const Color passportCardHeaderBg = navActive;
  static const Color passportCardBorder = navBorder;
  static const Color passportLine = textPrimary;
  static const Color passportTextMain = textPrimary;
  static const Color passportTextSub = textSecondary;
  static const Color passportTextTitle = textPrimary;
  static const Color passportPhotoBg = bgSecondary;
  static const Color passportPhotoBorder = borderDefault;
  static const Color passportSpotGlow = accentOrange;
  static const Color passportSpotRay = navActive;
  static const Color passportBurstGlow = navActiveBg;
  static const Color confettiPurple = textAccent;
  static const Color confettiMint = primaryDefault;
  static const Color confettiYellow = accentOrange;
  static const Color confettiBlue = bgPlane;
  static const Color confettiOrange = navActive;

  // Market
  static const Color marketTouchFurniture = textPrimary;
  static const Color marketTouchWallpaper = accentOrange;
  static const Color marketTouchFlooring = textAccent;
  static const Color marketTouchMusic = navActive;
  static const Color marketTouchFashion = accentDeepOrange;
  static const Color marketBlueBadgeBg = Color(0xFFE8F3FF);
  static const Color marketBlueBadgeText = Color(0xFF2C6BCF);
  static const Color marketProposalBadgeBg = Color(0xFFFEDED6);
  static const Color marketProposalBadgeText = accentDeepOrange;

  // Settings
  // 유지보수 포인트:
  // 설정 화면 CTA도 공통 브랜드 Primary 토큰을 재사용합니다.
  static const Color settingsPrimaryButton = primaryDefault;
  static const Color settingsPrimaryButtonPressed = primaryHover;
  static const Color settingsOverlay = Color(0x665F4F24);
  static const Color settingsSuccessIcon = accentOrange;
  static const Color settingsWarning = accentDeepOrange;
}
