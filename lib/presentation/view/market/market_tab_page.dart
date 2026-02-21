import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/market/market_my_trades_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_card.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_register_page.dart';

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
  bool _isSearchFocused = false;
  MarketFilterCategory _selectedCategory = MarketFilterCategory.all;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
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
                    style: const TextStyle(
                      color: AppColors.badgeRedText,
                      fontWeight: FontWeight.w700,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
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
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
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
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accentDeepOrange
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
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
      child: const Column(
        children: <Widget>[
          Icon(Icons.storefront_outlined, size: 42, color: AppColors.textHint),
          SizedBox(height: 8),
          Text(
            '등록된 거래가 없어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '플러스 버튼으로 첫 거래를 등록해보세요.',
            style: TextStyle(
              color: AppColors.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
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
}
