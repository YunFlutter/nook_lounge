import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketSelectableItem {
  const MarketSelectableItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.priceText,
    this.sizeText = '',
    this.remodelText = '',
    this.materialText = '',
    this.variantText = '',
  });

  final String id;
  final String name;
  final MarketFilterCategory category;
  final String imageUrl;
  final String priceText;
  final String sizeText;
  final String remodelText;
  final String materialText;
  final String variantText;
}
