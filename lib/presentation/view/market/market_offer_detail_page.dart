import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_appBarTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showSimpleMenu(context, ref),
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
          child: offer.isMine
              ? _buildOwnerBottomActions(context, ref)
              : _buildVisitorBottomActions(context),
        ),
      ),
    );
  }

  Widget _buildVisitorBottomActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton(
          onPressed: () => _showProposalFlow(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentDeepOrange,
            minimumSize: const Size.fromHeight(58),
          ),
          child: Text('거래를 제안할게요!', style: AppTextStyles.buttonPrimary),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.borderDefault, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text('거래 취소', style: AppTextStyles.buttonSecondary),
        ),
      ],
    );
  }

  Widget _buildOwnerBottomActions(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FilledButton(
          onPressed: () => _completeMyOffer(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentDeepOrange,
            minimumSize: const Size.fromHeight(58),
          ),
          child: Text('거래 완료할게요!', style: AppTextStyles.buttonPrimary),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _deleteMyOffer(context, ref),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppColors.borderDefault, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text('거래 삭제', style: AppTextStyles.buttonSecondary),
        ),
      ],
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

  Future<void> _showProposalFlow(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catalogChipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '거래 진행중',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Text('거래 제안서', style: AppTextStyles.headingH2),
                const SizedBox(height: 8),
                Text('구매자', style: AppTextStyles.captionMuted),
                Text('OOO', style: AppTextStyles.bodySecondaryStrong),
                const SizedBox(height: 16),
                _buildTradeSummaryCard(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _showResultDialog(context, accepted: false);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.badgeBlueText,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text('거래를 제안할게요!', style: AppTextStyles.buttonPrimary),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(
                      color: AppColors.borderDefault,
                      width: 2,
                    ),
                  ),
                  child: Text('거래 취소', style: AppTextStyles.buttonSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResultDialog(
    BuildContext context, {
    required bool accepted,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (accepted)
                  Text('OOO님이 거래를 수락했어요!', style: AppTextStyles.captionMuted),
                Text(
                  'OOO님에게 초대장과\n도도 코드를 보냈습니다!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelWithColor(
                    AppColors.textSecondary,
                    weight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text('비행장에서 기다려 주세요.', style: AppTextStyles.captionMuted),
                const SizedBox(height: 10),
                const Icon(
                  Icons.navigation_rounded,
                  color: AppColors.navActive,
                  size: 26,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.badgeBlueText,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text('확인', style: AppTextStyles.buttonPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSimpleMenu(BuildContext context, WidgetRef ref) async {
    if (offer.isMine) {
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
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('숨기기'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('신고하기'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 6),
            ],
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
    await ref
        .read(marketViewModelProvider.notifier)
        .setOfferLifecycle(
          offerId: offer.id,
          lifecycle: MarketLifecycleTab.completed,
          status: MarketOfferStatus.closed,
        );
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
                Text('거래 완료 처리', style: AppTextStyles.dialogTitleWithSize(30)),
                const SizedBox(height: 10),
                Text(
                  '이 거래를 완료 상태로 변경할까요?',
                  style: AppTextStyles.dialogBodyWithSize(18),
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
                        child: Text('취소', style: AppTextStyles.buttonOutline),
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
                        child: Text('완료', style: AppTextStyles.buttonPrimary),
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
                Text('거래 글 삭제', style: AppTextStyles.dialogTitleWithSize(30)),
                const SizedBox(height: 10),
                Text(
                  '정말 이 거래 글을 삭제할까요?',
                  style: AppTextStyles.dialogBodyWithSize(18),
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
                        child: Text('취소', style: AppTextStyles.buttonOutline),
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
                        child: Text('삭제', style: AppTextStyles.buttonPrimary),
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
