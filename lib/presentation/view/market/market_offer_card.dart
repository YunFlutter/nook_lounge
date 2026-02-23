import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/utils/relative_time_formatter.dart';
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

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: offer.dimmed ? 0.42 : 1,
      child: Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
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
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                      style: AppTextStyles.bodyPrimaryHeavy,
                    ),
                    const SizedBox(height: 2),
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
    return Column(
      children: <Widget>[
        if (offer.isMine)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              alignment: Alignment.center,
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
        const SizedBox(height: 6),
        Text(
          offer.offerHeaderLabel,
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
        const SizedBox(height: 4),
        _buildItemTypeBadge(_resolveItemTypeLabel(isOfferSide: true)),
        const SizedBox(height: 4),
        Text(
          'X${offer.offerItemQuantity}',
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
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
        const SizedBox(height: 4),
        _buildItemTypeBadge(categoryLabel),
        const SizedBox(height: 4),
        Text('X$quantity', style: AppTextStyles.bodyPrimaryHeavy),
      ],
    );
  }

  Widget _buildTouchingBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                    Text(
                      offer.ownerName,
                      style: AppTextStyles.bodyPrimaryHeavy,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRelativeTime(offer.createdAt),
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: offer.touchingTags
                .map(
                  (tag) => Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _touchingTagColor(tag),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionInverseHeavy,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text('입장료', style: AppTextStyles.captionMuted),
              const SizedBox(width: 6),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
              const Spacer(),
              _buildActionArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final Color bgColor;
    final Color textColor;
    switch (offer.status) {
      case MarketOfferStatus.open:
        bgColor = AppColors.catalogSuccessBg;
        textColor = AppColors.catalogSuccessText;
      case MarketOfferStatus.waiting:
        bgColor = AppColors.badgeRedBg;
        textColor = AppColors.badgeRedText;
      case MarketOfferStatus.closed:
      case MarketOfferStatus.offline:
      case MarketOfferStatus.trading:
        bgColor = AppColors.catalogChipBg;
        textColor = AppColors.textMuted;
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        offer.statusLabel,
        textAlign: TextAlign.center,
        style: AppTextStyles.chip(textColor),
      ),
    );
  }

  Widget _buildActionArea() {
    if (!offer.isMine) {
      return _buildActionChip();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildOwnerActionChip(label: '수정', onTap: onEditTap),
        const SizedBox(width: 4),
        _buildOwnerActionChip(label: '삭제', onTap: onDeleteTap),
        const SizedBox(width: 4),
        _buildOwnerActionChip(label: '완료', onTap: onCompleteTap),
      ],
    );
  }

  Widget _buildActionChip() {
    final bool disabled =
        offer.status == MarketOfferStatus.closed ||
        offer.status == MarketOfferStatus.offline ||
        offer.status == MarketOfferStatus.trading ||
        offer.dimmed;
    final Color bgColor = disabled
        ? AppColors.catalogChipBg
        : AppColors.badgeBlueText;
    final Color textColor = disabled ? AppColors.textMuted : AppColors.white;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : onActionTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            _resolveActionLabel(),
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
    final bool disabled = onTap == null || offer.dimmed;
    final Color bgColor = disabled
        ? AppColors.catalogChipBg
        : AppColors.badgeBlueBg;
    final Color textColor = disabled
        ? AppColors.textMuted
        : AppColors.badgeBlueText;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
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

  Color _touchingTagColor(String tag) {
    if (tag.contains('가구')) {
      return AppColors.marketTouchFurniture;
    }
    if (tag.contains('벽지')) {
      return AppColors.marketTouchWallpaper;
    }
    if (tag.contains('바닥')) {
      return AppColors.marketTouchFlooring;
    }
    if (tag.contains('음악')) {
      return AppColors.marketTouchMusic;
    }
    if (tag.contains('패션')) {
      return AppColors.marketTouchFashion;
    }
    return AppColors.badgeBlueText;
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
