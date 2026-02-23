import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/market/market_my_trades_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_card.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_register_page.dart';
import 'package:nook_lounge_app/presentation/viewmodel/market_view_model.dart';

class MarketTabPage extends ConsumerStatefulWidget {
  const MarketTabPage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<MarketTabPage> createState() => _MarketTabPageState();

  static Future<void> openMyTradesPage(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MarketMyTradesPage()));
  }
}

class _MarketTabPageState extends ConsumerState<MarketTabPage> {
  late final FocusNode _searchFocusNode;
  Timer? _relativeTimeTicker;
  bool _isSearchFocused = false;
  MarketFilterCategory _selectedCategory = MarketFilterCategory.all;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _relativeTimeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      // 유지보수 포인트:
      // 상대시간(몇 분 전)을 실시간 갱신하기 위해 최소 주기로 리빌드합니다.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _relativeTimeTicker?.cancel();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketViewModelProvider);
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final query = state.searchQuery.trim().toLowerCase();
    final offers = state.offers
        .where((offer) {
          if (_selectedCategory != MarketFilterCategory.all &&
              offer.category != _selectedCategory) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return offer.title.toLowerCase().contains(query) ||
              offer.ownerName.toLowerCase().contains(query) ||
              offer.offerItemName.toLowerCase().contains(query) ||
              offer.wantItemName.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Stack(
      children: <Widget>[
        RefreshIndicator(
          onRefresh: () async {
            // 유지보수 포인트:
            // 마켓은 Firestore 스트림 기반이라 강제 리프레시 없이도 최신 상태를 받습니다.
            // 당겨서 새로고침 UX를 유지하기 위해 짧은 지연만 둡니다.
            await Future<void>.delayed(const Duration(milliseconds: 320));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.s10,
              AppSpacing.pageHorizontal,
              98,
            ),
            children: <Widget>[
              AnimatedFadeSlide(
                child: _buildSearchField(
                  onChanged: viewModel.setSearchQuery,
                  focusNode: _searchFocusNode,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 40),
                child: _buildCategoryChips(
                  selected: _selectedCategory,
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                    viewModel.setCategory(category);
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    state.errorMessage!,
                    style: AppTextStyles.captionWithColor(
                      AppColors.badgeRedText,
                    ),
                  ),
                ),
              if (state.isLoading)
                const SizedBox(
                  height: 280,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (offers.isEmpty)
                _buildEmptyCard()
              else
                ...offers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final offer = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == offers.length - 1 ? 0 : 12,
                    ),
                    child: AnimatedFadeSlide(
                      delay: Duration(milliseconds: 70 + (index * 26)),
                      child: MarketOfferCard(
                        offer: offer,
                        onTap: () => _openOfferDetail(context, offer),
                        onActionTap: () => _openOfferDetail(context, offer),
                        onEditTap: offer.isMine
                            ? () => _onEditMineOffer(
                                context: context,
                                offer: offer,
                              )
                            : null,
                        onDeleteTap: offer.isMine
                            ? () => _onDeleteMineOffer(
                                context: context,
                                viewModel: viewModel,
                                offer: offer,
                              )
                            : null,
                        onCompleteTap: offer.isMine
                            ? () => _onCompleteMineOffer(
                                context: context,
                                viewModel: viewModel,
                                offer: offer,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.pageHorizontal,
          bottom: AppSpacing.pageHorizontal + 8,
          child: AnimatedFadeSlide(
            delay: const Duration(milliseconds: 240),
            offset: const Offset(0, 0.2),
            child: Material(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(999),
              elevation: 4,
              shadowColor: AppColors.shadowSoft,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openTradeRegisterPage(context),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.textPrimary,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required ValueChanged<String> onChanged,
    required FocusNode focusNode,
  }) {
    final borderColor = _isSearchFocused
        ? AppColors.accentDeepOrange
        : AppColors.borderStrong;
    final iconColor = _isSearchFocused
        ? AppColors.accentDeepOrange
        : AppColors.borderStrong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: _isSearchFocused ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, color: iconColor, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              onChanged: onChanged,
              cursorColor: AppColors.accentDeepOrange,
              style: AppTextStyles.bodyPrimaryStrong,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '가구, 레시피, 주민 검색...',
                hintStyle: AppTextStyles.bodyHintStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips({
    required MarketFilterCategory selected,
    required ValueChanged<MarketFilterCategory> onSelected,
  }) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MarketFilterCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = MarketFilterCategory.values[index];
          final isSelected = category == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.catalogChipSelectedBg
                    : AppColors.catalogChipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                category.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionWithColor(
                  isSelected ? AppColors.accentDeepOrange : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.storefront_outlined,
            size: 42,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 8),
          Text('등록된 거래가 없어요.', style: AppTextStyles.bodySecondaryStrong),
          const SizedBox(height: 4),
          Text('플러스 버튼으로 첫 거래를 등록해보세요.', style: AppTextStyles.bodyHintStrong),
        ],
      ),
    );
  }

  Future<void> _openTradeRegisterPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MarketTradeRegisterPage()),
    );
  }

  Future<void> _openOfferDetail(BuildContext context, MarketOffer offer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketOfferDetailPage(offer: offer),
      ),
    );
  }

  Future<void> _onEditMineOffer({
    required BuildContext context,
    required MarketOffer offer,
  }) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MarketTradeRegisterPage(initialOffer: offer),
      ),
    );
    if (updated != true || !mounted) {
      return;
    }
    _showSnack('거래 글을 수정했어요.');
  }

  Future<void> _onDeleteMineOffer({
    required BuildContext context,
    required MarketViewModel viewModel,
    required MarketOffer offer,
  }) async {
    final shouldDelete = await _showDeleteConfirmDialog(context);
    if (shouldDelete != true || !mounted) {
      return;
    }
    await viewModel.deleteOffer(offer.id);
    if (!mounted) {
      return;
    }
    _showSnack('거래 글을 삭제했어요.');
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
                Text('거래 글 삭제', style: AppTextStyles.dialogTitle),
                const SizedBox(height: 10),
                Text('정말 이 거래 글을 삭제할까요?', style: AppTextStyles.dialogBody),
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

  Future<void> _onCompleteMineOffer({
    required BuildContext context,
    required MarketViewModel viewModel,
    required MarketOffer offer,
  }) async {
    final shouldComplete = await _showCompleteConfirmDialog(context);
    if (shouldComplete != true || !mounted) {
      return;
    }
    await viewModel.setOfferLifecycle(
      offerId: offer.id,
      lifecycle: MarketLifecycleTab.completed,
      status: MarketOfferStatus.closed,
    );
    if (!mounted) {
      return;
    }
    _showSnack('거래를 완료로 변경했어요.');
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
                Text('거래 완료 처리', style: AppTextStyles.dialogTitle),
                const SizedBox(height: 10),
                Text('이 거래를 완료 상태로 변경할까요?', style: AppTextStyles.dialogBody),
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

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
