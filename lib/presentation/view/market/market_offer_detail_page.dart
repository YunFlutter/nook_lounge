import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_view_page.dart';

class MarketOfferDetailPage extends ConsumerWidget {
  const MarketOfferDetailPage({required this.offer, super.key});

  final MarketOffer offer;

  String get _appBarTitle {
    // 유지보수 포인트:
    // API/데이터 매핑 이슈로 특정 필드가 비어도
    // 상세 상단 타이틀이 사라지지 않도록 우선순위 fallback을 둡니다.
    final candidates = <String>[
      offer.title,
      offer.offerItemName,
      offer.wantItemName,
      '거래 상세',
    ];

    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '거래 상세';
  }

  String get _offerOwnerName {
    final value = offer.ownerName.trim();
    if (value.isEmpty) {
      return '거래자';
    }
    return value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId;
    final isMine =
        offer.isMine ||
        (currentUid.isNotEmpty && offer.ownerUid.trim() == currentUid);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_appBarTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showSimpleMenu(context, ref, isMine: isMine),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          120,
        ),
        children: <Widget>[
          if (offer.coverImageUrl.trim().isNotEmpty) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 230,
                child: _buildImage(offer.coverImageUrl),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('교환 제안', style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 12),
          _buildTradeSummaryCard(),
          const SizedBox(height: 20),
          isMine
              ? _buildOwnerProposalQueueSection(context, ref)
              : _buildMyProposalStatusSection(ref, currentUid),
          const SizedBox(height: 20),
          Text('거래 이동 방식', style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.catalogChipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    offer.moveType == MarketMoveType.host
                        ? Icons.home_rounded
                        : Icons.flight_takeoff_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    offer.moveType.label,
                    style: AppTextStyles.bodyPrimaryHeavy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('방문객 안내 사항', style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              offer.description.isEmpty ? '상세 안내가 없어요.' : offer.description,
              style: AppTextStyles.labelWithColor(
                AppColors.textPrimary,
                weight: FontWeight.w700,
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            10,
            AppSpacing.pageHorizontal,
            10,
          ),
          child: isMine
              ? _buildOwnerBottomActions(context, ref)
              : _buildVisitorBottomActions(
                  context,
                  ref,
                  currentUid: currentUid,
                ),
        ),
      ),
    );
  }

  Widget _buildVisitorBottomActions(
    BuildContext context,
    WidgetRef ref, {
    required String currentUid,
  }) {
    final AsyncValue<MarketTradeProposal?> myProposalAsync = currentUid.isEmpty
        ? const AsyncValue.data(null)
        : ref.watch(
            marketMyTradeProposalProvider((
              offerId: offer.id,
              proposerUid: currentUid,
            )),
          );

    var primaryLabel = '거래 할래요';
    var primaryBackground = AppColors.accentDeepOrange;
    VoidCallback? primaryOnPressed = () => _onTapTradeProposal(context, ref);
    var secondaryLabel = '닫기';
    VoidCallback? secondaryOnPressed = () => Navigator.of(context).pop();

    if (myProposalAsync.isLoading) {
      primaryLabel = '제안 상태 확인 중...';
      primaryBackground = AppColors.catalogChipBg;
      primaryOnPressed = null;
      secondaryLabel = '확인 중...';
      secondaryOnPressed = null;
    } else {
      final proposal = myProposalAsync.valueOrNull;
      switch (proposal?.status) {
        case MarketTradeProposalStatus.pending:
          primaryLabel = '제안 대기중';
          primaryBackground = AppColors.catalogChipBg;
          primaryOnPressed = null;
          secondaryLabel = '거래 취소';
          secondaryOnPressed = () => _cancelTradeAsParticipant(
            context,
            ref,
            hasAcceptedProposal: false,
          );
        case MarketTradeProposalStatus.accepted:
          primaryLabel = '코드 확인하기';
          primaryOnPressed = () => _openTradeCodePage(context, ref);
          secondaryLabel = '거래 취소';
          secondaryOnPressed = () => _cancelTradeAsParticipant(
            context,
            ref,
            hasAcceptedProposal: true,
          );
        case MarketTradeProposalStatus.rejected:
        case MarketTradeProposalStatus.cancelled:
          primaryLabel = '다시 제안하기';
          primaryOnPressed = () => _onTapTradeProposal(context, ref);
          secondaryLabel = '닫기';
          secondaryOnPressed = () => Navigator.of(context).pop();
        case null:
          primaryLabel = '거래 할래요';
          primaryOnPressed = () => _onTapTradeProposal(context, ref);
          secondaryLabel = '닫기';
          secondaryOnPressed = () => Navigator.of(context).pop();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton(
          onPressed: primaryOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primaryBackground,
            minimumSize: const Size.fromHeight(58),
          ),
          child: Text(primaryLabel, style: AppTextStyles.buttonPrimary),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: secondaryOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.borderDefault, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(secondaryLabel, style: AppTextStyles.buttonSecondary),
        ),
      ],
    );
  }

  Widget _buildOwnerBottomActions(BuildContext context, WidgetRef ref) {
    final bool canCancelTrade = offer.lifecycle == MarketLifecycleTab.ongoing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton(
          onPressed: canCancelTrade
              ? () => _completeMyOffer(context, ref)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentDeepOrange,
            disabledBackgroundColor: AppColors.catalogChipBg,
            minimumSize: const Size.fromHeight(58),
          ),
          child: Text('거래 완료할게요!', style: AppTextStyles.buttonPrimary),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: canCancelTrade
              ? () => _cancelTradeAsOwner(context, ref)
              : () => _deleteMyOffer(context, ref),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.borderDefault, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            canCancelTrade ? '거래 취소' : '거래 삭제',
            style: AppTextStyles.buttonSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMyProposalStatusSection(WidgetRef ref, String currentUid) {
    if (currentUid.trim().isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text(
          '로그인 후 거래 제안을 보낼 수 있어요.',
          style: AppTextStyles.captionMuted,
        ),
      );
    }

    final myProposalAsync = ref.watch(
      marketMyTradeProposalProvider((
        offerId: offer.id,
        proposerUid: currentUid,
      )),
    );
    return myProposalAsync.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('내 제안 상태를 확인하는 중...', style: AppTextStyles.captionMuted),
          ],
        ),
      ),
      error: (error, stackTrace) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text('제안 상태를 불러오지 못했어요.', style: AppTextStyles.captionHint),
      ),
      data: (proposal) {
        if (proposal == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Text(
              '아직 이 거래에 보낸 제안이 없어요.',
              style: AppTextStyles.captionMuted,
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: <Widget>[
              _buildProposalStatusBadge(proposal.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '업데이트: ${formatRelativeTime(proposal.updatedAt)}',
                  style: AppTextStyles.captionMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerProposalQueueSection(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(marketTradeProposalsProvider(offer.id));
    return proposalsAsync.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('거래 제안 목록을 불러오는 중...', style: AppTextStyles.captionMuted),
          ],
        ),
      ),
      error: (error, stackTrace) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Text('제안 목록을 불러오지 못했어요.', style: AppTextStyles.captionHint),
      ),
      data: (proposals) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '대기열 제안 ${proposals.length}건',
                style: AppTextStyles.bodySecondaryStrong,
              ),
              const SizedBox(height: 10),
              if (proposals.isEmpty)
                Text('아직 받은 거래 제안이 없어요.', style: AppTextStyles.captionMuted)
              else
                ...proposals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final proposal = entry.value;
                  final canAccept =
                      proposal.status == MarketTradeProposalStatus.pending;
                  final canOpenCode =
                      proposal.status == MarketTradeProposalStatus.accepted;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == proposals.length - 1 ? 0 : 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: <Widget>[
                          ClipOval(
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: _buildImage(proposal.proposerAvatarUrl),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  proposal.proposerName.trim().isEmpty
                                      ? '이름 없는 유저'
                                      : proposal.proposerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyPrimaryHeavy,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: <Widget>[
                                    _buildProposalStatusBadge(proposal.status),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatRelativeTime(proposal.updatedAt),
                                      style: AppTextStyles.captionMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (canAccept)
                            FilledButton(
                              onPressed: () =>
                                  _acceptProposal(context, ref, proposal),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentDeepOrange,
                                minimumSize: const Size(72, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(
                                '승낙',
                                style: AppTextStyles.captionWithColor(
                                  AppColors.white,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            )
                          else if (canOpenCode)
                            OutlinedButton(
                              onPressed: () => _openTradeCodePage(context, ref),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(84, 38),
                                side: const BorderSide(
                                  color: AppColors.borderStrong,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(
                                '코드',
                                style: AppTextStyles.captionWithColor(
                                  AppColors.textPrimary,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProposalStatusBadge(MarketTradeProposalStatus status) {
    Color bgColor = AppColors.catalogChipBg;
    Color textColor = AppColors.textMuted;
    switch (status) {
      case MarketTradeProposalStatus.pending:
        bgColor = AppColors.badgeYellowBg;
        textColor = AppColors.badgeYellowText;
      case MarketTradeProposalStatus.accepted:
        bgColor = AppColors.catalogSuccessBg;
        textColor = AppColors.catalogSuccessText;
      case MarketTradeProposalStatus.rejected:
        bgColor = AppColors.badgeRedBg;
        textColor = AppColors.badgeRedText;
      case MarketTradeProposalStatus.cancelled:
        bgColor = AppColors.catalogChipBg;
        textColor = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.captionWithColor(
          textColor,
          weight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTradeSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _buildItemMiniCard(
                  header: offer.offerHeaderLabel,
                  headerColor: AppColors.primaryDefault,
                  imageUrl: offer.offerItemImageUrl,
                  title: offer.offerItemName,
                  quantity: offer.offerItemQuantity,
                  categoryLabel: _resolveItemTypeLabel(isOfferSide: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.textAccent,
                ),
              ),
              Expanded(
                child: _buildItemMiniCard(
                  header: offer.wantHeaderLabel,
                  headerColor: AppColors.badgeBlueText,
                  imageUrl: offer.wantItemImageUrl,
                  title: offer.wantItemName,
                  quantity: offer.wantItemQuantity,
                  categoryLabel: _resolveItemTypeLabel(isOfferSide: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemMiniCard({
    required String header,
    required Color headerColor,
    required String imageUrl,
    required String title,
    required int quantity,
    required String categoryLabel,
  }) {
    final displayName = _resolvedDisplayName(title, quantity);
    final displayQuantity = _resolvedDisplayQuantity(title, quantity);
    return Column(
      children: <Widget>[
        Text(
          header.isEmpty ? '드려요' : header,
          style: AppTextStyles.labelWithColor(
            headerColor,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(6),
          child: _buildImage(imageUrl),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 4),
        _buildItemTypeBadge(categoryLabel),
        if (displayQuantity > 0) ...<Widget>[
          const SizedBox(height: 4),
          Text('X$displayQuantity', style: AppTextStyles.bodyPrimaryHeavy),
        ],
      ],
    );
  }

  Widget _buildItemTypeBadge(String label) {
    final String normalized = label.trim();
    Color bgColor = AppColors.catalogChipBg;
    Color textColor = AppColors.textMuted;
    IconData icon = Icons.inventory_2_rounded;

    switch (normalized) {
      case '재화':
        bgColor = AppColors.badgeBlueBg;
        textColor = AppColors.badgeBlueText;
        icon = Icons.paid_rounded;
      case '레시피':
        bgColor = AppColors.badgeYellowBg;
        textColor = AppColors.badgeYellowText;
        icon = Icons.description_rounded;
      case '주민':
        bgColor = AppColors.badgeMintBg;
        textColor = AppColors.badgeMintText;
        icon = Icons.person_rounded;
      case '만지작':
        bgColor = AppColors.badgePurpleBg;
        textColor = AppColors.badgePurpleText;
        icon = Icons.touch_app_rounded;
      case '아이템':
      default:
        bgColor = AppColors.badgeBeigeBg;
        textColor = AppColors.badgeBeigeText;
        icon = Icons.inventory_2_rounded;
    }

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 3),
          Text(
            normalized.isEmpty ? '아이템' : normalized,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              textColor,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveItemTypeLabel({required bool isOfferSide}) {
    final explicit = isOfferSide
        ? offer.offerItemCategory
        : offer.wantItemCategory;
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final name = isOfferSide ? offer.offerItemName : offer.wantItemName;
    final imageUrl = isOfferSide
        ? offer.offerItemImageUrl
        : offer.wantItemImageUrl;
    if (_isCurrencyLike(name: name, imageUrl: imageUrl)) {
      return '재화';
    }
    switch (offer.category) {
      case MarketFilterCategory.recipe:
        return '레시피';
      case MarketFilterCategory.villager:
        return '주민';
      case MarketFilterCategory.touching:
        return '만지작';
      case MarketFilterCategory.item:
      case MarketFilterCategory.all:
        return '아이템';
    }
  }

  bool _isCurrencyLike({required String name, required String imageUrl}) {
    if (imageUrl.contains('icon_recipe_scroll')) {
      return true;
    }
    if (imageUrl.contains('Nook_Miles_Ticket')) {
      return true;
    }
    return name.contains('벨') ||
        name.contains('마일 여행권') ||
        name.contains('마일 이용권');
  }

  String _resolvedDisplayName(String rawName, int quantity) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    final starPattern = RegExp(r'^(.+?)\s*\*\s*(\d+)$');
    final starMatch = starPattern.firstMatch(trimmed);
    if (starMatch != null && quantity <= 1) {
      return starMatch.group(1)?.trim() ?? trimmed;
    }
    return trimmed;
  }

  int _resolvedDisplayQuantity(String rawName, int quantity) {
    final safeQuantity = quantity <= 0 ? 0 : quantity;
    final starPattern = RegExp(r'^(.+?)\s*\*\s*(\d+)$');
    final starMatch = starPattern.firstMatch(rawName.trim());
    if (starMatch != null) {
      final parsed = int.tryParse(starMatch.group(2) ?? '');
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return safeQuantity;
  }

  Widget _buildImage(String source) {
    if (source.isEmpty) {
      return const SizedBox.shrink();
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
      );
    }
    if (source.startsWith('/')) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textHint,
        ),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textHint,
      ),
    );
  }

  Future<void> _onTapTradeProposal(BuildContext context, WidgetRef ref) async {
    final shouldProceed = await _showProposalConfirmDialog(context);
    if (shouldProceed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .sendTradeProposal(offer: offer);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 진행을 시작하지 못했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('거래 제안을 보냈어요. 작성자 승낙을 기다려 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _acceptProposal(
    BuildContext context,
    WidgetRef ref,
    MarketTradeProposal proposal,
  ) async {
    final shouldAccept = await _showAcceptProposalDialog(context, proposal);
    if (shouldAccept != true || !context.mounted) {
      return;
    }

    late final MarketTradeCodeSession session;
    late final bool shouldSendCode;
    try {
      final result = await ref
          .read(marketViewModelProvider.notifier)
          .acceptTradeProposalAsOwner(
            offer: offer,
            proposerUid: proposal.proposerUid,
          );
      session = result.session;
      shouldSendCode = result.shouldSendCode;
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('제안 승낙에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('선택한 제안을 승낙했어요. 거래 코드를 준비해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    if (shouldSendCode) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MarketTradeCodeSendPage(offer: offer, session: session),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketTradeCodeViewPage(offer: offer),
      ),
    );
  }

  Future<bool?> _showProposalConfirmDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<bool>(
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
                Text('거래 제안 보내기', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '$_offerOwnerName님에게 거래 제안을 보낼까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '보내기',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }

  Future<bool?> _showAcceptProposalDialog(
    BuildContext context,
    MarketTradeProposal proposal,
  ) {
    const dialogButtonHeight = 54.0;
    final proposerName = proposal.proposerName.trim().isEmpty
        ? '선택한 유저'
        : proposal.proposerName.trim();
    return showDialog<bool>(
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
                Text('제안 승낙', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '$proposerName님의 제안을 승낙할까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '승낙',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }

  Future<void> _showSimpleMenu(
    BuildContext context,
    WidgetRef ref, {
    required bool isMine,
  }) async {
    if (isMine) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('코드 확인'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _openTradeCodePage(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('삭제하기'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _deleteMyOffer(context, ref);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: const Text('코드 확인'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _openTradeCodePage(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('숨기기'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _hideOffer(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('신고하기'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _reportOffer(context, ref);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTradeCodePage(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final session = await viewModel.fetchTradeCodeSession(offer.id);
    if (!context.mounted) {
      return;
    }
    if (session == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('아직 거래 코드가 생성되지 않았어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final currentUid = viewModel.currentUserId;
    final shouldSendCode = session.isCodeSender(currentUid) && !session.hasCode;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => shouldSendCode
            ? MarketTradeCodeSendPage(offer: offer, session: session)
            : MarketTradeCodeViewPage(offer: offer),
      ),
    );
  }

  Future<void> _reportOffer(BuildContext context, WidgetRef ref) async {
    final result = await _showReportDialog(context);
    if (result == null || !context.mounted) {
      return;
    }
    final (reason, detail) = result;
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .reportOffer(offer: offer, reason: reason, detail: detail);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('신고 접수에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('신고가 접수되었어요. 검토 후 처리할게요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _hideOffer(BuildContext context, WidgetRef ref) async {
    final shouldHide = await _showHideConfirmDialog(context);
    if (shouldHide != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(marketViewModelProvider.notifier).hideOffer(offer: offer);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 글 숨기기에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('거래 글을 숨겼어요. 목록에서 제외됩니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Navigator.of(context).pop();
  }

  Future<bool?> _showHideConfirmDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<bool>(
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
                Text('거래 글 숨기기', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '이 거래 글을 목록에서 숨길까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '숨기기',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }

  Future<(String, String)?> _showReportDialog(BuildContext context) {
    const reasons = <String>['사기/허위 내용', '욕설/비매너', '거래 제안 또는 수락 후 연락두절', '기타'];
    const dialogButtonHeight = 54.0;

    String selectedReason = reasons.first;
    String detail = '';
    return showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    Text('신고하기', style: AppTextStyles.dialogTitleCompact),
                    const SizedBox(height: 10),
                    Text(
                      '신고 사유를 선택해 주세요.',
                      style: AppTextStyles.dialogBodyCompact,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.bgSecondary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderDefault,
                          ),
                        ),
                      ),
                      items: reasons
                          .map(
                            (reason) => DropdownMenuItem<String>(
                              value: reason,
                              child: Text(
                                reason,
                                style: AppTextStyles.bodySecondaryStrong,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          selectedReason = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 300,
                      style: AppTextStyles.bodySecondaryStrong,
                      decoration: const InputDecoration(
                        hintText: '상세 사유(선택)',
                        counterText: '',
                      ),
                      onChanged: (value) {
                        detail = value;
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                dialogButtonHeight,
                              ),
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: AppTextStyles.dialogButtonOutline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop((selectedReason, detail.trim()));
                            },
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
                              '접수',
                              style: AppTextStyles.dialogButtonPrimary,
                            ),
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
      },
    );
  }

  Future<void> _completeMyOffer(BuildContext context, WidgetRef ref) async {
    final shouldComplete = await _showCompleteConfirmDialog(context);
    if (shouldComplete != true || !context.mounted) {
      return;
    }
    await ref
        .read(marketViewModelProvider.notifier)
        .completeTrade(offer: offer);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('거래를 완료로 변경했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _cancelTradeAsParticipant(
    BuildContext context,
    WidgetRef ref, {
    required bool hasAcceptedProposal,
  }) async {
    final shouldCancel = await _showTradeCancelConfirmDialog(
      context,
      hasAcceptedProposal: hasAcceptedProposal,
      isOwner: false,
    );
    if (shouldCancel != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .cancelTrade(offer: offer);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 취소에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hasAcceptedProposal
                ? '거래를 취소했어요. 게시글이 다시 대기 상태로 돌아갔어요.'
                : '보낸 거래 제안을 취소했어요.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _cancelTradeAsOwner(BuildContext context, WidgetRef ref) async {
    final shouldCancel = await _showTradeCancelConfirmDialog(
      context,
      hasAcceptedProposal: true,
      isOwner: true,
    );
    if (shouldCancel != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .cancelTrade(offer: offer);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 취소에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('진행 중인 거래를 취소했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool?> _showTradeCancelConfirmDialog(
    BuildContext context, {
    required bool hasAcceptedProposal,
    required bool isOwner,
  }) {
    const dialogButtonHeight = 54.0;
    final String message = hasAcceptedProposal
        ? (isOwner
              ? '현재 승낙된 거래를 취소하고 게시글을 다시 열까요?'
              : '진행 중인 거래를 취소하고 대기 상태로 돌릴까요?')
        : '보낸 거래 제안을 취소할까요?';
    return showDialog<bool>(
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
                Text('거래 취소', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(message, style: AppTextStyles.dialogBodyCompact),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '유지',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '취소하기',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }

  Future<bool?> _showCompleteConfirmDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<bool>(
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
                Text('거래 완료 처리', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '이 거래를 완료 상태로 변경할까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '완료',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }

  Future<void> _deleteMyOffer(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await _showDeleteConfirmDialog(context);
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    await ref.read(marketViewModelProvider.notifier).deleteOffer(offer.id);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('거래 글을 삭제했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<bool>(
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
                Text('거래 글 삭제', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '정말 이 거래 글을 삭제할까요?',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 6),
                Text('삭제 후에는 복구할 수 없어요.', style: AppTextStyles.dialogDanger),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
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
                          '취소',
                          style: AppTextStyles.dialogButtonOutline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
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
                          '삭제',
                          style: AppTextStyles.dialogButtonPrimary,
                        ),
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
  }
}
