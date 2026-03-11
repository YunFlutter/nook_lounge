import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
import 'package:nook_lounge_app/core/utils/touching_item_tag_codec.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketOfferCard extends StatelessWidget {
  const MarketOfferCard({
    required this.offer,
    required this.onTap,
    required this.onActionTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onCompleteTap,
    super.key,
  });

  final MarketOffer offer;
  final VoidCallback onTap;
  final VoidCallback onActionTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onCompleteTap;

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  static const int _touchingPreviewMaxSlots = 4;
  static const double _touchingPreviewCircleSize = 70;
  static const double _touchingPreviewItemGap = 18;
  static const double _touchingPreviewLabelGap = 8;

  @override
  Widget build(BuildContext context) {
    final isCompletedStyle = _isCompletedOffer;
    final card = Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(22),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: offer.boardType == MarketBoardType.touching
              ? _buildTouchingBody(context)
              : _buildExchangeBody(context),
        ),
      ),
    );

    return Opacity(
      opacity: offer.dimmed ? 0.42 : (isCompletedStyle ? 0.74 : 1),
      child: isCompletedStyle
          ? ColorFiltered(
              colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
              child: card,
            )
          : card,
    );
  }

  bool get _isCompletedOffer {
    return offer.lifecycle == MarketLifecycleTab.completed ||
        offer.status == MarketOfferStatus.closed;
  }

  Widget _buildExchangeBody(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: offer.oneWayOffer
              ? _buildSingleOfferTop(context)
              : _buildExchangeTop(context),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(21),
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.borderDefault.withValues(alpha: 0.6),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(
            children: <Widget>[
              ClipOval(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: _buildImage(offer.ownerAvatarUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyPrimaryHeavy.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      formatRelativeTime(offer.createdAt),
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionArea(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleOfferTop(BuildContext context) {
    final normalizedHeader = offer.offerHeaderLabel.trim();
    final headerLabel = normalizedHeader.isEmpty ? '나눔' : normalizedHeader;
    final showMineSharingBadge = offer.isMine && headerLabel != '나눔';

    return Column(
      children: <Widget>[
        if (showMineSharingBadge)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.catalogSuccessBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '나눔',
                textAlign: TextAlign.center,
                style: AppTextStyles.captionPrimaryHeavy,
              ),
            ),
          ),
        if (showMineSharingBadge) const SizedBox(height: 6),
        Text(
          headerLabel,
          style: AppTextStyles.captionWithColor(AppColors.primaryDefault),
        ),
        const SizedBox(height: 4),
        Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(8),
          child: _buildImage(offer.offerItemImageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Text(
          offer.offerItemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 10),
        _buildItemTypeBadge(_resolveItemTypeLabel(isOfferSide: true)),
        if (offer.offerItemQuantity > 1) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'X${offer.offerItemQuantity}',
            style: AppTextStyles.bodyPrimaryHeavy,
          ),
        ],
      ],
    );
  }

  Widget _buildExchangeTop(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildOfferColumn(
            header: offer.offerHeaderLabel,
            headerColor: AppColors.primaryDefault,
            imageUrl: offer.offerItemImageUrl,
            name: offer.offerItemName,
            quantity: offer.offerItemQuantity,
            categoryLabel: _resolveItemTypeLabel(isOfferSide: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: const <Widget>[
              Icon(Icons.arrow_forward_rounded, color: AppColors.textAccent),
              Icon(Icons.arrow_back_rounded, color: AppColors.textAccent),
            ],
          ),
        ),
        Expanded(
          child: _buildOfferColumn(
            header: offer.wantHeaderLabel,
            headerColor: AppColors.badgeRedText,
            imageUrl: offer.wantItemImageUrl,
            name: offer.wantItemName,
            quantity: offer.wantItemQuantity,
            categoryLabel: _resolveItemTypeLabel(isOfferSide: false),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferColumn({
    required String header,
    required Color headerColor,
    required String imageUrl,
    required String name,
    required int quantity,
    required String categoryLabel,
  }) {
    return Column(
      children: <Widget>[
        Text(
          header,
          style: AppTextStyles.captionWithColor(
            headerColor,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(8),
          child: _buildImage(imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 10),
        _buildItemTypeBadge(categoryLabel),
        if (quantity > 1) ...<Widget>[
          const SizedBox(height: 10),
          Text('X$quantity', style: AppTextStyles.bodyPrimaryHeavy),
        ],
      ],
    );
  }

  Widget _buildTouchingBody(BuildContext context) {
    final touchingItems = _touchingPreviewItems;
    final touchingTitle = _resolvedTouchingTitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipOval(
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: _buildImage(offer.ownerAvatarUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Text(
                    //   offer.ownerName,
                    //   style: AppTextStyles.bodyPrimaryHeavy,
                    // ),
                    Text(
                      touchingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyPrimaryHeavy.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatRelativeTime(offer.createdAt),
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (offer.description.isNotEmpty)
            Text(
              offer.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelWithColor(
                AppColors.textPrimary,
                weight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          if (touchingItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _buildTouchingPreviewRow(touchingItems),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Text('입장료', style: AppTextStyles.captionMuted),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.badgeYellowBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offer.entryFeeText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionWithColor(
                    AppColors.badgeYellowText,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(child: Container()),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionArea(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _resolvedTouchingTitle {
    final normalized = offer.title.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return '만지작 거래';
  }

  List<({String label, String imageUrl, String category})>
  get _touchingPreviewItems {
    // 유지보수 포인트:
    // 신규 데이터(인코딩된 선택 아이템)와 과거 데이터(문자열 태그)를
    // 모두 읽어서 리스트 카드 미리보기 포맷으로 정규화합니다.
    final items =
        <({String key, String label, String imageUrl, String category})>[];
    final seen = <String>{};
    for (final raw in offer.touchingTags) {
      final decoded = decodeTouchingItemTag(raw);
      if (decoded != null) {
        final key = decoded.id.isEmpty ? decoded.name : decoded.id;
        if (!seen.add(key)) {
          continue;
        }
        items.add((
          key: key,
          label: decoded.name,
          imageUrl: decoded.imageUrl,
          category: decoded.category,
        ));
        continue;
      }

      for (final token in raw.split(',')) {
        final value = token.trim();
        if (value.isNotEmpty) {
          final key = value;
          if (!seen.add(key)) {
            continue;
          }
          items.add((key: key, label: value, imageUrl: '', category: ''));
        }
      }
    }
    return items
        .map(
          (item) => (
            label: item.label,
            imageUrl: item.imageUrl,
            category: item.category,
          ),
        )
        .toList(growable: false);
  }

  Widget _buildTouchingPreviewRow(
    List<({String label, String imageUrl, String category})> items,
  ) {
    // 유지보수 포인트:
    // 리스트 카드에서는 태그 칩을 나열하지 않고 Figma 압축 카드(최대 4칸, 초과 시 +N)로 고정합니다.
    final hasOverflow = items.length > _touchingPreviewMaxSlots;
    final visibleItems = hasOverflow
        ? items.take(_touchingPreviewMaxSlots - 1).toList(growable: false)
        : items.take(_touchingPreviewMaxSlots).toList(growable: false);
    final tiles = <Widget>[
      for (final item in visibleItems)
        _buildTouchingPreviewItem(
          label: item.label,
          imageUrl: item.imageUrl,
          category: item.category,
        ),
      if (hasOverflow)
        _buildTouchingOverflowItem(
          overflowCount: items.length - visibleItems.length,
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var index = 0; index < tiles.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: _touchingPreviewItemGap),
            tiles[index],
          ],
        ],
      ),
    );
  }

  Widget _buildTouchingPreviewItem({
    required String label,
    required String imageUrl,
    required String category,
  }) {
    return SizedBox(
      width: _touchingPreviewCircleSize,
      child: Column(
        children: <Widget>[
          Container(
            width: _touchingPreviewCircleSize,
            height: _touchingPreviewCircleSize,
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: _buildTouchingPreviewCircleContent(
              label: label,
              imageUrl: imageUrl,
              category: category,
            ),
          ),
          const SizedBox(height: _touchingPreviewLabelGap),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              AppColors.textMuted,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchingOverflowItem({required int overflowCount}) {
    final overflowText = overflowCount > 99 ? '+99' : '+$overflowCount';
    return SizedBox(
      width: _touchingPreviewCircleSize,
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: _touchingPreviewCircleSize,
                height: _touchingPreviewCircleSize,
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 34,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: _touchingPreviewCircleSize,
                height: _touchingPreviewCircleSize,
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  overflowText,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionInverseHeavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: _touchingPreviewLabelGap),
          Text(
            '더보기',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              AppColors.textMuted,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchingPreviewCircleContent({
    required String label,
    required String imageUrl,
    required String category,
  }) {
    if (imageUrl.isNotEmpty) {
      return ClipOval(child: _buildImage(imageUrl, fit: BoxFit.cover));
    }
    return Icon(
      _touchingPreviewIcon(label: label, category: category),
      size: 34,
      color: AppColors.textPrimary,
    );
  }

  IconData _touchingPreviewIcon({
    required String label,
    required String category,
  }) {
    final source = category.isEmpty ? label : '$category $label';
    if (source.contains('가구')) {
      return Icons.chair_rounded;
    }
    if (source.contains('벽지') || source.contains('천장')) {
      return Icons.wallpaper_rounded;
    }
    if (source.contains('바닥') || source.contains('러그')) {
      return Icons.grid_view_rounded;
    }
    if (source.contains('음악') || source.contains('음향')) {
      return Icons.music_note_rounded;
    }
    if (source.contains('패션') || source.contains('의상')) {
      return Icons.checkroom_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  Widget _buildActionArea() {
    // 유지보수 포인트:
    // 완료된 거래는 소유자 액션(수정/삭제/완료)을 표시하지 않습니다.
    if (_isCompletedOffer && offer.isMine) {
      return const SizedBox.shrink();
    }

    if (!offer.isMine) {
      return _buildActionChip();
    }
    final canDeleteMineOffer =
        offer.status != MarketOfferStatus.waiting &&
        offer.status != MarketOfferStatus.trading;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        _buildOwnerActionChip(label: '수정', onTap: onEditTap),
        if (canDeleteMineOffer)
          _buildOwnerActionChip(label: '삭제', onTap: onDeleteTap),
        _buildOwnerActionChip(label: '완료', onTap: onCompleteTap),
      ],
    );
  }

  Widget _buildActionChip() {
    final actionLabel = _resolveActionLabel();
    final isProposalAction = actionLabel == '거래제안';
    final isQueueAction = actionLabel == '줄서기';
    final bool disabled =
        _isCompletedOffer ||
        offer.status == MarketOfferStatus.closed ||
        offer.status == MarketOfferStatus.offline ||
        offer.status == MarketOfferStatus.trading ||
        offer.dimmed;
    final Color enabledBgColor = isProposalAction
        ? AppColors.marketProposalBadgeBg
        : isQueueAction
        ? AppColors.marketQueueBadgeBg
        : AppColors.badgeBlueText;
    final Color enabledTextColor = isProposalAction
        ? AppColors.marketProposalBadgeText
        : AppColors.white;
    final Color bgColor = disabled ? AppColors.catalogChipBg : enabledBgColor;
    final Color textColor = disabled ? AppColors.textMuted : enabledTextColor;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : onActionTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            actionLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.chip(textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerActionChip({
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool isEditChip = label == '수정';
    final bool isDeleteChip = label == '삭제';
    final bool isCompleteChip = label == '완료';
    final bool disabled = onTap == null || offer.dimmed;
    final Color enabledBgColor = isEditChip
        ? AppColors.marketBlueBadgeBg
        : isDeleteChip
        ? AppColors.marketProposalBadgeBg
        : isCompleteChip
        ? AppColors.marketOwnerCompleteActionBg.withValues(alpha: 0.3)
        : AppColors.badgeBlueBg;
    final Color enabledTextColor = isEditChip
        ? AppColors.marketBlueBadgeText
        : isDeleteChip
        ? AppColors.marketProposalBadgeText
        : isCompleteChip
        ? AppColors.marketOwnerCompleteActionText
        : AppColors.badgeBlueText;
    final Color bgColor = disabled ? AppColors.catalogChipBg : enabledBgColor;
    final Color textColor = disabled ? AppColors.textMuted : enabledTextColor;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              textColor,
              weight: FontWeight.w800,
            ),
          ),
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
        bgColor = Color(0xff9ee476).withOpacity(0.3);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
            Text(
              normalized.isEmpty ? '아이템' : normalized,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildImage(String source, {required BoxFit fit}) {
    if (source.isEmpty) {
      return const SizedBox.shrink();
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
      );
    }
    return Image.asset(
      source,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textHint,
      ),
    );
  }

  String _resolveActionLabel() {
    if (offer.tradeType == MarketTradeType.touching) {
      return '줄서기';
    }
    return '거래제안';
  }
}
