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

  static Future<bool> showInquiryDeleteConfirm({
    required BuildContext context,
    required bool isAppeal,
  }) {
    return _showDangerDecisionDialog(
      context: context,
      title: isAppeal ? '이의 신청을 삭제할까요?' : '문의를 삭제할까요?',
      subtitle: isAppeal ? '삭제된 이의 신청은 복구할 수 없어요.' : '삭제된 문의는 복구할 수 없어요.',
      primaryLabel: '삭제',
      secondaryLabel: '취소',
    );
  }

  static Future<bool> showUserUnblockConfirm({
    required BuildContext context,
    required String displayName,
  }) {
    final normalizedName = displayName.trim().isEmpty
        ? '해당 유저'
        : displayName.trim();
    return _showDangerDecisionDialog(
      context: context,
      title: '$normalizedName 차단을 해제할까요?',
      subtitle: '해제 후에는 서로의 게시물과 방문 요청이 다시 보일 수 있어요.',
      primaryLabel: '해제',
      secondaryLabel: '취소',
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
          backgroundColor: AppColors.transparent,
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
                  style: AppTextStyles.dialogTitle,
                ),
                const SizedBox(height: 14),
                Text(accent, style: AppTextStyles.dialogDanger),
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

  static Future<bool> _showDangerDecisionDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
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
                    Icons.delete_outline_rounded,
                    color: AppColors.badgeRedText,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dialogTitleCompact,
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dialogBodyCompact.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
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
                        backgroundColor: AppColors.modalPrimaryAction,
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
          backgroundColor: AppColors.transparent,
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
                  style: AppTextStyles.dialogTitle,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.dialogBody,
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
    Color backgroundColor = AppColors.modalPrimaryAction,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          backgroundColor: backgroundColor,
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
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
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
