import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketOfferCard extends StatelessWidget {
  const MarketOfferCard({
    required this.offer,
    required this.onTap,
    required this.onActionTap,
    super.key,
  });

  final MarketOffer offer;
  final VoidCallback onTap;
  final VoidCallback onActionTap;

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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.createdAtLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionChip(),
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
              child: const Text(
                '나눔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.catalogSuccessText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          offer.offerHeaderLabel,
          style: const TextStyle(
            color: AppColors.primaryDefault,
            fontWeight: FontWeight.w800,
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
          child: _buildImage(offer.offerItemImageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Text(
          offer.offerItemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'X${offer.offerItemQuantity}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
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
  }) {
    return Column(
      children: <Widget>[
        Text(
          header,
          style: TextStyle(color: headerColor, fontWeight: FontWeight.w800),
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'X$quantity',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.createdAtLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
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
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                '입장료',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  style: const TextStyle(
                    color: AppColors.badgeYellowText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              _buildActionChip(),
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
        style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
      ),
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
            offer.actionLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
          ),
        ),
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
}
