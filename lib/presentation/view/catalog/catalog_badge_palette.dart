import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';

typedef CatalogBadgeTone = ({Color background, Color foreground});
typedef CatalogLabeledBadgeTone = ({
  String label,
  Color background,
  Color foreground,
});

class CatalogBadgePalette {
  const CatalogBadgePalette._();

  // 유지보수 포인트:
  // 물고기/곤충/미술품 배지 색상은 Figma 문구 기준으로 여기서만 관리합니다.
  // JSON의 실제 location 값 변형(예: '강 하구', '절벽 위 강', '광원 주변 비행')도
  // 함께 흡수하므로, 서식처 문자열이 바뀌면 아래 분기만 확인하면 됩니다.
  static CatalogBadgeTone resolveHabitat(String habitat) {
    final normalized = habitat.trim();
    if (normalized.isEmpty) {
      return _neutralTone;
    }

    if (normalized.contains('흰 꽃')) {
      return _whiteFlowerTone;
    }
    if (normalized.contains('꽃')) {
      return _flowerTone;
    }

    if (normalized.contains('절벽 위')) {
      return _fishCliffTone;
    }
    if (normalized.contains('하구')) {
      return _fishEstuaryTone;
    }
    if (normalized == '강') {
      return _fishRiverTone;
    }
    if (normalized == '연못') {
      return _fishPondTone;
    }
    if (normalized.contains('부둣가')) {
      return _fishPierTone;
    }
    if (normalized.startsWith('바다')) {
      return _fishSeaTone;
    }

    if (_containsAny(normalized, <String>['강/연못 위', '물가', '물 위'])) {
      return _bugWaterTone;
    }
    if (normalized.contains('눈덩이')) {
      return _bugSnowballTone;
    }
    if (_containsAny(normalized, <String>['해변', '해안가'])) {
      return _bugCoastTone;
    }
    if (normalized.contains('바위')) {
      return _bugRockTone;
    }
    if (normalized.contains('쓰레기')) {
      return _bugTrashTone;
    }
    if (_containsAny(normalized, <String>['썩은 무', '사탕', '막대사탕'])) {
      return _bugRottenTone;
    }
    if (normalized.contains('주민')) {
      return _bugVillagerTone;
    }
    if (normalized.contains('야자수')) {
      return _bugPalmTone;
    }
    if (_containsAny(normalized, <String>['그루터기', '묘목', '지면', '언더그라운드'])) {
      return _bugGroundTone;
    }
    if (normalized.contains('나무')) {
      return _bugTreeTone;
    }
    if (_containsAny(normalized, <String>['광원', '비행'])) {
      return _bugAirTone;
    }

    return _neutralTone;
  }

  static CatalogLabeledBadgeTone? resolveArtAuthenticity(List<String> tags) {
    if (tags.any((tag) => tag == '가품:있음')) {
      return (
        label: '가품 있음',
        background: AppColors.accentOrange,
        foreground: AppColors.textPrimary,
      );
    }
    if (tags.any((tag) => tag == '가품:없음')) {
      return (
        label: '가품 없음',
        background: AppColors.textInverse,
        foreground: AppColors.textPrimary,
      );
    }
    return null;
  }

  static CatalogBadgeTone resolveVillagerPersonality(String personality) {
    switch (personality.trim()) {
      case '운동광':
        return (
          background: const Color(0xFFE8F3FF),
          foreground: const Color(0xFF2C6BCF),
        );
      case '단순활발':
        return (
          background: const Color(0xFFFFF6CC),
          foreground: const Color(0xFFC29B1E),
        );
      case '먹보':
        return (
          background: const Color(0xFFFFF4E5),
          foreground: const Color(0xFFC57A1F),
        );
      case '무뚝뚝':
        return (
          background: const Color(0xFFF0F0F0),
          foreground: const Color(0xFF6A6A6A),
        );
      case '보통':
        return (
          background: const Color(0xFFF1E39C),
          foreground: AppColors.textPrimary,
        );
      case '스누티':
        return (
          background: const Color(0xFFF8D7FF),
          foreground: const Color(0xFFC24AE9),
        );
      case '아이돌':
        return (
          background: const Color(0xFFEDE7FF),
          foreground: const Color(0xFF6C63C9),
        );
      case '느끼함':
        return (
          background: AppColors.navActiveBg,
          foreground: AppColors.textSecondary,
        );
      default:
        return (
          background: AppColors.badgeBlueBg,
          foreground: AppColors.badgeBlueText,
        );
    }
  }

