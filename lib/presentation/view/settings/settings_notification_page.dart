import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';

class SettingsNotificationPage extends ConsumerWidget {
  const SettingsNotificationPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(settingsNotificationPreferencesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('알림'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
        ),
        child: prefsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              '알림 설정을 불러오지 못했어요.\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondaryStrong,
            ),
          ),
          data: (prefs) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('푸시 알림', style: AppTextStyles.captionMuted),
                const SizedBox(height: SettingsUiTokens.sectionGap),
                _switchTile(
                  title: '내글에 거래 제안 알림',
                  value: prefs.tradeOfferEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    ref: ref,
                    type: SettingsNotificationType.tradeOffer,
                    enabled: enabled,
                  ),
                ),
                _switchTile(
                  title: '도도코드 초대 알림',
                  value: prefs.dodoCodeInviteEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    ref: ref,
                    type: SettingsNotificationType.dodoCodeInvite,
                    enabled: enabled,
                  ),
                ),
                _switchTile(
                  title: '내 방문 모집글에 대기열 추가 알림',
                  value: prefs.airportQueueStandbyEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    ref: ref,
                    type: SettingsNotificationType.airportQueueStandby,
                    enabled: enabled,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _updatePreference({
    required BuildContext context,
    required WidgetRef ref,
    required SettingsNotificationType type,
    required bool enabled,
  }) async {
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateNotificationPreference(uid: uid, type: type, enabled: enabled);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('알림 설정 저장에 실패했어요.\n$error')));
    }
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 64,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyWithSize(
                20,
                color: AppColors.textSecondary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 1.05,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.accentOrange,
              inactiveTrackColor: AppColors.borderDefault,
              activeThumbColor: AppColors.white,
              inactiveThumbColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
