import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';

class LocalCatalogDataSource {
  static const Map<String, String> _assetByCategory = <String, String>{
    '주민': 'assets/json/villagers.json',
    '물고기': 'assets/json/fish.json',
    '곤충': 'assets/json/bugs.json',
    '해산물': 'assets/json/sea.json',
    '화석': 'assets/json/fossils_individuals.json',
    '미술품': 'assets/json/art.json',
    '레시피': 'assets/json/recipes.json',
    '가구': 'assets/json/furniture.json',
    '패션': 'assets/json/clothing.json',
    '아이템': 'assets/json/items.json',
  };

  List<CatalogItem>? _cachedItems;

  Future<List<CatalogItem>> loadAll() async {
    if (_cachedItems != null) {
      return _cachedItems!;
    }

    // 유지보수 포인트:
    // 도감/아이템 원본은 앱 assets에서만 로드해 Firebase read 비용을 0으로 유지합니다.
    // 서버에는 "사용자 상태(보유/기증/즐겨찾기)"만 저장하세요.
    final items = <CatalogItem>[];

    for (final entry in _assetByCategory.entries) {
      final rawJson = await rootBundle.loadString(entry.value);
      final decoded = jsonDecode(rawJson);

      if (decoded is! List<dynamic>) {
        continue;
      }

      for (final row in decoded) {
        if (row is! Map<String, dynamic>) {
          continue;
        }

        final id = _stringOrFallback(
          row['id'],
          fallback: _stringOrFallback(
            row['number'],
            fallback: _stringOrFallback(row['name'], fallback: ''),
          ),
        );

        final name = _stringOrFallback(row['name'], fallback: '이름 없음');
        final imageUrl = _stringOrFallback(
          row['image_url'],
          fallback: _stringOrFallback(row['icon_url'], fallback: ''),
        );

        final tags = <String>{
          _stringOrFallback(row['species'], fallback: ''),
          _stringOrFallback(row['personality'], fallback: ''),
          _stringOrFallback(row['location'], fallback: ''),
          _stringOrFallback(row['material_type'], fallback: ''),
          _stringOrFallback(row['rarity'], fallback: ''),
        }..removeWhere((value) => value.isEmpty);

        items.add(
          CatalogItem(
            id: '${entry.key}-$id-$name',
            category: entry.key,
            name: name,
            imageUrl: imageUrl,
            tags: tags.toList(growable: false),
          ),
        );
      }
    }

    _cachedItems = List<CatalogItem>.unmodifiable(items);
    return _cachedItems!;
  }

  Future<List<CatalogItem>> search({
    required String keyword,
    String? category,
    int limit = 50,
  }) async {
    final all = await loadAll();

    final filtered = all.where((item) {
      final categoryMatch = category == null || category == item.category;
      final keywordMatch = item.matches(keyword);
      return categoryMatch && keywordMatch;
    });

    return filtered.take(limit).toList(growable: false);
  }

  String _stringOrFallback(Object? value, {required String fallback}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
