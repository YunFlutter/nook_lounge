class CatalogUserState {
  const CatalogUserState({
    required this.itemId,
    required this.owned,
    required this.donated,
    required this.favorite,
    required this.category,
    required this.memo,
  });

  final String itemId;
  final bool owned;
  final bool donated;
  final bool favorite;
  final String category;
  final String memo;

  factory CatalogUserState.fromMap({
    required String itemId,
    required Map<String, dynamic> data,
  }) {
    return CatalogUserState(
      itemId: itemId,
      owned: (data['owned'] as bool?) ?? false,
      donated: (data['donated'] as bool?) ?? false,
      favorite: (data['favorite'] as bool?) ?? false,
      category: (data['category'] as String?) ?? '',
      memo: (data['memo'] as String?) ?? '',
    );
  }

  CatalogUserState copyWith({
    bool? owned,
    bool? donated,
    bool? favorite,
    String? category,
    String? memo,
  }) {
    return CatalogUserState(
      itemId: itemId,
      owned: owned ?? this.owned,
      donated: donated ?? this.donated,
      favorite: favorite ?? this.favorite,
      category: category ?? this.category,
      memo: memo ?? this.memo,
    );
  }
}
