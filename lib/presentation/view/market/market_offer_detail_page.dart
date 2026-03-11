import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/constants/market_report_constants.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/core/utils/touching_item_tag_codec.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/presentation/view/common/home_style_app_bar_title.dart';
import 'package:nook_lounge_app/presentation/view/market/market_report_reason_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_report_result_dialogs.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_send_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_view_page.dart';

final _marketOfferDetailIslandsProvider = StreamProvider.autoDispose
    .family<List<IslandProfile>, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchIslands(uid);
    });

final _marketOfferDetailPrimaryIslandIdProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchPrimaryIslandId(uid);
    });

IslandProfile? _resolveSelectedIslandForMarketOfferDetail({
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

class MarketOfferDetailPage extends ConsumerWidget {
  const MarketOfferDetailPage({required this.offer, super.key});

  static const double _sectionCornerRadius = 28;
  static const double _panelCornerRadius = 22;

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

  bool get _isCompletedOffer {
    return offer.lifecycle == MarketLifecycleTab.completed ||
        offer.status == MarketOfferStatus.closed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOffer = _resolveCurrentOffer(ref);
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId;
    final isMine =
        currentOffer.isMine ||
        (currentUid.isNotEmpty && currentOffer.ownerUid.trim() == currentUid);
    final canOpenSimpleMenu = _canOpenSimpleMenu(
      isMine: isMine,
      currentOffer: currentOffer,
    );
    final showBottomActionBar =
        !isMine || !_isCompletedOfferByStatus(currentOffer);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: HomeStyleAppBarTitle(_appBarTitle, maxLines: 1),
        actions: canOpenSimpleMenu
            ? <Widget>[
                IconButton(
                  onPressed: () => _showSimpleMenu(
                    context,
                    ref,
                    isMine: isMine,
                    currentOffer: currentOffer,
                  ),
                  icon: const Icon(Icons.more_vert_rounded),
                ),
              ]
            : const <Widget>[],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          showBottomActionBar ? 136 : 40,
        ),
        children: <Widget>[
          if (offer.coverImageUrl.trim().isNotEmpty) ...<Widget>[
            _buildCoverImageCard(),
            const SizedBox(height: AppSpacing.s20),
          ],
          _buildOfferOverviewCard(ref, currentOffer),
          const SizedBox(height: AppSpacing.s18),
          _buildSectionCard(
            title: isMine ? '받은 거래 제안' : '내 거래 제안',
            child: isMine
                ? _buildOwnerProposalQueueSection(
                    context,
                    ref,
                    currentOffer: currentOffer,
                  )
                : _buildMyProposalStatusSection(ref, currentUid),
          ),
          const SizedBox(height: AppSpacing.s18),
          _buildSectionCard(title: '거래 이동 방식', child: _buildMoveTypePanel()),
          const SizedBox(height: AppSpacing.s18),
          _buildSectionCard(
            title: '방문객 안내 사항',
            child: _buildVisitorGuidePanel(),
          ),
        ],
      ),
      bottomNavigationBar: showBottomActionBar
          ? _buildBottomActionBar(
              child: isMine
                  ? _buildOwnerBottomActions(
                      context,
                      ref,
                      currentOffer: currentOffer,
                    )
                  : _buildVisitorBottomActions(
                      context,
                      ref,
                      currentUid: currentUid,
                      currentOffer: currentOffer,
                    ),
            )
          : null,
    );
  }

  MarketOffer _resolveCurrentOffer(WidgetRef ref) {
    final offers = ref.watch(
      marketViewModelProvider.select((state) {
        return state.offers;
      }),
    );
    for (final item in offers) {
      if (item.id == offer.id) {
        return item;
      }
    }
    return offer;
  }

  bool _isInactiveOffer(MarketOffer target) {
    final isCompleted =
        target.lifecycle == MarketLifecycleTab.completed ||
        target.status == MarketOfferStatus.closed;
    final isCancelled =
        target.lifecycle == MarketLifecycleTab.cancelled ||
        target.status == MarketOfferStatus.offline;
    return isCompleted || isCancelled;
  }

  bool _isCancelledOffer(MarketOffer target) {
    return target.lifecycle == MarketLifecycleTab.cancelled ||
        target.status == MarketOfferStatus.offline;
  }

  bool _isCompletedOfferByStatus(MarketOffer target) {
    return target.lifecycle == MarketLifecycleTab.completed ||
        target.status == MarketOfferStatus.closed;
  }

  bool _canOpenSimpleMenu({
    required bool isMine,
    required MarketOffer currentOffer,
  }) {
    if (!isMine) {
      return true;
    }

    final isInactiveOffer = _isInactiveOffer(currentOffer);
    final canDeleteMineOffer =
        !isInactiveOffer &&
        currentOffer.status != MarketOfferStatus.waiting &&
        currentOffer.status != MarketOfferStatus.trading;
    return canDeleteMineOffer;
  }

  // 유지보수 포인트:
  // 상세 화면의 카드 질감(반경/보더/그림자)을 한 곳에서 맞추면
  // 이후 시장 화면 전체의 톤을 바꿀 때 이 메서드만 조정하면 됩니다.
  BoxDecoration _buildSurfaceDecoration({
    required Color color,
    required double radius,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.borderDefault.withValues(
          alpha: elevated ? 0.78 : 0.68,
        ),
      ),
      boxShadow: elevated
          ? <BoxShadow>[
              const BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ]
          : const <BoxShadow>[],
    );
  }

  Widget _buildCoverImageCard() {
    return Container(
      decoration: _buildSurfaceDecoration(
        color: AppColors.bgCard,
        radius: _sectionCornerRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(height: 230, child: _buildImage(offer.coverImageUrl)),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: _buildSurfaceDecoration(color: AppColors.bgCard, radius: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: AppTextStyles.bodyPrimaryHeavy),
            const SizedBox(height: AppSpacing.s10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInsetPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color backgroundColor = AppColors.bgSecondary,
    bool elevated = false,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: _buildSurfaceDecoration(
        color: backgroundColor,
        radius: _panelCornerRadius,
        elevated: elevated,
      ),
      child: child,
    );
  }

  Widget _buildBottomActionBar({required Widget child}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          AppSpacing.s12,
        ),
        child: child,
      ),
    );
  }

  Widget _buildOfferOverviewCard(WidgetRef ref, MarketOffer currentOffer) {
    final ownerUid = currentOffer.ownerUid.trim();
    final islandsAsync = ownerUid.isEmpty
        ? null
        : ref.watch(_marketOfferDetailIslandsProvider(ownerUid));
    final primaryIslandIdAsync = ownerUid.isEmpty
        ? null
        : ref.watch(_marketOfferDetailPrimaryIslandIdProvider(ownerUid));
    final selectedIsland = _resolveSelectedIslandForMarketOfferDetail(
      islands: islandsAsync?.valueOrNull ?? const <IslandProfile>[],
      primaryIslandId: primaryIslandIdAsync?.valueOrNull,
    );
    final displayName = _resolveOfferOwnerDisplayName(
      currentOffer: currentOffer,
      selectedIsland: selectedIsland,
    );
    final islandName = (selectedIsland?.islandName ?? '').trim();
    final avatarUrl = _resolveOfferOwnerAvatarUrl(
      currentOffer: currentOffer,
      selectedIsland: selectedIsland,
    );
    final hemisphere = (selectedIsland?.hemisphere ?? '').trim();
    final nativeFruit = (selectedIsland?.nativeFruit ?? '').trim();
    final ownerInfoLine = _buildOfferOwnerInfoLine(
      islandName: islandName,
      hemisphere: hemisphere,
      nativeFruit: nativeFruit,
    );
    final secondaryText = ownerInfoLine.isNotEmpty
        ? ownerInfoLine
        : ownerUid.isEmpty
        ? '게시자 정보 일부만 표시하고 있어요.'
        : (islandsAsync?.isLoading == true ||
              primaryIslandIdAsync?.isLoading == true)
        ? '대표 섬 정보를 불러오는 중이에요.'
        : '등록된 대표 섬 정보가 없어요.';

    return Semantics(
      label: '거래 요약 카드',
      child: Container(
        width: double.infinity,
        decoration: _buildSurfaceDecoration(
          color: AppColors.bgCard,
          radius: _sectionCornerRadius,
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Wrap(
                  //   spacing: AppSpacing.s8,
                  //   runSpacing: AppSpacing.s8,
                  //   children: <Widget>[
                  //     _buildOfferMetaBadge(
                  //       label: _resolveOfferPhaseLabel(currentOffer),
                  //       backgroundColor: _resolveOfferPhaseBackground(
                  //         currentOffer,
                  //       ),
                  //       textColor: _resolveOfferPhaseTextColor(currentOffer),
                  //     ),
                  //   ],
                  // ),
                  _buildTradeSummaryCard(embedded: true),
                ],
              ),
            ),
            _buildOfferOwnerFooter(
              displayName: displayName,
              secondaryText: secondaryText,
              avatarUrl: avatarUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferOwnerFooter({
    required String displayName,
    required String secondaryText,
    required String avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_sectionCornerRadius - 1),
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.borderDefault.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: avatarUrl.isEmpty
                  ? Image.asset(
                      'assets/images/icon_raccoon_character.png',
                      fit: BoxFit.cover,
                    )
                  : _buildImage(avatarUrl),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyPrimaryHeavy.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferMetaBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionWithColor(
          textColor,
          weight: FontWeight.w800,
        ),
      ),
    );
  }

  String _resolveOfferPhaseLabel(MarketOffer target) {
    if (_isCancelledOffer(target)) {
      return '거래 취소';
    }
    if (_isCompletedOfferByStatus(target)) {
      return '거래 완료';
    }
    switch (target.status) {
      case MarketOfferStatus.open:
        return '제안 받는 중';
      case MarketOfferStatus.waiting:
        return '상대 응답 대기';
      case MarketOfferStatus.closed:
        return '거래 마감';
      case MarketOfferStatus.offline:
        return '오프라인';
      case MarketOfferStatus.trading:
        return '거래 진행 중';
    }
  }

  Color _resolveOfferPhaseBackground(MarketOffer target) {
    if (_isCancelledOffer(target)) {
      return AppColors.badgeRedBg;
    }
    if (_isCompletedOfferByStatus(target)) {
      return AppColors.catalogSuccessBg;
    }
    switch (target.status) {
      case MarketOfferStatus.open:
        return AppColors.badgeMintBg;
      case MarketOfferStatus.waiting:
        return AppColors.badgeYellowBg;
      case MarketOfferStatus.closed:
        return AppColors.badgeBeigeBg;
      case MarketOfferStatus.offline:
        return AppColors.catalogChipBg;
      case MarketOfferStatus.trading:
        return AppColors.badgeBlueBg;
    }
  }

  Color _resolveOfferPhaseTextColor(MarketOffer target) {
    if (_isCancelledOffer(target)) {
      return AppColors.badgeRedText;
    }
    if (_isCompletedOfferByStatus(target)) {
      return AppColors.catalogSuccessText;
    }
    switch (target.status) {
      case MarketOfferStatus.open:
        return AppColors.badgeMintText;
      case MarketOfferStatus.waiting:
        return AppColors.badgeYellowText;
      case MarketOfferStatus.closed:
        return AppColors.badgeBeigeText;
      case MarketOfferStatus.offline:
        return AppColors.textMuted;
      case MarketOfferStatus.trading:
        return AppColors.badgeBlueText;
    }
  }

  String _buildOfferOwnerInfoLine({
    required String islandName,
    required String hemisphere,
    required String nativeFruit,
  }) {
    final segments = <String>[
      if (islandName.isNotEmpty) islandName,
      if (hemisphere.isNotEmpty) hemisphere,
      if (nativeFruit.isNotEmpty) nativeFruit,
    ];
    return segments.join(' · ');
  }

  String _resolveOfferOwnerDisplayName({
    required MarketOffer currentOffer,
    required IslandProfile? selectedIsland,
  }) {
    // 유지보수 포인트:
    // 거래 글에는 등록 시점 이름이 저장되지만, 상세에서는 대표 섬 스트림을 우선 사용해
    // 프로필 수정 후에도 최신 대표 주민명을 보여주도록 보강합니다.
    final representativeName = (selectedIsland?.representativeName ?? '')
        .trim();
    if (representativeName.isNotEmpty) {
      return representativeName;
    }
    final ownerName = currentOffer.ownerName.trim();
    if (ownerName.isNotEmpty) {
      return ownerName;
    }
    final islandName = (selectedIsland?.islandName ?? '').trim();
    if (islandName.isNotEmpty) {
      return islandName;
    }
    return '거래자';
  }

  String _resolveOfferOwnerAvatarUrl({
    required MarketOffer currentOffer,
    required IslandProfile? selectedIsland,
  }) {
    final latestImageUrl = (selectedIsland?.imageUrl ?? '').trim();
    if (latestImageUrl.isNotEmpty) {
      return latestImageUrl;
    }
    return currentOffer.ownerAvatarUrl.trim();
  }

  Widget _buildVisitorBottomActions(
    BuildContext context,
    WidgetRef ref, {
    required String currentUid,
    required MarketOffer currentOffer,
  }) {
    if (_isInactiveOffer(currentOffer)) {
      final title = _isCancelledOffer(currentOffer) ? '취소된 거래예요' : '완료된 거래예요';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildPrimaryBottomButton(
            label: title,
            onPressed: null,
            backgroundColor: AppColors.catalogChipBg,
          ),
          const SizedBox(height: AppSpacing.s10),
          _buildSecondaryBottomButton(
            label: '닫기',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

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
    VoidCallback? primaryOnPressed = () =>
        _onTapTradeProposal(context, ref, currentOffer: currentOffer);
    var secondaryLabel = '닫기';
    VoidCallback? secondaryOnPressed = () => Navigator.of(context).pop();
    final canCancelTrade = !_isInactiveOffer(currentOffer);
    final isOfferLockedByAcceptedTrade =
        currentOffer.status == MarketOfferStatus.waiting ||
        currentOffer.status == MarketOfferStatus.trading;

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
          secondaryLabel = canCancelTrade ? '거래 취소' : '닫기';
          secondaryOnPressed = canCancelTrade
              ? () => _cancelTradeAsParticipant(
                  context,
                  ref,
                  hasAcceptedProposal: false,
                )
              : () => Navigator.of(context).pop();
        case MarketTradeProposalStatus.accepted:
          if (!canCancelTrade) {
            primaryLabel = '거래 종료';
            primaryBackground = AppColors.catalogChipBg;
            primaryOnPressed = null;
            secondaryLabel = '닫기';
            secondaryOnPressed = () => Navigator.of(context).pop();
          } else {
            primaryLabel = '코드 확인하기';
            primaryOnPressed = () =>
                _openTradeCodePage(context, ref, currentOffer: currentOffer);
            secondaryLabel = canCancelTrade ? '거래 취소' : '닫기';
            secondaryOnPressed = canCancelTrade
                ? () => _cancelTradeAsParticipant(
                    context,
                    ref,
                    hasAcceptedProposal: true,
                  )
                : () => Navigator.of(context).pop();
          }
        case MarketTradeProposalStatus.rejected:
          primaryLabel = '거절된 제안';
          primaryBackground = AppColors.catalogChipBg;
          primaryOnPressed = null;
          secondaryLabel = '닫기';
          secondaryOnPressed = () => Navigator.of(context).pop();
        case MarketTradeProposalStatus.cancelled:
          primaryLabel = '취소된 제안';
          primaryBackground = AppColors.catalogChipBg;
          primaryOnPressed = null;
          secondaryLabel = '닫기';
          secondaryOnPressed = () => Navigator.of(context).pop();
        case null:
          if (isOfferLockedByAcceptedTrade) {
            primaryLabel = '거래 진행 중';
            primaryBackground = AppColors.catalogChipBg;
            primaryOnPressed = null;
          } else {
            primaryLabel = '거래 할래요';
            primaryOnPressed = () =>
                _onTapTradeProposal(context, ref, currentOffer: currentOffer);
          }
          secondaryLabel = '닫기';
          secondaryOnPressed = () => Navigator.of(context).pop();
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPrimaryBottomButton(
          label: primaryLabel,
          onPressed: primaryOnPressed,
          backgroundColor: primaryBackground,
        ),
        const SizedBox(height: AppSpacing.s10),
        _buildSecondaryBottomButton(
          label: secondaryLabel,
          onPressed: secondaryOnPressed,
        ),
      ],
    );
  }

  Widget _buildOwnerBottomActions(
    BuildContext context,
    WidgetRef ref, {
    required MarketOffer currentOffer,
  }) {
    if (_isCompletedOfferByStatus(currentOffer)) {
      return const SizedBox.shrink();
    }

    final bool canCancelTrade =
        currentOffer.lifecycle == MarketLifecycleTab.ongoing &&
        !_isCancelledOffer(currentOffer);
    final proposalsAsync = ref.watch(marketTradeProposalsProvider(offer.id));
    final hasAcceptedProposal =
        proposalsAsync.valueOrNull?.any(
          (proposal) => proposal.status == MarketTradeProposalStatus.accepted,
        ) ??
        false;
    final canCompleteTrade = canCancelTrade && hasAcceptedProposal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPrimaryBottomButton(
          label: '거래 완료할게요!',
          onPressed: canCompleteTrade
              ? () => _completeMyOffer(context, ref)
              : null,
          backgroundColor: AppColors.accentDeepOrange,
        ),
        const SizedBox(height: AppSpacing.s10),
        _buildSecondaryBottomButton(
          label: canCancelTrade ? '거래 취소' : '거래 삭제',
          onPressed: canCancelTrade
              ? () => _cancelTradeAsOwner(context, ref)
              : () => _deleteMyOffer(context, ref),
        ),
      ],
    );
  }

  Widget _buildPrimaryBottomButton({
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        backgroundColor: backgroundColor,
        disabledBackgroundColor: AppColors.catalogChipBg,
        minimumSize: const Size.fromHeight(60),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        style: onPressed == null
            ? AppTextStyles.buttonSecondary
            : AppTextStyles.buttonPrimary,
      ),
    );
  }

  Widget _buildSecondaryBottomButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        overlayColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        backgroundColor: AppColors.bgCard.withValues(alpha: 0.96),
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        side: BorderSide(
          color: AppColors.borderDefault.withValues(alpha: 0.9),
          width: 1.6,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label, style: AppTextStyles.buttonOutline),
    );
  }

  Widget _buildMyProposalStatusSection(WidgetRef ref, String currentUid) {
    if (currentUid.trim().isEmpty) {
      return _buildInsetPanel(
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
      loading: () => _buildInsetPanel(
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.s10),
            Text('내 제안 상태를 확인하는 중...', style: AppTextStyles.captionMuted),
          ],
        ),
      ),
      error: (error, stackTrace) => _buildInsetPanel(
        child: Text('제안 상태를 불러오지 못했어요.', style: AppTextStyles.captionHint),
      ),
      data: (proposal) {
        if (proposal == null) {
          return _buildInsetPanel(
            child: Text(
              '아직 이 거래에 보낸 제안이 없어요.',
              style: AppTextStyles.captionMuted,
            ),
          );
        }
        return _buildInsetPanel(
          child: Row(
            children: <Widget>[
              _buildProposalStatusBadge(
                proposal.status,
                isOfferCompleted: _isCompletedOffer,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  '업데이트 ${formatRelativeTime(proposal.updatedAt)}',
                  style: AppTextStyles.captionMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOwnerProposalQueueSection(
    BuildContext context,
    WidgetRef ref, {
    required MarketOffer currentOffer,
  }) {
    final proposalsAsync = ref.watch(marketTradeProposalsProvider(offer.id));
    return proposalsAsync.when(
      loading: () => _buildInsetPanel(
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.s10),
            Text('거래 제안 목록을 불러오는 중...', style: AppTextStyles.captionMuted),
          ],
        ),
      ),
      error: (error, stackTrace) => _buildInsetPanel(
        child: Text('제안 목록을 불러오지 못했어요.', style: AppTextStyles.captionHint),
      ),
      data: (proposals) {
        if (proposals.isEmpty) {
          return _buildInsetPanel(
            child: Text('아직 받은 거래 제안이 없어요.', style: AppTextStyles.captionMuted),
          );
        }

        return _buildInsetPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '대기열 제안 ${proposals.length}건',
                style: AppTextStyles.bodySecondaryStrong,
              ),
              const SizedBox(height: AppSpacing.s10),
              ...proposals.asMap().entries.map((entry) {
                final index = entry.key;
                final proposal = entry.value;
                final canAccept =
                    !_isInactiveOffer(currentOffer) &&
                    proposal.status == MarketTradeProposalStatus.pending;
                final canOpenCode =
                    !_isInactiveOffer(currentOffer) &&
                    proposal.status == MarketTradeProposalStatus.accepted;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == proposals.length - 1 ? 0 : AppSpacing.s10,
                  ),
                  child: _buildInsetPanel(
                    backgroundColor: AppColors.bgSecondary,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        ClipOval(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: proposal.proposerAvatarUrl.trim().isEmpty
                                ? Image.asset(
                                    'assets/images/icon_raccoon_character.png',
                                    fit: BoxFit.cover,
                                  )
                                : _buildImage(proposal.proposerAvatarUrl),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s10),
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
                                style: AppTextStyles.bodyPrimaryHeavy.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s6),
                              Wrap(
                                spacing: AppSpacing.s6,
                                runSpacing: AppSpacing.s6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  _buildProposalStatusBadge(
                                    proposal.status,
                                    isOfferCompleted: _isCompletedOffer,
                                  ),
                                  Text(
                                    formatRelativeTime(proposal.updatedAt),
                                    style: AppTextStyles.captionMuted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s10),
                        if (canAccept)
                          FilledButton(
                            onPressed: () =>
                                _acceptProposal(context, ref, proposal),
                            style: FilledButton.styleFrom(
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: AppColors.accentDeepOrange,
                              minimumSize: const Size(80, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                            onPressed: () => _openTradeCodePage(
                              context,
                              ref,
                              currentOffer: currentOffer,
                            ),
                            style: OutlinedButton.styleFrom(
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: AppColors.bgSecondary,
                              minimumSize: const Size(84, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              side: BorderSide(
                                color: AppColors.borderStrong.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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

  Widget _buildProposalStatusBadge(
    MarketTradeProposalStatus status, {
    bool isOfferCompleted = false,
  }) {
    final bool isCompletedTarget =
        isOfferCompleted && status == MarketTradeProposalStatus.accepted;
    final String label = isCompletedTarget ? '거래 종료 된 상대' : status.label;
    Color bgColor = AppColors.catalogChipBg;
    Color textColor = AppColors.textMuted;
    if (isCompletedTarget) {
      bgColor = AppColors.catalogChipBg;
      textColor = AppColors.textMuted;
    } else {
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
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionWithColor(
          textColor,
          weight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTradeSummaryCard({bool embedded = false}) {
    if (offer.tradeType == MarketTradeType.touching) {
      return _buildTouchingTradeSummaryCard(embedded: embedded);
    }
    final Widget content = offer.oneWayOffer
        ? _buildSingleTradeSummaryContent(embedded: embedded)
        : Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildItemMiniCard(
                      header: offer.offerHeaderLabel,
                      defaultHeader: '드려요',
                      headerColor: AppColors.primaryDefault,
                      imageUrl: offer.offerItemImageUrl,
                      title: offer.offerItemName,
                      quantity: offer.offerItemQuantity,
                      categoryLabel: _resolveItemTypeLabel(isOfferSide: true),
                      imageSize: embedded ? 104 : 74,
                      imageBorderRadius: embedded ? 22 : 16,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _buildItemMiniCard(
                      header: offer.wantHeaderLabel,
                      defaultHeader: '받아요',
                      headerColor: AppColors.accentDeepOrange,
                      imageUrl: offer.wantItemImageUrl,
                      title: offer.wantItemName,
                      quantity: offer.wantItemQuantity,
                      categoryLabel: _resolveItemTypeLabel(isOfferSide: false),
                      imageSize: embedded ? 104 : 74,
                      imageBorderRadius: embedded ? 22 : 16,
                    ),
                  ),
                ],
              ),
              _buildTradeDirectionIndicator(),
            ],
          );
    if (embedded) {
      return content;
    }
    return _buildInsetPanel(child: content);
  }

  Widget _buildSingleTradeSummaryContent({bool embedded = false}) {
    return Center(
      child: _buildItemMiniCard(
        header: offer.offerHeaderLabel,
        defaultHeader: '나눔',
        headerColor: AppColors.primaryDefault,
        imageUrl: offer.offerItemImageUrl,
        title: offer.offerItemName,
        quantity: offer.offerItemQuantity,
        categoryLabel: _resolveItemTypeLabel(isOfferSide: true),
        imageSize: embedded ? 106 : 74,
        imageBorderRadius: embedded ? 22 : 16,
      ),
    );
  }

  Widget _buildTouchingTradeSummaryCard({bool embedded = false}) {
    final touchingTags = _resolveTouchingTags();
    final touchingCount = touchingTags.length;
    final Widget content = Column(
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildItemMiniCard(
                    header: '입장료',
                    defaultHeader: '입장료',
                    headerColor: AppColors.primaryDefault,
                    imageUrl: offer.offerItemImageUrl,
                    title: offer.offerItemName,
                    quantity: offer.offerItemQuantity,
                    categoryLabel: _resolveItemTypeLabel(isOfferSide: true),
                    imageSize: embedded ? 104 : 74,
                    imageBorderRadius: embedded ? 22 : 16,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: _buildItemMiniCard(
                    header: '만지작',
                    defaultHeader: '만지작',
                    headerColor: AppColors.badgePurpleText,
                    imageUrl: '',
                    title: touchingCount > 0 ? '만지작 $touchingCount개' : '만지작',
                    quantity: 0,
                    categoryLabel: '만지작',
                    emptyImageIcon: Icons.touch_app_rounded,
                    imageSize: embedded ? 104 : 74,
                    imageBorderRadius: embedded ? 22 : 16,
                  ),
                ),
              ],
            ),
            _buildTradeDirectionIndicator(),
          ],
        ),
        if (touchingTags.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          _buildInsetPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.unfold_less_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildFoldedTouchingSummaryText(touchingTags),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    if (embedded) {
      return content;
    }
    return _buildInsetPanel(child: content);
  }

  String _buildFoldedTouchingSummaryText(List<String> touchingTags) {
    if (touchingTags.isEmpty) {
      return '선택된 만지작 아이템이 없어요';
    }
    const previewLimit = 3;
    final preview = touchingTags.take(previewLimit).join(', ');
    final remainCount = touchingTags.length - previewLimit;
    if (remainCount <= 0) {
      return preview;
    }
    return '$preview 외 $remainCount개';
  }

  Widget _buildTradeDirectionIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.sync_alt_rounded,
        size: 28,
        color: AppColors.textAccent,
      ),
    );
  }

  List<String> _resolveTouchingTags() {
    return resolveTouchingTagLabels(offer.touchingTags);
  }

  Widget _buildItemMiniCard({
    required String header,
    required String defaultHeader,
    required Color headerColor,
    required String imageUrl,
    required String title,
    required int quantity,
    required String categoryLabel,
    IconData emptyImageIcon = Icons.image_not_supported_outlined,
    double imageSize = 74,
    double imageBorderRadius = 16,
  }) {
    final displayName = title.trim().isEmpty ? '-' : title.trim();
    final displayQuantity = quantity <= 0 ? 0 : quantity;
    final headerText = header.trim().isEmpty ? defaultHeader : header;
    return Column(
      children: <Widget>[
        Text(
          headerText,
          style: AppTextStyles.captionWithColor(
            headerColor,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(imageBorderRadius),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: imageUrl.trim().isEmpty
              ? Icon(emptyImageIcon, color: AppColors.textHint, size: 30)
              : _buildImage(imageUrl),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyPrimaryHeavy.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.s8),
        _buildItemTypeBadge(categoryLabel),
        if (displayQuantity > 1) ...<Widget>[
          const SizedBox(height: AppSpacing.s4),
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
        bgColor = AppColors.marketBlueBadgeBg;
        textColor = AppColors.marketBlueBadgeText;
        icon = Icons.paid_rounded;
      case '레시피':
        bgColor = AppColors.badgeYellowBg;
        textColor = AppColors.badgeYellowText;
        icon = Icons.description_rounded;
      case '주민':
        bgColor = const Color(0xff9ee476).withValues(alpha: 0.3);
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

    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 60, minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 11, color: textColor),
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
      ),
    );
  }

  Widget _buildMoveTypePanel() {
    final isHost = offer.moveType == MarketMoveType.host;
    return _buildInsetPanel(
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
              isHost ? Icons.home_rounded : Icons.flight_takeoff_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              offer.moveType.label,
              style: AppTextStyles.bodyPrimaryHeavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorGuidePanel() {
    final description = offer.description.trim();
    if (description.isEmpty) {
      return _buildInsetPanel(
        child: Text('상세 안내가 없어요.', style: AppTextStyles.bodySecondaryStrong),
      );
    }
    return _buildInsetPanel(
      child: Text(
        description,
        style: AppTextStyles.labelWithColor(
          AppColors.textPrimary,
          weight: FontWeight.w700,
          height: 1.42,
        ),
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

  Future<void> _onTapTradeProposal(
    BuildContext context,
    WidgetRef ref, {
    required MarketOffer currentOffer,
  }) async {
    if (_isCompletedOfferByStatus(currentOffer)) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '완료된 거래에는 제안을 보낼 수 없어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final isOfferLockedByAcceptedTrade =
        currentOffer.status == MarketOfferStatus.waiting ||
        currentOffer.status == MarketOfferStatus.trading;
    if (isOfferLockedByAcceptedTrade) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '이미 다른 상대와 진행 중인 거래예요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

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
      final errorMessage =
          ref.read(marketViewModelProvider).errorMessage ??
          '거래 진행을 시작하지 못했어요. 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, errorMessage),
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
          content: _snackContent(context, '거래 제안을 보냈어요. 작성자 승낙을 기다려 주세요.'),
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
          SnackBar(
            content: _snackContent(context, '제안 승낙에 실패했어요. 다시 시도해 주세요.'),
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
          content: _snackContent(context, '선택한 제안을 승낙했어요. 거래 코드를 준비해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    if (shouldSendCode) {
      await Navigator.of(context).push(
        AppPageRoute<void>(
          screenName: AppScreenNames.marketTradeCodeSend,
          builder: (_) =>
              MarketTradeCodeSendPage(offer: offer, session: session),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      AppPageRoute<void>(
        screenName: AppScreenNames.marketTradeCodeView,
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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
    required MarketOffer currentOffer,
  }) async {
    if (!_canOpenSimpleMenu(isMine: isMine, currentOffer: currentOffer)) {
      return;
    }

    final isInactiveOffer = _isInactiveOffer(currentOffer);
    final canDeleteMineOffer =
        !isInactiveOffer &&
        currentOffer.status != MarketOfferStatus.waiting &&
        currentOffer.status != MarketOfferStatus.trading;
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
                if (canDeleteMineOffer)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text('삭제하기', style: AppTextStyles.bodyPrimaryStrong),
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
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text('숨기기', style: AppTextStyles.bodyPrimaryStrong),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _hideOffer(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text('이 유저 차단', style: AppTextStyles.bodyPrimaryStrong),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _blockOfferOwner(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text('신고하기', style: AppTextStyles.bodyPrimaryStrong),
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

  Future<void> _openTradeCodePage(
    BuildContext context,
    WidgetRef ref, {
    required MarketOffer currentOffer,
  }) async {
    if (_isInactiveOffer(currentOffer)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '취소/종료된 거래는 코드를 확인할 수 없어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final session = await viewModel.fetchTradeCodeSession(currentOffer.id);
    if (!context.mounted) {
      return;
    }
    if (session == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '아직 거래 코드가 생성되지 않았어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final currentUid = viewModel.currentUserId;
    final shouldSendCode = session.isCodeSender(currentUid) && !session.hasCode;
    await Navigator.of(context).push(
      AppPageRoute<void>(
        screenName: shouldSendCode
            ? AppScreenNames.marketTradeCodeSend
            : AppScreenNames.marketTradeCodeView,
        builder: (_) => shouldSendCode
            ? MarketTradeCodeSendPage(offer: currentOffer, session: session)
            : MarketTradeCodeViewPage(offer: currentOffer),
      ),
    );
  }

  Future<void> _reportOffer(BuildContext context, WidgetRef ref) async {
    final result = await MarketReportReasonPage.show(context);
    if (result == null || !context.mounted) {
      return;
    }
    final reason = result.reason;
    final detail = result.detail;
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .reportOffer(offer: offer, reason: reason, detail: detail);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final errorCode = _stateErrorCode(error);
      if (errorCode == MarketReportConstants.duplicateReportErrorCode) {
        await MarketReportResultDialogs.showDuplicate(context);
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '신고 접수에 실패했어요. 다시 시도해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (!context.mounted) {
      return;
    }
    await MarketReportResultDialogs.showSubmitted(context);
  }

  String? _stateErrorCode(Object error) {
    if (error is StateError) {
      return error.message;
    }
    final fallbackMessage = error.toString();
    if (fallbackMessage.contains(
      MarketReportConstants.duplicateReportErrorCode,
    )) {
      return MarketReportConstants.duplicateReportErrorCode;
    }
    return null;
  }

  Text _snackContent(BuildContext _, String message) {
    return Text(message);
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
          SnackBar(
            content: _snackContent(context, '거래 글 숨기기에 실패했어요. 다시 시도해 주세요.'),
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
          content: _snackContent(context, '거래 글을 숨겼어요. 목록에서 제외됩니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    Navigator.of(context).pop();
  }

  Future<void> _blockOfferOwner(BuildContext context, WidgetRef ref) async {
    final shouldBlock = await _showBlockUserConfirmDialog(context);
    if (shouldBlock != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .blockUserForMe(blockedUid: offer.ownerUid);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '유저 차단에 실패했어요. 다시 시도해 주세요.'),
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
          content: _snackContent(context, '해당 유저를 차단했어요. 서로의 게시물/요청이 숨겨집니다.'),
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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

  Future<bool?> _showBlockUserConfirmDialog(BuildContext context) {
    const dialogButtonHeight = 54.0;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('유저 차단', style: AppTextStyles.dialogTitleCompact),
                const SizedBox(height: 10),
                Text(
                  '해당 유저를 차단하면 서로의 게시물과 방문 요청이 보이지 않아요.',
                  style: AppTextStyles.dialogBodyCompact,
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
                          minimumSize: const Size.fromHeight(
                            dialogButtonHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '차단',
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

  Future<void> _completeMyOffer(BuildContext context, WidgetRef ref) async {
    final shouldComplete = await _showCompleteConfirmDialog(context);
    if (shouldComplete != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .completeTrade(offer: offer);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      final errorMessage =
          ref.read(marketViewModelProvider).errorMessage ??
          '거래 완료에 실패했어요. 다시 시도해 주세요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, errorMessage),
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
          content: _snackContent(context, '거래를 완료로 변경했어요.'),
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
          SnackBar(
            content: _snackContent(context, '거래 취소에 실패했어요. 다시 시도해 주세요.'),
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
          content: _snackContent(
            context,
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
          SnackBar(
            content: _snackContent(context, '거래 취소에 실패했어요. 다시 시도해 주세요.'),
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
          content: _snackContent(context, '진행 중인 거래를 취소했어요.'),
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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
    if (_isCompletedOffer) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: _snackContent(context, '완료된 거래는 삭제할 수 없어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

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
        SnackBar(
          content: _snackContent(context, '거래 글을 삭제했어요.'),
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
          surfaceTintColor: AppColors.transparent,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
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
                          overlayColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          backgroundColor: AppColors.modalPrimaryAction,
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
