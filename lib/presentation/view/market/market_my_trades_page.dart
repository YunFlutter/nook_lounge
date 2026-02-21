import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';

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
                      style: TextStyle(
                        color: selectedTab
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
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
                      const Text(
                        '나',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSquareItemImage(offer.offerItemImageUrl),
                      const SizedBox(height: 6),
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
                      const Text(
                        '상대',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSquareItemImage(offer.wantItemImageUrl),
                      const SizedBox(height: 6),
                      Text(
                        offer.wantItemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'X${offer.wantItemQuantity}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
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
                    onTap: () => _showInfo(context, '수정 화면은 다음 단계에서 연결됩니다.'),
                  ),
                ),
                Expanded(
                  child: _buildBottomAction(
                    icon: Icons.schedule_rounded,
                    label: '거래취소',
                    onTap: () async {
                      await viewModel.setOfferLifecycle(
                        offerId: offer.id,
                        lifecycle: MarketLifecycleTab.cancelled,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildBottomAction(
                    icon: Icons.check_circle_rounded,
                    label: '완료',
                    onTap: () async {
                      await viewModel.setOfferLifecycle(
                        offerId: offer.id,
                        lifecycle: MarketLifecycleTab.completed,
                      );
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
                await viewModel.deleteOffer(offer.id);
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
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
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
      child: const Text(
        '해당 탭의 거래가 없어요.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
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
}
