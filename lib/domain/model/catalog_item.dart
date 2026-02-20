import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_item.freezed.dart';

@freezed
sealed class CatalogItem with _$CatalogItem {
  const CatalogItem._();

  const factory CatalogItem({
    required String id,
    required String category,
    required String name,
    required String imageUrl,
    required List<String> tags,
  }) = _CatalogItem;

  bool matches(String keyword) {
    final normalizedKeyword = keyword.trim().toLowerCase();

    if (normalizedKeyword.isEmpty) {
      return true;
    }

    final haystack = <String>[name, ...tags].join(' ').toLowerCase();
    return haystack.contains(normalizedKeyword);
  }
}
