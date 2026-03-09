import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/domain/model/user_service_block.dart';

class SessionAccessBlockedDialog {
  const SessionAccessBlockedDialog._();

  static final DateFormat _blockedUntilFormat = DateFormat('yyyy.MM.dd HH:mm');

  static Future<void> show({
    required BuildContext context,
    required UserServiceBlock block,
  }) {
    final blockedUntilText = _blockedUntilFormat.format(
      block.blockedUntilDateTime.toLocal(),
    );
    final blockedReason =
        block.normalizedReason ?? AppStrings.serviceBlockedDefaultReason;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.settingsOverlay,
      builder: (dialogContext) {
        return Semantics(
          namesRoute: true,
          label: AppStrings.serviceBlockedTitle,
          child: Dialog(
            elevation: 0,
            backgroundColor: AppColors.transparent,
            child: Container(
              width: 330,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(
                  SettingsUiTokens.dialogRadius,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.badgeRedBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: AppColors.badgeRedText,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.serviceBlockedTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dialogTitleCompact,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.serviceBlockedDescription,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dialogBodyCompact.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InfoCard(
                    label: AppStrings.serviceBlockedUntilLabel,
                    value: blockedUntilText,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    label: AppStrings.serviceBlockedReasonLabel,
                    value: blockedReason,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.settingsPrimaryButton,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SettingsUiTokens.actionButtonRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        AppStrings.confirm,
                        style: AppTextStyles.buttonPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.captionSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyPrimaryStrong.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}
