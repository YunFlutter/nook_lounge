import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

part 'market_view_state.freezed.dart';

@freezed
sealed class MarketViewState with _$MarketViewState {
  const factory MarketViewState({
    @Default('') String searchQuery,
    @Default(MarketFilterCategory.all) MarketFilterCategory selectedCategory,
    @Default(MarketLifecycleTab.ongoing) MarketLifecycleTab selectedLifecycle,
    @Default(<MarketOffer>[]) List<MarketOffer> offers,
    @Default(true) bool isLoading,
    String? errorMessage,
  }) = _MarketViewState;
}
