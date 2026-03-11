import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

void main() {
  group('SettingsSeedData inquiry status palette', () {
    test('문의접수와 처리중 색상이 고객센터 상세 기준을 따른다', () {
      expect(
        SettingsSeedData.inquiryStatusBackgroundColor(
          SupportInquiryStatus.received,
        ),
        AppColors.settingsInquiryReceivedBadgeBg,
      );
      expect(
        SettingsSeedData.inquiryStatusTextColor(SupportInquiryStatus.received),
        AppColors.settingsInquiryReceivedBadgeText,
      );
      expect(
        SettingsSeedData.inquiryStatusBackgroundColor(
          SupportInquiryStatus.processing,
        ),
        AppColors.settingsInquiryProcessingBadgeBg,
      );
      expect(
        SettingsSeedData.inquiryStatusTextColor(
          SupportInquiryStatus.processing,
        ),
        AppColors.settingsInquiryProcessingBadgeText,
      );
    });
  });
}
