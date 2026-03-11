import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

class SettingsInquiryStatusBadge extends StatelessWidget {
  const SettingsInquiryStatusBadge({required this.status, super.key});

  final SupportInquiryStatus status;

  @override
  Widget build(BuildContext context) {
    final background = SettingsSeedData.inquiryStatusBackgroundColor(status);
    final foreground = SettingsSeedData.inquiryStatusTextColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SettingsUiTokens.chipRadius),
      ),
      child: Text(
        SettingsSeedData.inquiryStatusLabel(status),
        style: AppTextStyles.captionWithColor(
          foreground,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}