  static CatalogBadgeTone get _neutralTone =>
      (background: AppColors.catalogChipBg, foreground: AppColors.textPrimary);

  static CatalogBadgeTone get _fishRiverTone => (
    background: const Color(0xFFDCECF8),
    foreground: const Color(0xFF3F7DBB),
  );

  static CatalogBadgeTone get _fishPondTone => (
    background: const Color(0xFFE3F3ED),
    foreground: const Color(0xFF4C8F7A),
  );

  static CatalogBadgeTone get _fishCliffTone => (
    background: const Color(0xFFCFE2F6),
    foreground: const Color(0xFF3569A8),
  );

  static CatalogBadgeTone get _fishEstuaryTone => (
    background: const Color(0xFFBFD8F3),
    foreground: const Color(0xFF2E66A6),
  );

  static CatalogBadgeTone get _fishSeaTone => (
    background: const Color(0xFFAFCBF0),
    foreground: const Color(0xFF1F5FA8),
  );

  static CatalogBadgeTone get _fishPierTone => (
    background: const Color(0xFF9CBDE8),
    foreground: const Color(0xFF1C4F8C),
  );

  static CatalogBadgeTone get _flowerTone => (
    background: const Color(0xFFF5E6F1),
    foreground: const Color(0xFFA85C8E),
  );

  static CatalogBadgeTone get _whiteFlowerTone =>
      (background: AppColors.bgSecondary, foreground: AppColors.textPrimary);

  static CatalogBadgeTone get _bugWaterTone => (
    background: const Color(0xFFE3F0FB),
    foreground: const Color(0xFF3C7CB8),
  );

  static CatalogBadgeTone get _bugAirTone => (
    background: const Color(0xFFF1F3F6),
    foreground: const Color(0xFF7A828C),
  );

  static CatalogBadgeTone get _bugSnowballTone => (
    background: const Color(0xFFE9EEF3),
    foreground: const Color(0xFF5F6F82),
  );

  static CatalogBadgeTone get _bugPalmTone => (
    background: const Color(0xFFE9F1E6),
    foreground: const Color(0xFF4F7A55),
  );

  static CatalogBadgeTone get _bugTreeTone => (
    background: const Color(0xFFF8EBDA),
    foreground: const Color(0xFF8A684A),
  );

  static CatalogBadgeTone get _bugRockTone => (
    background: const Color(0xFFEFEDE8),
    foreground: const Color(0xFF7A736A),
  );

  static CatalogBadgeTone get _bugGroundTone => (
    background: const Color(0xFFE9D9C4),
    foreground: const Color(0xFF7A5B3F),
  );

  static CatalogBadgeTone get _bugCoastTone => (
    background: const Color(0xFFE8F4FF),
    foreground: const Color(0xFF2E6FA3),
  );

  static CatalogBadgeTone get _bugRottenTone => (
    background: const Color(0xFFF1E8FF),
    foreground: const Color(0xFF8C63C9),
  );

  static CatalogBadgeTone get _bugVillagerTone => (
    background: const Color(0xFFFFE9D8),
    foreground: const Color(0xFFC76A2C),
  );

  static CatalogBadgeTone get _bugTrashTone => (
    background: const Color(0xFFE5E7EA),
    foreground: const Color(0xFF5E646B),
  );

  static bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
