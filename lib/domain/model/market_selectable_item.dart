import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

part 'market_selectable_item.freezed.dart';

@freezed
sealed class MarketSelectableItem with _$MarketSelectableItem {
  const factory MarketSelectableItem({
    required String id,
    required String name,
    required MarketFilterCategory category,
    required String imageUrl,
    required String priceText,
    @Default('') String sizeText,
    @Default('') String remodelText,
    @Default('') String materialText,
    @Default('') String variantText,
  }) = _MarketSelectableItem;
}
