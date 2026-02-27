import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/presentation/viewmodel/airport_view_model.dart';

enum _TradeExitAction { complete, cancel }

class AirportVisitorManifestPage extends ConsumerWidget {
  const AirportVisitorManifestPage({
    required this.uid,
    required this.islandId,
    required this.session,
    this.onInviteTap,
    super.key,
  });

  final String uid;
  final String islandId;
  final AirportSession session;
  final VoidCallback? onInviteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (uid: uid, islandId: islandId);
    final state = ref.watch(airportViewModelProvider(args));
    final viewModel = ref.read(airportViewModelProvider(args).notifier);
    final resolvedSession = state.session ?? session;
    final visitors = state.activeVisitors;
    final currentCount = visitors.length;
    final capacity = resolvedSession.capacity;
    final progress = capacity <= 0
        ? 0.0
        : (currentCount / capacity).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('방문객 명단'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.s10,
            AppSpacing.pageHorizontal,
            110,
          ),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('현재 방문객', style: AppTextStyles.headingH1),
                  const SizedBox(height: 8),
                  Text(
                    '${resolvedSession.islandName} 입구 현황을 모니터링 중입니다.',
                    style: AppTextStyles.bodySecondaryStrong,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('섬 수용 인원', style: AppTextStyles.headingH3),
                      ),
                      Text(
                        '$currentCount',
                        style: AppTextStyles.bodyWithSize(
                          34,
                          color: AppColors.accentDeepOrange,
                          weight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '/$capacity',
                        style: AppTextStyles.bodyWithSize(
                          28,
                          color: AppColors.textHint,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.borderDefault,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (visitors.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(
                  '현재 방문객이 없어요.',
                  style: AppTextStyles.bodySecondaryStrong,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...visitors.asMap().entries.map((entry) {
                final index = entry.key;
                final visitor = entry.value;
                final isArrived =
                    visitor.status == AirportVisitRequestStatus.arrived;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visitors.length - 1 ? 0 : 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      children: <Widget>[
                        Text('${index + 1}', style: AppTextStyles.headingH3),
                        const SizedBox(width: 12),
                        ClipOval(
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: visitor.requesterAvatarUrl.trim().isEmpty
                                ? Image.asset(
                                    'assets/images/icon_raccoon_character.png',
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    visitor.requesterAvatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/icon_raccoon_character.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                visitor.requesterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyPrimaryStrong,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '목적: ${visitor.purpose.label}',
                                style: AppTextStyles.captionMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isArrived
                                ? AppColors.badgeYellowBg
                                : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isArrived ? '섬에 있음' : '오는 중',
                            style: AppTextStyles.captionWithColor(
                              isArrived
                                  ? AppColors.badgeBeigeText
                                  : AppColors.textSecondary,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () async {
                            if (!isArrived) {
                              await viewModel.markArrived(visitor.id);
                              return;
                            }

                            if (visitor.sourceType == 'market_trade' &&
                                (visitor.sourceOfferId?.trim().isNotEmpty ??
                                    false)) {
                              await _handleTradeVisitorExit(
                                context: context,
                                ref: ref,
                                airportViewModel: viewModel,
                                visitor: visitor,
                              );
                              return;
                            }

                            await viewModel.completeVisit(visitor.id);
                          },
                          icon: Icon(
                            isArrived
                                ? Icons.close_rounded
                                : Icons.check_rounded,
                            color: AppColors.textMuted,
                          ),
                          tooltip: isArrived ? '방문 종료' : '도착 처리',
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          6,
          AppSpacing.pageHorizontal,
          12,
        ),
        child: FilledButton(
          onPressed: onInviteTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.badgeBlueText,
            foregroundColor: AppColors.textInverse,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Text('방문객 추가'),
        ),
      ),
    );
  }

  Future<void> _handleTradeVisitorExit({
    required BuildContext context,
    required WidgetRef ref,
    required AirportViewModel airportViewModel,
    required AirportVisitRequest visitor,
  }) async {
    final action = await _showTradeExitActionDialog(context);
    if (action == null || !context.mounted) {
      return;
    }

    final offerId = visitor.sourceOfferId?.trim() ?? '';
    if (offerId.isEmpty) {
      await airportViewModel.completeVisit(visitor.id);
      return;
    }

    final offer = await ref
        .read(marketRepositoryProvider)
        .fetchOfferById(offerId);
    if (!context.mounted) {
      return;
    }
    if (offer == null) {
      await airportViewModel.completeVisit(visitor.id);
      return;
    }

    try {
      if (action == _TradeExitAction.complete) {
        await ref
            .read(marketViewModelProvider.notifier)
            .completeTrade(offer: offer);
      } else {
        await ref
            .read(marketViewModelProvider.notifier)
            .cancelTrade(offer: offer);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = _resolveTradeActionErrorMessage(
        error: error,
        action: action,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      return;
    }

    await airportViewModel.completeVisit(visitor.id);
  }

  Future<_TradeExitAction?> _showTradeExitActionDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<_TradeExitAction>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('거래 처리 선택', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '방문객이 퇴장했어요.\n연결된 거래를 완료할지 취소할지 선택해 주세요.',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(_TradeExitAction.cancel),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          side: const BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '거래 취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(_TradeExitAction.complete),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentDeepOrange,
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '거래 완료',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('닫기', style: AppTextStyles.captionSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolveTradeActionErrorMessage({
    required Object error,
    required _TradeExitAction action,
  }) {
    final fallback = action == _TradeExitAction.complete
        ? '거래 완료 처리에 실패했어요. 다시 시도해 주세요.'
        : '거래 취소 처리에 실패했어요. 다시 시도해 주세요.';
    if (error is StateError) {
      switch (error.message) {
        case 'trade_complete_unavailable':
          return '이미 종료된 거래예요.';
        case 'trade_complete_no_active_proposal':
          return '진행 중인 거래 상대가 없어 완료 처리할 수 없어요.';
        case 'trade_complete_permission_denied':
        case 'trade_cancel_permission_denied':
          return '거래 처리 권한이 없어요.';
        case 'trade_offer_not_found':
          return '거래 정보를 찾지 못했어요.';
      }
    }
    return fallback;
  }
}
