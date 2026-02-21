import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketViewState {
  const MarketViewState({
    this.searchQuery = '',
    this.selectedCategory = MarketFilterCategory.all,
    this.selectedLifecycle = MarketLifecycleTab.ongoing,
    this.offers = const <MarketOffer>[],
    this.isLoading = true,
    this.errorMessage,
  });

  final String searchQuery;
  final MarketFilterCategory selectedCategory;
  final MarketLifecycleTab selectedLifecycle;
  final List<MarketOffer> offers;
  final bool isLoading;
  final String? errorMessage;

  MarketViewState copyWith({
    String? searchQuery,
    MarketFilterCategory? selectedCategory,
    MarketLifecycleTab? selectedLifecycle,
    List<MarketOffer>? offers,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MarketViewState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedLifecycle: selectedLifecycle ?? this.selectedLifecycle,
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
