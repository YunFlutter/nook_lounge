import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_offer.freezed.dart';

enum MarketFilterCategory {
  all('전체'),
  item('아이템'),
  recipe('레시피'),
  villager('주민'),
  touching('만지작');

  const MarketFilterCategory(this.label);
  final String label;
}

enum MarketBoardType { exchange, touching }

enum MarketOfferStatus {
  open('열림'),
  waiting('대기중'),
  closed('닫힘'),
  offline('오프라인'),
  trading('거래중');

  const MarketOfferStatus(this.label);
  final String label;
}

enum MarketLifecycleTab {
  ongoing('진행중'),
  cancelled('거래취소'),
  completed('완료');

  const MarketLifecycleTab(this.label);
  final String label;
}

enum MarketTradeType {
  sharing('나눔'),
  exchange('교환'),
  touching('만지작'),
  crafting('제작 중');

  const MarketTradeType(this.label);
  final String label;
}

enum MarketMoveType {
  visitor('제가 갈게요'),
  host('섬을 열게요');

  const MarketMoveType(this.label);
  final String label;
}

@freezed
sealed class MarketOffer with _$MarketOffer {
  const MarketOffer._();

  const factory MarketOffer({
    required String id,
    required String ownerUid,
    required MarketFilterCategory category,
    required MarketBoardType boardType,
    required MarketLifecycleTab lifecycle,
    required MarketOfferStatus status,
    required String ownerName,
    required String ownerAvatarUrl,
    required String title,
    required String offerHeaderLabel,
    required String offerItemName,
    required String offerItemImageUrl,
    required int offerItemQuantity,
    @Default('') String offerItemCategory,
    @Default('') String offerItemVariant,
    required String wantHeaderLabel,
    required String wantItemName,
    required String wantItemImageUrl,
    required int wantItemQuantity,
    @Default('') String wantItemCategory,
    @Default('') String wantItemVariant,
    required List<String> touchingTags,
    required String entryFeeText,
    @Default(false) bool isMine,
    @Default(false) bool dimmed,
    required String description,
    required MarketTradeType tradeType,
    required MarketMoveType moveType,
    @Default('') String coverImageUrl,
    @Default(false) bool oneWayOffer,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MarketOffer;

  String get statusLabel => status.label;

  factory MarketOffer.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return MarketOffer(
      id: id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      category: _parseEnum(
        values: MarketFilterCategory.values,
        value: data['category'] as String?,
        fallback: MarketFilterCategory.all,
      ),
      boardType: _parseEnum(
        values: MarketBoardType.values,
        value: data['boardType'] as String?,
        fallback: MarketBoardType.exchange,
      ),
      lifecycle: _parseEnum(
        values: MarketLifecycleTab.values,
        value: data['lifecycle'] as String?,
        fallback: MarketLifecycleTab.ongoing,
      ),
      status: _parseEnum(
        values: MarketOfferStatus.values,
        value: data['status'] as String?,
        fallback: MarketOfferStatus.open,
      ),
      ownerName: (data['ownerName'] as String?) ?? '',
      ownerAvatarUrl: (data['ownerAvatarUrl'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      offerHeaderLabel: (data['offerHeaderLabel'] as String?) ?? '',
      offerItemName: (data['offerItemName'] as String?) ?? '',
      offerItemImageUrl: (data['offerItemImageUrl'] as String?) ?? '',
      offerItemQuantity: (data['offerItemQuantity'] as num?)?.toInt() ?? 0,
      offerItemCategory: (data['offerItemCategory'] as String?) ?? '',
      offerItemVariant: (data['offerItemVariant'] as String?) ?? '',
      wantHeaderLabel: (data['wantHeaderLabel'] as String?) ?? '',
      wantItemName: (data['wantItemName'] as String?) ?? '',
      wantItemImageUrl: (data['wantItemImageUrl'] as String?) ?? '',
      wantItemQuantity: (data['wantItemQuantity'] as num?)?.toInt() ?? 0,
      wantItemCategory: (data['wantItemCategory'] as String?) ?? '',
      wantItemVariant: (data['wantItemVariant'] as String?) ?? '',
      touchingTags:
          (data['touchingTags'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      entryFeeText: (data['entryFeeText'] as String?) ?? '무료',
      description: (data['description'] as String?) ?? '',
      tradeType: _parseEnum(
        values: MarketTradeType.values,
        value: data['tradeType'] as String?,
        fallback: MarketTradeType.exchange,
      ),
      moveType: _parseEnum(
        values: MarketMoveType.values,
        value: data['moveType'] as String?,
        fallback: MarketMoveType.visitor,
      ),
      coverImageUrl: _normalizeRemoteImageUrl(data['coverImageUrl'] as String?),
      oneWayOffer: (data['oneWayOffer'] as bool?) ?? false,
      createdAt: _parseDateTime(
        createdAt: data['createdAt'],
        createdAtMillis: data['createdAtMillis'],
      ),
      updatedAt: _parseDateTime(
        createdAt: data['updatedAt'] ?? data['createdAt'],
        createdAtMillis: data['updatedAtMillis'] ?? data['createdAtMillis'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerUid': ownerUid,
      'category': category.name,
      'boardType': boardType.name,
      'lifecycle': lifecycle.name,
      'status': status.name,
      'ownerName': ownerName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'title': title,
      'offerHeaderLabel': offerHeaderLabel,
      'offerItemName': offerItemName,
      'offerItemImageUrl': offerItemImageUrl,
      'offerItemQuantity': offerItemQuantity,
      'offerItemCategory': offerItemCategory,
      'offerItemVariant': offerItemVariant,
      'wantHeaderLabel': wantHeaderLabel,
      'wantItemName': wantItemName,
      'wantItemImageUrl': wantItemImageUrl,
      'wantItemQuantity': wantItemQuantity,
      'wantItemCategory': wantItemCategory,
      'wantItemVariant': wantItemVariant,
      'touchingTags': touchingTags,
      'entryFeeText': entryFeeText,
      'description': description,
      'tradeType': tradeType.name,
      'moveType': moveType.name,
      'coverImageUrl': coverImageUrl,
      'oneWayOffer': oneWayOffer,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

String _normalizeRemoteImageUrl(String? value) {
  final source = (value ?? '').trim();
  if (source.isEmpty) {
    return '';
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return source;
  }
  // 유지보수 포인트:
  // 과거 문서에 로컬 경로가 저장된 경우 화면 표시에 사용하지 않도록 차단합니다.
  return '';
}

DateTime _parseDateTime({
  required Object? createdAt,
  required Object? createdAtMillis,
}) {
  // 유지보수 포인트:
  // 기존 문서(createdAtMillis)와 신규 문서(createdAt Timestamp/DateTime)를
  // 모두 읽을 수 있게 하여 점진 마이그레이션이 가능하도록 합니다.
  final parsed = _toDateTime(createdAt);
  if (parsed != null) {
    return parsed;
  }
  final legacyMillis = _toInt(createdAtMillis);
  if (legacyMillis != null && legacyMillis > 0) {
    return DateTime.fromMillisecondsSinceEpoch(legacyMillis);
  }
  return DateTime.now();
}

DateTime? _toDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  try {
    final dynamic converted = (value as dynamic).toDate();
    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {}
  return null;
}

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

T _parseEnum<T extends Enum>({
  required List<T> values,
  required String? value,
  required T fallback,
}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }
  for (final candidate in values) {
    if (candidate.name == value) {
      return candidate;
    }
  }
  return fallback;
}
