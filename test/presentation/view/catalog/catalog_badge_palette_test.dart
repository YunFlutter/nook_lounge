import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_badge_palette.dart';

void main() {
  group('CatalogBadgePalette.resolveHabitat', () {
    test('물고기 서식처를 요청한 팔레트로 구분한다', () {
      expect(CatalogBadgePalette.resolveHabitat('강'), (
        background: const Color(0xFFDCECF8),
        foreground: const Color(0xFF3F7DBB),
      ));
      expect(CatalogBadgePalette.resolveHabitat('연못'), (
        background: const Color(0xFFE3F3ED),
        foreground: const Color(0xFF4C8F7A),
      ));
      expect(CatalogBadgePalette.resolveHabitat('절벽 위 강'), (
        background: const Color(0xFFCFE2F6),
        foreground: const Color(0xFF3569A8),
      ));
      expect(CatalogBadgePalette.resolveHabitat('강 하구'), (
        background: const Color(0xFFBFD8F3),
        foreground: const Color(0xFF2E66A6),
      ));
      expect(CatalogBadgePalette.resolveHabitat('바다(비 오는 날)'), (
        background: const Color(0xFFAFCBF0),
        foreground: const Color(0xFF1F5FA8),
      ));
      expect(CatalogBadgePalette.resolveHabitat('부둣가'), (
        background: const Color(0xFF9CBDE8),
        foreground: const Color(0xFF1C4F8C),
      ));
    });

    test('곤충 서식처 변형 문자열도 세부 팔레트에 맞춘다', () {
      expect(CatalogBadgePalette.resolveHabitat('파랑/보라/검정 꽃 주변 비행'), (
        background: const Color(0xFFF5E6F1),
        foreground: const Color(0xFFA85C8E),
      ));
      expect(CatalogBadgePalette.resolveHabitat('강/연못 위'), (
        background: const Color(0xFFE3F0FB),
        foreground: const Color(0xFF3C7CB8),
      ));
      expect(CatalogBadgePalette.resolveHabitat('쓰레기/썩은 무 주변 비행'), (
        background: const Color(0xFFE5E7EA),
        foreground: const Color(0xFF5E646B),
      ));
      expect(CatalogBadgePalette.resolveHabitat('해변 바위 위'), (
        background: const Color(0xFFE8F4FF),
        foreground: const Color(0xFF2E6FA3),
      ));
      expect(CatalogBadgePalette.resolveHabitat('흰 꽃 위'), (
        background: AppColors.bgSecondary,
        foreground: AppColors.textPrimary,
      ));
    });
  });

  group('CatalogBadgePalette.resolveArtAuthenticity', () {
    test('미술품 진위 배지 색상을 반환한다', () {
      expect(CatalogBadgePalette.resolveArtAuthenticity(<String>['가품:있음']), (
        label: '가품 있음',
        background: AppColors.accentOrange,
        foreground: AppColors.textPrimary,
      ));
      expect(CatalogBadgePalette.resolveArtAuthenticity(<String>['가품:없음']), (
        label: '가품 없음',
        background: AppColors.textInverse,
        foreground: AppColors.textPrimary,
      ));
    });
  });
}
