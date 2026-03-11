import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';

class SettingsNotificationPage extends ConsumerStatefulWidget {
  const SettingsNotificationPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<SettingsNotificationPage> createState() =>
      _SettingsNotificationPageState();
}

class _SettingsNotificationPageState
    extends ConsumerState<SettingsNotificationPage> {
  SettingsNotificationPreferences? _optimisticPrefs;

  @override
  Widget build(BuildContext context) {
    final prefsProvider = settingsNotificationPreferencesProvider(widget.uid);
    ref.listen<AsyncValue<SettingsNotificationPreferences>>(prefsProvider, (
      previous,
      next,
    ) {
      next.whenData((prefs) {
        final optimisticPrefs = _optimisticPrefs;
        if (!mounted || optimisticPrefs == null) {
          return;
        }
        if (_samePreferences(optimisticPrefs, prefs)) {
          setState(() {
            _optimisticPrefs = null;
          });
        }
      });
    });
    final prefsAsync = ref.watch(prefsProvider);

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
            final effectivePrefs = _optimisticPrefs ?? prefs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('푸시 알림', style: AppTextStyles.captionMuted),
                const SizedBox(height: SettingsUiTokens.sectionGap),
                _switchTile(
                  title: '내글에 거래 제안 알림',
                  value: effectivePrefs.tradeOfferEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    currentPrefs: effectivePrefs,
                    type: SettingsNotificationType.tradeOffer,
                    enabled: enabled,
                  ),
                ),
                _switchTile(
                  title: '도도코드 초대 알림',
                  value: effectivePrefs.dodoCodeInviteEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    currentPrefs: effectivePrefs,
                    type: SettingsNotificationType.dodoCodeInvite,
                    enabled: enabled,
                  ),
                ),
                _switchTile(
                  title: '내 방문 모집글에 대기열 추가 알림',
                  value: effectivePrefs.airportQueueStandbyEnabled,
                  onChanged: (enabled) => _updatePreference(
                    context: context,
                    currentPrefs: effectivePrefs,
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
    required SettingsNotificationPreferences currentPrefs,
    required SettingsNotificationType type,
    required bool enabled,
  }) async {
    final nextPrefs = _patchPreferences(
      currentPrefs: currentPrefs,
      type: type,
      enabled: enabled,
    );
    setState(() {
      _optimisticPrefs = nextPrefs;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateNotificationPreference(
            uid: widget.uid,
            type: type,
            enabled: enabled,
          );
    } catch (error) {
      if (mounted) {
        setState(() {
          _optimisticPrefs = null;
        });
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('알림 설정 저장에 실패했어요.\n$error')));
    }
  }

  SettingsNotificationPreferences _patchPreferences({
    required SettingsNotificationPreferences currentPrefs,
    required SettingsNotificationType type,
    required bool enabled,
  }) {
    switch (type) {
      case SettingsNotificationType.tradeOffer:
        return currentPrefs.copyWith(tradeOfferEnabled: enabled);
      case SettingsNotificationType.dodoCodeInvite:
        return currentPrefs.copyWith(dodoCodeInviteEnabled: enabled);
      case SettingsNotificationType.airportQueueStandby:
        return currentPrefs.copyWith(airportQueueStandbyEnabled: enabled);
    }
  }

  bool _samePreferences(
    SettingsNotificationPreferences left,
    SettingsNotificationPreferences right,
  ) {
    return left.tradeOfferEnabled == right.tradeOfferEnabled &&
        left.dodoCodeInviteEnabled == right.dodoCodeInviteEnabled &&
        left.airportQueueStandbyEnabled == right.airportQueueStandbyEnabled;
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
