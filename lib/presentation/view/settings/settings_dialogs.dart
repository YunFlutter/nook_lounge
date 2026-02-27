import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';

class SettingsDialogs {
  const SettingsDialogs._();

  static Future<bool> showWithdrawConfirm(BuildContext context) {
    return _showDecisionDialog(
      context: context,
      title: '정말 탈퇴하시겠습니까?',
      accent: '!',
      primaryLabel: '네. 탈퇴할게요.',
      secondaryLabel: '취소',
    );
  }

  static Future<bool> showIslandDeleteConfirm({
    required BuildContext context,
    required String islandName,
  }) {
    final normalizedName = islandName.trim().isEmpty
        ? '선택한 섬'
        : islandName.trim();
    return _showDecisionDialog(
      context: context,
      title: '$normalizedName을(를) 삭제할까요?',
      accent: '!',
      primaryLabel: '삭제',
      secondaryLabel: '취소',
    );
  }

  static Future<void> showWithdrawalCompleted(BuildContext context) {
    return _showDoneDialog(
      context: context,
      title: '탈퇴처리가 완료되었습니다.',
      subtitle: '다음에 또 만나요!',
      buttonLabel: '확인',
    );
  }

  static Future<void> showInquiryReceived({
    required BuildContext context,
    required String displayName,
  }) {
    final normalizedName = displayName.trim().isEmpty
        ? '고객'
        : displayName.trim();
    return _showDoneDialog(
      context: context,
      title: '$normalizedName님의 문의사항이\n접수되었습니다.',
      subtitle: null,
      buttonLabel: '확인',
    );
  }

  static Future<bool> _showDecisionDialog({
    required BuildContext context,
    required String title,
    required String accent,
    required String primaryLabel,
    required String secondaryLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.settingsOverlay,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 330,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 22),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(
                SettingsUiTokens.dialogRadius,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyWithSize(
                    36,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  accent,
                  style: AppTextStyles.bodyWithSize(
                    50,
                    color: AppColors.settingsWarning,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _dialogOutlineButton(
                        label: secondaryLabel,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _dialogPrimaryButton(
                        label: primaryLabel,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  static Future<void> _showDoneDialog({
    required BuildContext context,
    required String title,
    required String? subtitle,
    required String buttonLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.settingsOverlay,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 330,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 22),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(
                SettingsUiTokens.dialogRadius,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyWithSize(
                    36,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyWithSize(
                      28,
                      color: AppColors.textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.settingsSuccessIcon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _dialogPrimaryButton(
                    label: buttonLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _dialogPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.settingsPrimaryButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SettingsUiTokens.actionButtonRadius,
            ),
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonPrimary),
      ),
    );
  }

  static Widget _dialogOutlineButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderDefault),
          backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              SettingsUiTokens.actionButtonRadius,
            ),
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonSecondary),
      ),
    );
  }
}
