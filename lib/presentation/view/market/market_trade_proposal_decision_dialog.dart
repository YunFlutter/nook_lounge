import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

enum MarketTradeProposalDecisionDialogPerspective { proposer, owner }

Future<bool?> showMarketTradeProposalDecisionDialog(
  BuildContext context, {
  required MarketOffer offer,
  required String participantLabel,
  required String participantName,
  required String badgeLabel,
  required String primaryLabel,
  required String secondaryLabel,
  required MarketTradeProposalDecisionDialogPerspective perspective,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => MarketTradeProposalDecisionDialog(
      offer: offer,
      participantLabel: participantLabel,
      participantName: participantName,
      badgeLabel: badgeLabel,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      perspective: perspective,
    ),
  );
}

class MarketTradeProposalDecisionDialog extends StatelessWidget {
  const MarketTradeProposalDecisionDialog({
    required this.offer,
    required this.participantLabel,
    required this.participantName,
    required this.badgeLabel,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.perspective,
    super.key,
  });

  static const double _dialogCornerRadius = 30;
  static const double _buttonCornerRadius = 30;
  static const double _summaryCardSize = 84;
  static const double _summaryImageSize = 73;

  final MarketOffer offer;
  final String participantLabel;
  final String participantName;
  final String badgeLabel;
  final String primaryLabel;
  final String secondaryLabel;
  final MarketTradeProposalDecisionDialogPerspective perspective;

  bool get _isProposerPerspective {
    return perspective == MarketTradeProposalDecisionDialogPerspective.proposer;
  }

  @override
  Widget build(BuildContext context) {
    final giveItem = _resolveGiveItem();
    final receiveItem = _resolveReceiveItem();

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_dialogCornerRadius),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 18),
              _buildTradeSummary(giveItem: giveItem, receiveItem: receiveItem),
              const SizedBox(height: 18),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayParticipantName = participantName.trim().isEmpty
        ? '거래 상대'
        : participantName.trim();

    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderDefault, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentDeepOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                badgeLabel,
                style: AppTextStyles.captionWithColor(
                  AppColors.navInactive,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '거래 제안서',
          style: AppTextStyles.bodyWithSize(
            24,
            color: AppColors.textSecondary,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Column(
          children: <Widget>[
            Text(
              participantLabel,
              style: AppTextStyles.captionWithColor(
                AppColors.textMuted,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              displayParticipantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyWithSize(
                16,
                color: AppColors.navInactive,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTradeSummary({
    required ({
      String title,
      String imageUrl,
      int quantity,
      IconData fallbackIcon,
    })
    giveItem,
    required ({
      String title,
      String imageUrl,
      int quantity,
      IconData fallbackIcon,
    })
    receiveItem,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildSummaryItemCard(
              header: '드려요',
              headerColor: AppColors.accentDeepOrange,
              title: giveItem.title,
              imageUrl: giveItem.imageUrl,
              quantity: giveItem.quantity,
              fallbackIcon: giveItem.fallbackIcon,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.sync_alt_rounded,
              size: 30,
              color: AppColors.textAccent,
            ),
          ),
          Expanded(
            child: _buildSummaryItemCard(
              header: '받아요',
              headerColor: AppColors.primaryHover,
              title: receiveItem.title,
              imageUrl: receiveItem.imageUrl,
              quantity: receiveItem.quantity,
              fallbackIcon: receiveItem.fallbackIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItemCard({
    required String header,
    required Color headerColor,
    required String title,
    required String imageUrl,
    required int quantity,
    required IconData fallbackIcon,
  }) {
    final displayTitle = title.trim().isEmpty ? '아이템 정보 없음' : title.trim();
    final displayQuantity = quantity > 1 ? 'X$quantity' : '';

    return Column(
      children: <Widget>[
        Text(
          header,
          style: AppTextStyles.captionWithColor(
            headerColor,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _summaryCardSize,
          height: _summaryCardSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: _summaryCardSize,
                height: _summaryCardSize,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: _summaryImageSize,
                  height: _summaryImageSize,
                  color: AppColors.bgCard,
                  alignment: Alignment.center,
                  child: _buildImage(imageUrl, fallbackIcon),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 94,
          height: 36,
          child: Text(
            displayQuantity.isEmpty
                ? displayTitle
                : '$displayTitle\n$displayQuantity',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionWithColor(
              AppColors.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              backgroundColor: AppColors.modalPrimaryAction,
              shadowColor: AppColors.shadowMedium,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_buttonCornerRadius),
              ),
            ),
            child: Text(
              primaryLabel,
              style: AppTextStyles.bodyWithSize(
                18,
                color: AppColors.textInverse,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              backgroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.borderDefault, width: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_buttonCornerRadius),
              ),
            ),
            child: Text(
              secondaryLabel,
              style: AppTextStyles.bodyWithSize(
                18,
                color: AppColors.textMuted,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _resolveGiveItem() {
    if (offer.tradeType == MarketTradeType.touching) {
      return _isProposerPerspective ? _entryFeeItem() : _touchingItem();
    }
    if (offer.oneWayOffer) {
      return _isProposerPerspective ? _emptyCounterItem() : _offerItem();
    }
    return _isProposerPerspective ? _wantItem() : _offerItem();
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _resolveReceiveItem() {
    if (offer.tradeType == MarketTradeType.touching) {
      return _isProposerPerspective ? _touchingItem() : _entryFeeItem();
    }
    if (offer.oneWayOffer) {
      return _isProposerPerspective ? _offerItem() : _emptyCounterItem();
    }
    return _isProposerPerspective ? _offerItem() : _wantItem();
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _offerItem() {
    return (
      title: offer.offerItemName,
      imageUrl: offer.offerItemImageUrl,
      quantity: offer.offerItemQuantity,
      fallbackIcon: Icons.inventory_2_rounded,
    );
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _wantItem() {
    return (
      title: offer.wantItemName,
      imageUrl: offer.wantItemImageUrl,
      quantity: offer.wantItemQuantity,
      fallbackIcon: Icons.inventory_2_rounded,
    );
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _entryFeeItem() {
    return (
      title: offer.offerItemName.trim().isEmpty
          ? '입장료 없음'
          : offer.offerItemName,
      imageUrl: offer.offerItemImageUrl,
      quantity: offer.offerItemQuantity,
      fallbackIcon: Icons.paid_rounded,
    );
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _touchingItem() {
    final touchingCount = offer.touchingTags.length;
    final touchingTitle = touchingCount <= 0 ? '만지작' : '만지작 $touchingCount개';
    return (
      title: touchingTitle,
      imageUrl: '',
      quantity: 0,
      fallbackIcon: Icons.touch_app_rounded,
    );
  }

  ({String title, String imageUrl, int quantity, IconData fallbackIcon})
  _emptyCounterItem() {
    return (
      title: '대가 없음',
      imageUrl: '',
      quantity: 0,
      fallbackIcon: Icons.card_giftcard_rounded,
    );
  }

  Widget _buildImage(String source, IconData fallbackIcon) {
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty) {
      return Icon(fallbackIcon, color: AppColors.textHint, size: 32);
    }
    if (normalizedSource.startsWith('http://') ||
        normalizedSource.startsWith('https://')) {
      return Image.network(
        normalizedSource,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: AppColors.textHint, size: 32);
        },
      );
    }
    if (normalizedSource.startsWith('/')) {
      return Image.file(
        File(normalizedSource),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, color: AppColors.textHint, size: 32);
        },
      );
    }
    return Image.asset(
      normalizedSource,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: AppColors.textHint, size: 32);
      },
    );
  }
}
