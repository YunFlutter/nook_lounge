import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/view/home/home_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_dialogs.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_document_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_island_edit_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_island_list_sheet.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_notice_list_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_notification_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_support_center_page.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final islandsAsync = ref.watch(homeDashboardIslandsProvider(uid));
    final primaryIslandIdAsync = ref.watch(
      homeDashboardPrimaryIslandIdProvider(uid),
    );
    final islands = islandsAsync.valueOrNull ?? const <IslandProfile>[];
    final selectedIsland = _resolveSelectedIsland(
      islands: islands,
      primaryIslandId: primaryIslandIdAsync.valueOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap * 3,
        ),
        children: <Widget>[
          _sectionLabel('섬 정보'),
          const SizedBox(height: 6),
          _menuTile(
            title: '섬 정보 수정',
            onTap: () {
              if (islandsAsync.hasError || primaryIslandIdAsync.hasError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('섬 정보를 불러오지 못했어요.')),
                  );
                return;
              }
              if (islandsAsync.isLoading || primaryIslandIdAsync.isLoading) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('섬 정보를 불러오는 중이에요.')),
                  );
                return;
              }
              if (islands.isEmpty) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('수정할 섬이 아직 없어요.')),
                  );
                return;
              }

              _openIslandListSheet(
                context: context,
                islands: islands,
                selectedIslandId: selectedIsland?.id,
              );
            },
          ),
          const SizedBox(height: SettingsUiTokens.sectionGap),
          const Divider(height: 1),
          const SizedBox(height: SettingsUiTokens.sectionGap),
          _menuTile(
            title: '알림',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsNotificationPage(uid: uid),
              ),
            ),
          ),
          _menuTile(
            title: '공지사항',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsNoticeListPage(),
              ),
            ),
          ),
          _menuTile(
            title: '고객센터',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsSupportCenterPage(
                  uid: uid,
                  displayName: selectedIsland?.representativeName ?? '',
                ),
              ),
            ),
          ),
          _menuTile(
            title: '운영정책',
            onTap: () =>
                _openDocument(context, SettingsDocumentType.operationPolicy),
          ),
          _menuTile(
            title: '이용약관',
            onTap: () =>
                _openDocument(context, SettingsDocumentType.termsOfService),
          ),
          _menuTile(
            title: '개인정보처리방침',
            onTap: () =>
                _openDocument(context, SettingsDocumentType.privacyPolicy),
          ),
          _menuTile(title: '앱 버전', trailingText: AppStrings.appVersion),
          const SizedBox(height: SettingsUiTokens.sectionGap),
          const Divider(height: 1),
          const SizedBox(height: SettingsUiTokens.sectionGap),
          _menuTile(
            title: '로그아웃',
            showChevron: false,
            onTap: () => _logout(context: context, ref: ref),
          ),
          _menuTile(
            title: '탈퇴하기',
            showChevron: false,
            onTap: () => _withdraw(context: context, ref: ref),
          ),
        ],
      ),
    );
  }

  IslandProfile? _resolveSelectedIsland({
    required List<IslandProfile> islands,
    required String? primaryIslandId,
  }) {
    if (islands.isEmpty) {
      return null;
    }
    if (primaryIslandId == null || primaryIslandId.trim().isEmpty) {
      return islands.first;
    }
    for (final island in islands) {
      if (island.id == primaryIslandId.trim()) {
        return island;
      }
    }
    return islands.first;
  }

  Future<void> _openIslandListSheet({
    required BuildContext context,
    required List<IslandProfile> islands,
    required String? selectedIslandId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SettingsIslandListSheet(
          islands: islands,
          selectedIslandId: selectedIslandId,
          onIslandTap: (island) async {
            Navigator.of(sheetContext).pop();
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SettingsIslandEditPage(uid: uid, island: island),
              ),
            );
          },
        );
      },
    );
  }

  void _openDocument(BuildContext context, SettingsDocumentType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsDocumentPage(type: type)),
    );
  }

  Future<void> _logout({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요.\n$error')));
    }
  }

  Future<void> _withdraw({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final confirmed = await SettingsDialogs.showWithdrawConfirm(context);
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(authRepositoryProvider).requestWithdrawal();
      if (!context.mounted) {
        return;
      }
      await SettingsDialogs.showWithdrawalCompleted(context);
      if (!context.mounted) {
        return;
      }
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('탈퇴 처리에 실패했어요.\n$error')));
    }
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: AppTextStyles.captionMuted);
  }

  Widget _menuTile({
    required String title,
    VoidCallback? onTap,
    bool showChevron = true,
    String? trailingText,
  }) {
    final tile = SizedBox(
      height: 54,
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
          if (trailingText != null)
            Text(
              trailingText,
              style: AppTextStyles.bodyWithSize(
                14,
                color: AppColors.textMuted,
                weight: FontWeight.w700,
              ),
            )
          else if (showChevron)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 28,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return tile;
    }

    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SettingsUiTokens.tileRadius),
        child: tile,
      ),
    );
  }
}
