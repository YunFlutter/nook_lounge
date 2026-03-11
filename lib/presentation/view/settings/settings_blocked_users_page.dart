import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/blocked_user_summary.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_dialogs.dart';

class SettingsBlockedUsersPage extends ConsumerStatefulWidget {
  const SettingsBlockedUsersPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<SettingsBlockedUsersPage> createState() =>
      _SettingsBlockedUsersPageState();
}

class _SettingsBlockedUsersPageState
    extends ConsumerState<SettingsBlockedUsersPage> {
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');
  String? _processingUid;

  @override
  Widget build(BuildContext context) {
    final blockedUsersAsync = ref.watch(
      blockedUserSummariesProvider(widget.uid),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: const Text('차단 관리'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(blockedUserSummariesProvider(widget.uid));
          await ref.read(blockedUserSummariesProvider(widget.uid).future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SettingsUiTokens.horizontalPadding,
            SettingsUiTokens.verticalGap,
            SettingsUiTokens.horizontalPadding,
            SettingsUiTokens.verticalGap * 3,
          ),
          children: <Widget>[
            _guideCard(),
            const SizedBox(height: 16),
            blockedUsersAsync.when(
              loading: () => _loadingCard(),
              error: (error, _) => _errorCard(),
              data: (blockedUsers) {
                if (blockedUsers.isEmpty) {
                  return _emptyCard();
                }
                return Column(
                  children: blockedUsers
                      .map((summary) => _blockedUserCard(context, summary))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(SettingsUiTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('차단한 유저', style: AppTextStyles.headingH3),
          const SizedBox(height: 8),
          Text(
            '차단한 유저는 마켓 게시물과 방문 요청에서 서로 보이지 않아요.',
            style: AppTextStyles.bodySecondaryStrong,
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(SettingsUiTokens.cardRadius),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(SettingsUiTokens.cardRadius),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.badgeRedText,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text('차단 목록을 불러오지 못했어요.', style: AppTextStyles.headingH3),
          const SizedBox(height: 6),
          Text(
            '잠시 후 다시 시도해 주세요.',
            style: AppTextStyles.bodySecondaryStrong,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(SettingsUiTokens.cardRadius),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.block_outlined,
            color: AppColors.textMuted,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text('차단한 유저가 없어요.', style: AppTextStyles.headingH3),
          const SizedBox(height: 6),
          Text(
            '마켓이나 비행장에서 차단한 유저가 여기에 표시됩니다.',
            style: AppTextStyles.bodySecondaryStrong,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _blockedUserCard(BuildContext context, BlockedUserSummary summary) {
    final normalizedUid = summary.uid.trim();
    final isProcessing = _processingUid == normalizedUid;
    final subtitle = summary.islandName.trim().isEmpty
        ? normalizedUid
        : summary.islandName.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 52,
              height: 52,
              child: summary.hasAvatar
                  ? Image.network(
                      summary.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  summary.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyPrimaryHeavy,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMuted,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '차단일 ${_dateFormat.format(summary.blockedAt)}',
                    style: AppTextStyles.captionSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => _unblockUser(context: context, summary: summary),
              style: OutlinedButton.styleFrom(
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                side: const BorderSide(color: AppColors.borderDefault),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isProcessing ? '처리중...' : '해제',
                style: AppTextStyles.captionPrimaryHeavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Image.asset(
      'assets/images/icon_raccoon_character.png',
      fit: BoxFit.cover,
    );
  }

  Future<void> _unblockUser({
    required BuildContext context,
    required BlockedUserSummary summary,
  }) async {
    final shouldUnblock = await SettingsDialogs.showUserUnblockConfirm(
      context: context,
      displayName: summary.displayName,
    );
    if (!shouldUnblock || !context.mounted) {
      return;
    }

    setState(() {
      _processingUid = summary.uid;
    });

    try {
      await ref
          .read(userBlockRepositoryProvider)
          .unblockUser(uid: widget.uid, blockedUid: summary.uid);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('차단을 해제했어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('차단 해제에 실패했어요.\n$error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _processingUid = null;
        });
      }
    }
  }
}
