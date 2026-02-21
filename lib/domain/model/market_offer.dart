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

class MarketOffer {
  const MarketOffer({
    required this.id,
    required this.ownerUid,
    required this.category,
    required this.boardType,
    required this.lifecycle,
    required this.status,
    required this.ownerName,
    required this.ownerAvatarUrl,
    required this.createdAtLabel,
    required this.title,
    required this.offerHeaderLabel,
    required this.offerItemName,
    required this.offerItemImageUrl,
    required this.offerItemQuantity,
    this.offerItemVariant = '',
    required this.wantHeaderLabel,
    required this.wantItemName,
    required this.wantItemImageUrl,
    required this.wantItemQuantity,
    this.wantItemVariant = '',
    required this.touchingTags,
    required this.entryFeeText,
    required this.actionLabel,
    required this.isMine,
    required this.dimmed,
    required this.description,
    required this.tradeType,
    required this.moveType,
    this.statusLabelOverride = '',
    this.coverImageUrl = '',
    this.oneWayOffer = false,
    this.createdAtMillis = 0,
  });

  final String id;
  final String ownerUid;
  final MarketFilterCategory category;
  final MarketBoardType boardType;
  final MarketLifecycleTab lifecycle;
  final MarketOfferStatus status;
  final String ownerName;
  final String ownerAvatarUrl;
  final String createdAtLabel;
  final String title;
  final String offerHeaderLabel;
  final String offerItemName;
  final String offerItemImageUrl;
  final int offerItemQuantity;
  final String offerItemVariant;
  final String wantHeaderLabel;
  final String wantItemName;
  final String wantItemImageUrl;
  final int wantItemQuantity;
  final String wantItemVariant;
  final List<String> touchingTags;
  final String entryFeeText;
  final String actionLabel;
  final bool isMine;
  final bool dimmed;
  final String description;
  final MarketTradeType tradeType;
  final MarketMoveType moveType;
  final String statusLabelOverride;
  final String coverImageUrl;
  final bool oneWayOffer;
  final int createdAtMillis;

  String get statusLabel {
    if (statusLabelOverride.isNotEmpty) {
      return statusLabelOverride;
    }
    return status.label;
  }

  MarketOffer copyWith({
    String? id,
    String? ownerUid,
    MarketFilterCategory? category,
    MarketBoardType? boardType,
    MarketLifecycleTab? lifecycle,
    MarketOfferStatus? status,
    String? ownerName,
    String? ownerAvatarUrl,
    String? createdAtLabel,
    String? title,
    String? offerHeaderLabel,
    String? offerItemName,
    String? offerItemImageUrl,
    int? offerItemQuantity,
    String? offerItemVariant,
    String? wantHeaderLabel,
    String? wantItemName,
    String? wantItemImageUrl,
    int? wantItemQuantity,
    String? wantItemVariant,
    List<String>? touchingTags,
    String? entryFeeText,
    String? actionLabel,
    bool? isMine,
    bool? dimmed,
    String? description,
    MarketTradeType? tradeType,
    MarketMoveType? moveType,
    String? statusLabelOverride,
    String? coverImageUrl,
    bool? oneWayOffer,
    int? createdAtMillis,
  }) {
    return MarketOffer(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      category: category ?? this.category,
      boardType: boardType ?? this.boardType,
      lifecycle: lifecycle ?? this.lifecycle,
      status: status ?? this.status,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      createdAtLabel: createdAtLabel ?? this.createdAtLabel,
      title: title ?? this.title,
      offerHeaderLabel: offerHeaderLabel ?? this.offerHeaderLabel,
      offerItemName: offerItemName ?? this.offerItemName,
      offerItemImageUrl: offerItemImageUrl ?? this.offerItemImageUrl,
      offerItemQuantity: offerItemQuantity ?? this.offerItemQuantity,
      offerItemVariant: offerItemVariant ?? this.offerItemVariant,
      wantHeaderLabel: wantHeaderLabel ?? this.wantHeaderLabel,
      wantItemName: wantItemName ?? this.wantItemName,
      wantItemImageUrl: wantItemImageUrl ?? this.wantItemImageUrl,
      wantItemQuantity: wantItemQuantity ?? this.wantItemQuantity,
      wantItemVariant: wantItemVariant ?? this.wantItemVariant,
      touchingTags: touchingTags ?? this.touchingTags,
      entryFeeText: entryFeeText ?? this.entryFeeText,
      actionLabel: actionLabel ?? this.actionLabel,
      isMine: isMine ?? this.isMine,
      dimmed: dimmed ?? this.dimmed,
      description: description ?? this.description,
      tradeType: tradeType ?? this.tradeType,
      moveType: moveType ?? this.moveType,
      statusLabelOverride: statusLabelOverride ?? this.statusLabelOverride,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      oneWayOffer: oneWayOffer ?? this.oneWayOffer,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

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
      createdAtLabel: (data['createdAtLabel'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      offerHeaderLabel: (data['offerHeaderLabel'] as String?) ?? '',
      offerItemName: (data['offerItemName'] as String?) ?? '',
      offerItemImageUrl: (data['offerItemImageUrl'] as String?) ?? '',
      offerItemQuantity: (data['offerItemQuantity'] as num?)?.toInt() ?? 0,
      offerItemVariant: (data['offerItemVariant'] as String?) ?? '',
      wantHeaderLabel: (data['wantHeaderLabel'] as String?) ?? '',
      wantItemName: (data['wantItemName'] as String?) ?? '',
      wantItemImageUrl: (data['wantItemImageUrl'] as String?) ?? '',
      wantItemQuantity: (data['wantItemQuantity'] as num?)?.toInt() ?? 0,
      wantItemVariant: (data['wantItemVariant'] as String?) ?? '',
      touchingTags:
          (data['touchingTags'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      entryFeeText: (data['entryFeeText'] as String?) ?? '무료',
      actionLabel: (data['actionLabel'] as String?) ?? '',
      isMine: (data['isMine'] as bool?) ?? false,
      dimmed: (data['dimmed'] as bool?) ?? false,
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
      statusLabelOverride: (data['statusLabelOverride'] as String?) ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
      oneWayOffer: (data['oneWayOffer'] as bool?) ?? false,
      createdAtMillis: (data['createdAtMillis'] as num?)?.toInt() ?? 0,
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
      'createdAtLabel': createdAtLabel,
      'title': title,
      'offerHeaderLabel': offerHeaderLabel,
      'offerItemName': offerItemName,
      'offerItemImageUrl': offerItemImageUrl,
      'offerItemQuantity': offerItemQuantity,
      'offerItemVariant': offerItemVariant,
      'wantHeaderLabel': wantHeaderLabel,
      'wantItemName': wantItemName,
      'wantItemImageUrl': wantItemImageUrl,
      'wantItemQuantity': wantItemQuantity,
      'wantItemVariant': wantItemVariant,
      'touchingTags': touchingTags,
      'entryFeeText': entryFeeText,
      'actionLabel': actionLabel,
      'isMine': isMine,
      'dimmed': dimmed,
      'description': description,
      'tradeType': tradeType.name,
      'moveType': moveType.name,
      'statusLabelOverride': statusLabelOverride,
      'coverImageUrl': coverImageUrl,
      'oneWayOffer': oneWayOffer,
      'createdAtMillis': createdAtMillis,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
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
