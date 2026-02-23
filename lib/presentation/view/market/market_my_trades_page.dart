import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_register_page.dart';

class MarketMyTradesPage extends ConsumerWidget {
  const MarketMyTradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketViewModelProvider);
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final offers = viewModel.myOffers;

    return Scaffold(
      appBar: AppBar(title: const Text('내 거래관리')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          AppSpacing.pageHorizontal,
        ),
        children: <Widget>[
          AnimatedFadeSlide(
            child: _buildLifecycleTabs(
              selected: state.selectedLifecycle,
              counts: _buildCounts(state.offers),
              onSelect: viewModel.setLifecycle,
            ),
          ),
          const SizedBox(height: 12),
          if (offers.isEmpty)
            _buildEmpty()
          else
            ...offers.asMap().entries.map((entry) {
              final index = entry.key;
              final offer = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == offers.length - 1 ? 0 : 10,
                ),
                child: AnimatedFadeSlide(
                  delay: Duration(milliseconds: 30 + (index * 24)),
                  child: _buildTradeCard(context, ref, offer),
                ),
              );
            }),
        ],
      ),
    );
  }

  Map<MarketLifecycleTab, int> _buildCounts(List<MarketOffer> offers) {
    final counts = <MarketLifecycleTab, int>{
      MarketLifecycleTab.ongoing: 0,
      MarketLifecycleTab.cancelled: 0,
      MarketLifecycleTab.completed: 0,
    };
    for (final offer in offers) {
      if (!offer.isMine) {
        continue;
      }
      counts[offer.lifecycle] = (counts[offer.lifecycle] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildLifecycleTabs({
    required MarketLifecycleTab selected,
    required Map<MarketLifecycleTab, int> counts,
    required ValueChanged<MarketLifecycleTab> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: MarketLifecycleTab.values
            .map((tab) {
              final selectedTab = tab == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedTab
                          ? AppColors.bgCard
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: selectedTab
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.shadowSoft,
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '${tab.label}(${counts[tab] ?? 0})',
                      style: AppTextStyles.labelWithColor(
                        selectedTab
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTradeCard(
    BuildContext context,
    WidgetRef ref,
    MarketOffer offer,
  ) {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final offerDisplayName = _resolvedDisplayName(
      offer.offerItemName,
      offer.offerItemQuantity,
    );
    final offerDisplayQuantity = _resolvedDisplayQuantity(
      offer.offerItemName,
      offer.offerItemQuantity,
    );
    final wantDisplayName = _resolvedDisplayName(
      offer.wantItemName,
      offer.wantItemQuantity,
    );
    final wantDisplayQuantity = _resolvedDisplayQuantity(
      offer.wantItemName,
      offer.wantItemQuantity,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        '나',
                        style: AppTextStyles.bodySecondaryStrong,
                      ),
                      const SizedBox(height: 8),
                      _buildSquareItemImage(offer.offerItemImageUrl),
                      const SizedBox(height: 6),
                      Text(
                        offerDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyPrimaryHeavy,
                      ),
                      if (offerDisplayQuantity > 0)
                        Text(
                          'X$offerDisplayQuantity',
                          style: AppTextStyles.bodyPrimaryHeavy,
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textAccent,
                      ),
                      Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textAccent,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        '상대',
                        style: AppTextStyles.bodySecondaryStrong,
                      ),
                      const SizedBox(height: 8),
                      _buildSquareItemImage(offer.wantItemImageUrl),
                      const SizedBox(height: 6),
                      Text(
                        wantDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyPrimaryHeavy,
                      ),
                      if (wantDisplayQuantity > 0)
                        Text(
                          'X$wantDisplayQuantity',
                          style: AppTextStyles.bodyPrimaryHeavy,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDefault),
          if (offer.lifecycle == MarketLifecycleTab.ongoing)
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildBottomAction(
                    icon: Icons.edit_rounded,
                    label: '수정',
                    onTap: () => _openEditForm(context, offer),
                  ),
                ),
                Expanded(
                  child: _buildBottomAction(
                    icon: Icons.schedule_rounded,
                    label: '거래취소',
                    onTap: () async {
                      final shouldCancel = await _showConfirmDialog(
                        context: context,
                        title: '거래 취소',
                        message: '이 거래를 취소 상태로 변경할까요?',
                        confirmLabel: '취소',
                      );
                      if (shouldCancel != true) {
                        return;
                      }
                      await viewModel.setOfferLifecycle(
                        offerId: offer.id,
                        lifecycle: MarketLifecycleTab.cancelled,
                      );
                      if (context.mounted) {
                        _showInfo(context, '거래를 취소로 변경했어요.');
                      }
                    },
                  ),
                ),
                Expanded(
                  child: _buildBottomAction(
                    icon: Icons.check_circle_rounded,
                    label: '완료',
                    onTap: () async {
                      final shouldComplete = await _showConfirmDialog(
                        context: context,
                        title: '거래 완료 처리',
                        message: '이 거래를 완료 상태로 변경할까요?',
                        confirmLabel: '완료',
                      );
                      if (shouldComplete != true) {
                        return;
                      }
                      await viewModel.setOfferLifecycle(
                        offerId: offer.id,
                        lifecycle: MarketLifecycleTab.completed,
                        status: MarketOfferStatus.closed,
                      );
                      if (context.mounted) {
                        _showInfo(context, '거래를 완료로 변경했어요.');
                      }
                    },
                  ),
                ),
              ],
            )
          else
            _buildBottomAction(
              icon: Icons.delete_outline_rounded,
              label: '삭제',
              onTap: () async {
                final shouldDelete = await _showConfirmDialog(
                  context: context,
                  title: '거래 글 삭제',
                  message: '정말 이 거래 글을 삭제할까요?',
                  confirmLabel: '삭제',
                );
                if (shouldDelete != true) {
                  return;
                }
                await viewModel.deleteOffer(offer.id);
                if (context.mounted) {
                  _showInfo(context, '거래 글을 삭제했어요.');
                }
              },
              expand: false,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool expand = true,
  }) {
    final button = InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: expand
                ? const BorderSide(color: AppColors.borderDefault)
                : BorderSide.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: AppColors.textMuted, size: 18),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.captionMuted,
            ),
          ],
        ),
      ),
    );

    if (!expand) {
      return button;
    }
    return button;
  }

  Widget _buildSquareItemImage(String source) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(7),
      child: source.isEmpty
          ? const SizedBox.shrink()
          : (source.startsWith('http://') || source.startsWith('https://'))
          ? Image.network(
              source,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image_rounded,
                color: AppColors.textHint,
              ),
            )
          : Image.asset(
              source,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textHint,
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: 240,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(
        '해당 탭의 거래가 없어요.',
        style: AppTextStyles.bodySecondaryStrong,
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    const dialogButtonHeight = 54.0;
    final isDestructive = confirmLabel == '삭제';

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
                Text(
                  title,
                  style: AppTextStyles.dialogTitleWithSize(30),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.dialogBodyWithSize(18),
                ),
                if (isDestructive) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '삭제 후에는 복구할 수 없어요.',
                    style: AppTextStyles.dialogDanger,
                  ),
                ],
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
                          style: AppTextStyles.buttonOutline,
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
                          confirmLabel,
                          style: AppTextStyles.buttonPrimary,
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

  Future<void> _openEditForm(BuildContext context, MarketOffer offer) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MarketTradeRegisterPage(initialOffer: offer),
      ),
    );
    if (updated == true && context.mounted) {
      _showInfo(context, '거래 글을 수정했어요.');
    }
  }
}
