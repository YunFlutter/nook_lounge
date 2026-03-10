import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

class SettingsSeedData {
  const SettingsSeedData._();

  static const String supportCategoryAccount = '계정/로그인';
  static const String supportCategoryIsland = '섬 관리/대시보드';
  static const String supportCategoryTurnip = '무주식 계산기';
  static const String supportCategoryAirport = '비행장/섬 방문';
  static const String supportCategoryMarket = '너굴마켓';
  static const String supportCategoryReport = '신고/제재';
  static const String supportCategorySecurity = '데이터 / 보안';
  static const String supportCategoryTech = '기술 문제 / 오류';
  static const String supportCategoryPolicy = '정책 관련';

  static const List<String> supportCategories = <String>[
    supportCategoryAccount,
    supportCategoryIsland,
    supportCategoryTurnip,
    supportCategoryAirport,
    supportCategoryMarket,
    supportCategoryReport,
    supportCategorySecurity,
    supportCategoryTech,
    supportCategoryPolicy,
  ];

  static final List<SettingsNotice> defaultNotices = <SettingsNotice>[
    SettingsNotice(
      id: 'notice_20260216_1',
      title: '[공지] 앱 업데이트 사항 안내',
      body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
      publishedAt: DateTime(2026, 2, 16),
    ),
    SettingsNotice(
      id: 'notice_20260216_2',
      title: '[공지] 앱 업데이트 사항 안내',
      body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
      publishedAt: DateTime(2026, 2, 16),
    ),
    SettingsNotice(
      id: 'notice_20260216_3',
      title: '[공지] 앱 업데이트 사항 안내',
      body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
      publishedAt: DateTime(2026, 2, 16),
    ),
  ];

  static final Map<SettingsDocumentType, SettingsDocument> defaultDocuments =
      <SettingsDocumentType, SettingsDocument>{
        SettingsDocumentType.operationPolicy: SettingsDocument(
          type: SettingsDocumentType.operationPolicy,
          title: '운영정책',
          body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
          updatedAt: DateTime(2026, 2, 16),
        ),
        SettingsDocumentType.termsOfService: SettingsDocument(
          type: SettingsDocumentType.termsOfService,
          title: '이용약관',
          body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
          updatedAt: DateTime(2026, 2, 16),
        ),
        SettingsDocumentType.privacyPolicy: SettingsDocument(
          type: SettingsDocumentType.privacyPolicy,
          title: '개인정보처리방침',
          body: '안녕하세요. 누크라운지입니다.\n다음과 같은 업데이트 내역을 안내드립니다.\n\n......\n\n감사합니다.',
          updatedAt: DateTime(2026, 2, 16),
        ),
      };

  static String inquiryStatusLabel(SupportInquiryStatus status) {
    switch (status) {
      case SupportInquiryStatus.received:
        return '문의접수';
      case SupportInquiryStatus.processing:
        return '처리중';
      case SupportInquiryStatus.completed:
        return '처리완료';
    }
  }

  static Color inquiryStatusBackgroundColor(SupportInquiryStatus status) {
    switch (status) {
      case SupportInquiryStatus.received:
        return AppColors.badgeRedBg;
      case SupportInquiryStatus.processing:
        return AppColors.badgeBlueBg;
      case SupportInquiryStatus.completed:
        return AppColors.bgSecondary;
    }
  }

  static Color inquiryStatusTextColor(SupportInquiryStatus status) {
    switch (status) {
      case SupportInquiryStatus.received:
        return AppColors.badgeRedText;
      case SupportInquiryStatus.processing:
        return AppColors.badgeBlueText;
      case SupportInquiryStatus.completed:
        return AppColors.textSecondary;
    }
  }
}
