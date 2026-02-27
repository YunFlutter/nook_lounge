import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_faq_item.dart';
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

  static final List<SettingsFaqItem> faqItems = <SettingsFaqItem>[
    const SettingsFaqItem(
      id: 'faq_email_change',
      category: supportCategoryAccount,
      question: '로그인 이메일을 바꿀 수 있나요?',
      answer: '소셜 로그인 계정은 제공사(구글/애플) 설정에서 변경 후 재로그인이 필요합니다.',
    ),
    const SettingsFaqItem(
      id: 'faq_withdraw',
      category: supportCategoryAccount,
      question: '탈퇴는 어떻게 하나요?',
      answer: '설정 > 탈퇴하기에서 진행할 수 있으며, 탈퇴 완료 전 최종 확인이 필요합니다.',
    ),
    const SettingsFaqItem(
      id: 'faq_data_delete',
      category: supportCategorySecurity,
      question: '탈퇴하면 데이터는 모두 삭제되나요?',
      answer: '탈퇴 요청 시 개인정보는 비활성 처리되며, 내부 보관 정책에 따라 순차 삭제됩니다.',
    ),
    const SettingsFaqItem(
      id: 'faq_blocked',
      category: supportCategoryPolicy,
      question: '계정이 정지되었어요. 왜 그런가요?',
      answer: '운영정책 위반이 감지되면 이용 제한이 적용될 수 있으며 고객센터로 문의 가능합니다.',
    ),
    const SettingsFaqItem(
      id: 'faq_multi_account',
      category: supportCategoryAccount,
      question: '여러 개의 계정을 만들 수 있나요?',
      answer: '서비스 악용 방지를 위해 동일 환경의 다중 계정 생성이 제한될 수 있습니다.',
    ),
    const SettingsFaqItem(
      id: 'faq_guest_limit',
      category: supportCategoryAccount,
      question: '비회원으로 이용 가능한 기능은 무엇인가요?',
      answer:
          '비회원은 거래글 목록, 비행장 방문 모집 현황, 무주식 계산기 화면을 확인할 수 있습니다. 단, 거래 제안/방문 신청/거래 일정 및 저장 등은 계정 기반 기능입니다.',
    ),
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
        return AppColors.badgeMintBg;
      case SupportInquiryStatus.processing:
        return AppColors.badgeBlueBg;
      case SupportInquiryStatus.completed:
        return AppColors.bgSecondary;
    }
  }

  static Color inquiryStatusTextColor(SupportInquiryStatus status) {
    switch (status) {
      case SupportInquiryStatus.received:
        return AppColors.badgeMintText;
      case SupportInquiryStatus.processing:
        return AppColors.badgeBlueText;
      case SupportInquiryStatus.completed:
        return AppColors.textSecondary;
    }
  }
}
