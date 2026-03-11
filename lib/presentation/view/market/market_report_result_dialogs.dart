import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';

class MarketReportResultDialogs {
  const MarketReportResultDialogs._();

  static Future<void> showSubmitted(BuildContext context) {
    return _showStatusDialog(
      context: context,
      title: '신고가 접수되었습니다.',
      icon: const Icon(Icons.check_rounded, color: AppColors.white, size: 28),
      iconBackgroundColor: AppColors.settingsSuccessIcon,
    );
  }

  static Future<void> showDuplicate(BuildContext context) {
    return _showStatusDialog(
      context: context,
      title: '중복된 신고입니다.',
      icon: Text('!', style: AppTextStyles.dialogDanger),
      iconBackgroundColor: AppColors.transparent,
    );
  }

  static Future<void> _showStatusDialog({
    required BuildContext context,
    required String title,
    required Widget icon,
    required Color iconBackgroundColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.settingsOverlay,
      builder: (dialogContext) {
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
                const SizedBox(height: 18),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      overlayColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      backgroundColor: AppColors.modalPrimaryAction,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SettingsUiTokens.actionButtonRadius,
                        ),
                      ),
                    ),
                    child: Text('확인', style: AppTextStyles.buttonPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
