class SettingsUiTokens {
  const SettingsUiTokens._();

  // 유지보수 포인트:
  // 설정 화면 전용 spacing/radius 토큰을 분리해 디자인 변경 시
  // 화면별 숫자 수정이 아닌 이 파일만 수정하도록 고정합니다.
  static const double horizontalPadding = 20;
  static const double verticalGap = 10;
  static const double sectionGap = 18;
  static const double tileRadius = 18;
  static const double cardRadius = 24;
  static const double actionButtonRadius = 28;
  static const double dialogRadius = 30;
  static const double chipRadius = 999;

  static const Duration shortAnimation = Duration(milliseconds: 180);
  static const Duration normalAnimation = Duration(milliseconds: 240);
}
