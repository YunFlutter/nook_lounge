import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';

class SettingsNoticePinnedBadge extends StatelessWidget {
  const SettingsNoticePinnedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      // 유지보수 포인트:
      // ListView 직속 자식에서도 뱃지가 전폭으로 늘어나지 않도록
      // Align으로 느슨한 가로 제약을 다시 부여합니다.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentOrange,
          borderRadius: BorderRadius.circular(SettingsUiTokens.chipRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsUiTokens.noticeBadgeHorizontalPadding,
            vertical: SettingsUiTokens.noticeBadgeVerticalPadding,
          ),
          child: Text(
            '고정',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              AppColors.accentDeepOrange,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
