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
    if (_cachedItems != null && !_requiresCacheRefresh(_cachedItems!)) {
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
        final imageUrl = _resolveImageUrl(category: entry.key, row: row);

        final tags = <String>{
          _stringOrFallback(row['species'], fallback: ''),
          _stringOrFallback(row['personality'], fallback: ''),
          _stringOrFallback(row['location'], fallback: ''),
          _stringOrFallback(row['material_type'], fallback: ''),
          _stringOrFallback(row['rarity'], fallback: ''),
        }..removeWhere((value) => value.isEmpty);

        _addPrefixedTag(
          tags,
          prefix: '판매가',
          value: _stringOrFallback(row['sell_nook'], fallback: ''),
          suffix: '벨',
        );
        _addPrefixedTag(
          tags,
          prefix: '판매가',
          value: _stringOrFallback(row['sell'], fallback: ''),
          suffix: '벨',
        );
        _addPrefixedTag(
          tags,
          prefix: '판매가',
          value: _extractSellPriceFromRow(row),
          suffix: '벨',
        );
        _addPrefixedTag(
          tags,
          prefix: '구매가',
          value: _extractBuyPriceFromRow(row),
          suffix: '벨',
        );
        _addPrefixedTag(
          tags,
          prefix: '출현시간',
          value: _stringOrFallback(row['time'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '북반구',
          value: _stringOrFallback(row['n_availability'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '남반구',
          value: _stringOrFallback(row['s_availability'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '서식처',
          value: _stringOrFallback(row['location'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '희귀도',
          value: _stringOrFallback(row['rarity'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '성격',
          value: _stringOrFallback(row['personality'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '종',
          value: _stringOrFallback(row['species'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '성별',
          value: _stringOrFallback(row['gender'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '그룹',
          value: _stringOrFallback(row['fossil_group'], fallback: ''),
        );
        _addPrefixedTag(
          tags,
          prefix: '획득처',
          value: _extractAvailabilityFromRow(row),
        );
        _addPrefixedTag(tags, prefix: '재료', value: _extractMaterials(row));
        _addPrefixedTag(tags, prefix: '리폼', value: _extractCustomizable(row));
        _addVillagerPrefixedTags(tags: tags, category: entry.key, row: row);
        _addArtImageTags(tags: tags, category: entry.key, row: row);
        _addFashionVariationTags(tags: tags, category: entry.key, row: row);

        if (row['has_fake'] is bool) {
          tags.add((row['has_fake'] as bool) ? '가품:있음' : '가품:없음');
        }
        final style = _extractStyle(row);
        if (style.isNotEmpty) {
          tags.add('스타일:$style');
        }

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

  void _addPrefixedTag(
    Set<String> tags, {
    required String prefix,
    required String value,
    String suffix = '',
  }) {
    if (value.isEmpty) {
      return;
    }
    tags.add('$prefix:$value$suffix');
  }

  String _resolveImageUrl({
    required String category,
    required Map<String, dynamic> row,
  }) {
    if (category == '주민') {
      final villagerPreferredKeys = <String>[
        'image_url',
        'icon_url',
        'photo_url',
      ];
      for (final key in villagerPreferredKeys) {
        final value = _extractNhDetailsValue(row, key);
        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    final directKeys = <String>[
      'image_url',
      'icon_url',
      'render_url',
      'texture_url',
      'fake_image_url',
      'fake_texture_url',
    ];

    for (final key in directKeys) {
      final value = _stringOrFallback(row[key], fallback: '');
      if (value.isNotEmpty) {
        return value;
      }
    }

    final variations = row['variations'];
    if (variations is List) {
      for (final variation in variations) {
        if (variation is! Map<String, dynamic>) {
          continue;
        }
        final variationImage = _stringOrFallback(
          variation['image_url'],
          fallback: '',
        );
        if (variationImage.isNotEmpty) {
          return variationImage;
        }
      }
    }

    return '';
  }

  String _extractBuyPriceFromRow(Map<String, dynamic> row) {
    final directBuy = row['buy'];
    if (directBuy is num || directBuy is String) {
      final text = _stringOrFallback(directBuy, fallback: '');
      if (text.isNotEmpty) {
        final normalized = _extractBellPriceFromText(text);
        return normalized.isNotEmpty ? normalized : text;
      }
    }

    final buy = directBuy;
    if (buy is! List) {
      return '';
    }

    String fallbackPrice = '';
    for (final entry in buy) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final price = _stringOrFallback(entry['price'], fallback: '');
      final currency = _stringOrFallback(entry['currency'], fallback: '');
      if (price.isEmpty) {
        continue;
      }
      if (fallbackPrice.isEmpty) {
        fallbackPrice = price;
      }
      if (currency == '벨') {
        return price;
      }
    }

    return fallbackPrice;
  }

  String _extractSellPriceFromRow(Map<String, dynamic> row) {
    final sellNook = _stringOrFallback(row['sell_nook'], fallback: '');
    if (sellNook.isNotEmpty) {
      return sellNook;
    }
    return _stringOrFallback(row['sell'], fallback: '');
  }

  String _extractAvailabilityFromRow(Map<String, dynamic> row) {
    final availability = row['availability'];
    if (availability is String) {
      return availability;
    }
    if (availability is! List) {
      return '';
    }

    final sources = <String>{};
    for (final entry in availability) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final source = _stringOrFallback(entry['from'], fallback: '');
      if (source.isNotEmpty) {
        sources.add(source);
      }
    }
    return sources.take(2).join(', ');
  }

  String _extractMaterials(Map<String, dynamic> row) {
    final materials = row['materials'];
    if (materials is! List) {
      return '';
    }

    final values = <String>[];
    for (final entry in materials) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final name = _stringOrFallback(entry['name'], fallback: '');
      final count = _stringOrFallback(entry['count'], fallback: '');
      if (name.isEmpty) {
        continue;
      }
      values.add(count.isEmpty ? name : '$name x$count');
    }
    return values.take(3).join(', ');
  }

  String _extractCustomizable(Map<String, dynamic> row) {
    final customizable = row['customizable'];
    if (customizable is bool) {
      return customizable ? '가능' : '불가';
    }
    return '';
  }

  String _extractStyle(Map<String, dynamic> row) {
    final style1 = _stringOrFallback(row['style_1'], fallback: '');
    if (style1.isNotEmpty) {
      return style1;
    }

    final styles = row['styles'];
    if (styles is List && styles.isNotEmpty) {
      return _stringOrFallback(styles.first, fallback: '');
    }
    return '';
  }

  void _addVillagerPrefixedTags({
    required Set<String> tags,
    required String category,
    required Map<String, dynamic> row,
  }) {
    if (category != '주민') {
      return;
    }

    _addPrefixedTag(
      tags,
      prefix: '성격',
      value: _stringOrFallback(row['personality'], fallback: ''),
    );
    _addPrefixedTag(
      tags,
      prefix: '종',
      value: _stringOrFallback(row['species'], fallback: ''),
    );
    _addPrefixedTag(
      tags,
      prefix: '성별',
      value: _stringOrFallback(row['gender'], fallback: ''),
    );
    _addPrefixedTag(tags, prefix: '생일', value: _extractBirthday(row));
    _addPrefixedTag(
      tags,
      prefix: '별자리',
      value: _stringOrFallback(row['sign'], fallback: ''),
    );
    _addPrefixedTag(
      tags,
      prefix: '말버릇',
      value: _extractNhDetailsValue(row, 'catchphrase'),
    );
    _addPrefixedTag(
      tags,
      prefix: '좌우명',
      value: _extractNhDetailsValue(
        row,
        'quote',
        fallback: _stringOrFallback(row['quote'], fallback: ''),
      ),
    );
    _addPrefixedTag(
      tags,
      prefix: '취미',
      value: _extractNhDetailsValue(row, 'hobby'),
    );
    _addPrefixedTag(tags, prefix: '의상', value: _mergeVillagerClothing(row));
    _addPrefixedTag(
      tags,
      prefix: '선호색상',
      value: _extractNhList(row, 'fav_colors'),
    );
    _addPrefixedTag(
      tags,
      prefix: '선호스타일',
      value: _extractNhList(row, 'fav_styles'),
    );
    _addPrefixedTag(
      tags,
      prefix: '인테리어BGM',
      value: _extractNhDetailsValue(row, 'house_music'),
    );
    _addPrefixedTag(
      tags,
      prefix: '주민사진URL',
      value: _extractNhDetailsValue(row, 'photo_url'),
    );
    _addPrefixedTag(
      tags,
      prefix: '아이콘URL',
      value: _extractNhDetailsValue(row, 'icon_url'),
    );
    _addPrefixedTag(
      tags,
      prefix: '집내부URL',
      value: _extractNhDetailsValue(row, 'house_interior_url'),
    );
    _addPrefixedTag(
      tags,
      prefix: '집외부URL',
      value: _extractNhDetailsValue(row, 'house_exterior_url'),
    );
    _addPrefixedTag(
      tags,
      prefix: '우산',
      value: _extractNhDetailsValue(row, 'umbrella'),
    );
    _addPrefixedTag(
      tags,
      prefix: '성격세부',
      value: _extractNhDetailsValue(row, 'sub-personality'),
    );
    _addPrefixedTag(
      tags,
      prefix: '집 벽지',
      value: _extractNhDetailsValue(row, 'house_wallpaper'),
    );
    _addPrefixedTag(
      tags,
      prefix: '집 바닥',
      value: _extractNhDetailsValue(row, 'house_flooring'),
    );
    _addPrefixedTag(
      tags,
      prefix: '인테리어 음악노트',
      value: _extractNhDetailsValue(row, 'house_music_note'),
    );
    _addPrefixedTag(tags, prefix: '이전 말버릇', value: _extractPrevPhrases(row));
  }

  void _addFashionVariationTags({
    required Set<String> tags,
    required String category,
    required Map<String, dynamic> row,
  }) {
    if (category != '패션') {
      return;
    }

    final variations = row['variations'];
    if (variations is! List) {
      return;
    }

    for (final variation in variations) {
      if (variation is! Map<String, dynamic>) {
        continue;
      }
      final imageUrl = _stringOrFallback(variation['image_url'], fallback: '');
      if (imageUrl.isEmpty) {
        continue;
      }
      final variationName = _stringOrFallback(
        variation['variation'],
        fallback: '기본',
      );
      final colors = _extractVariationColors(variation);
      final label = colors.isNotEmpty
          ? '$variationName ($colors)'
          : variationName;

      _addPrefixedTag(tags, prefix: '색상옵션', value: variationName);
      _addPrefixedTag(tags, prefix: '옵션이미지URL', value: '$label||$imageUrl');
    }
  }

  void _addArtImageTags({
    required Set<String> tags,
    required String category,
    required Map<String, dynamic> row,
  }) {
    if (category != '미술품') {
      return;
    }

    _addPrefixedTag(
      tags,
      prefix: '진품텍스처URL',
      value: _stringOrFallback(row['texture_url'], fallback: ''),
    );
    _addPrefixedTag(
      tags,
      prefix: '가품아이콘URL',
      value: _stringOrFallback(row['fake_image_url'], fallback: ''),
    );
    _addPrefixedTag(
      tags,
      prefix: '가품텍스처URL',
      value: _stringOrFallback(row['fake_texture_url'], fallback: ''),
    );
  }

  String _extractBirthday(Map<String, dynamic> row) {
    final monthRaw = _stringOrFallback(row['birthday_month'], fallback: '');
    final dayRaw = _stringOrFallback(row['birthday_day'], fallback: '');

    if (monthRaw.isEmpty && dayRaw.isEmpty) {
      return '';
    }

    final month = monthRaw.replaceAll('월', '').trim();
    final day = dayRaw.replaceAll('일', '').trim();

    if (month.isEmpty) {
      return day.isEmpty ? '' : '$day일';
    }
    if (day.isEmpty) {
      return '$month월';
    }
    return '$month월 $day일';
  }

  String _mergeVillagerClothing(Map<String, dynamic> row) {
    final clothing = _extractNhDetailsValue(
      row,
      'clothing',
      fallback: _stringOrFallback(row['clothing'], fallback: ''),
    );
    final variation = _extractNhDetailsValue(row, 'clothing_variation');

    if (clothing.isEmpty) {
      return variation;
    }
    if (variation.isEmpty) {
      return clothing;
    }
    return '$clothing ($variation)';
  }

  String _extractNhDetailsValue(
    Map<String, dynamic> row,
    String key, {
    String fallback = '',
  }) {
    final nhDetails = row['nh_details'];
    if (nhDetails is! Map<String, dynamic>) {
      return fallback;
    }
    return _stringOrFallback(nhDetails[key], fallback: fallback);
  }

  String _extractNhList(Map<String, dynamic> row, String key) {
    final nhDetails = row['nh_details'];
    if (nhDetails is! Map<String, dynamic>) {
      return '';
    }

    final values = nhDetails[key];
    if (values is! List) {
      return '';
    }

    final labels = <String>[];
    for (final value in values) {
      final text = _stringOrFallback(value, fallback: '');
      if (text.isEmpty) {
        continue;
      }
      labels.add(text);
    }
    return labels.join(', ');
  }

  String _extractPrevPhrases(Map<String, dynamic> row) {
    final phrases = row['prev_phrases'];
    if (phrases is! List) {
      return '';
    }
    final values = <String>[];
    for (final phrase in phrases) {
      final text = _stringOrFallback(phrase, fallback: '');
      if (text.isEmpty) {
        continue;
      }
      values.add(text);
      if (values.length == 3) {
        break;
      }
    }
    return values.join(', ');
  }

  String _extractVariationColors(Map<String, dynamic> variation) {
    final colors = variation['colors'];
    if (colors is! List) {
      return '';
    }
    final labels = <String>[];
    for (final color in colors) {
      final text = _stringOrFallback(color, fallback: '');
      if (text.isEmpty) {
        continue;
      }
      labels.add(text);
    }
    return labels.join(', ');
  }

  bool _containsLegacyPricePattern(List<CatalogItem> items) {
    for (final item in items) {
      for (final tag in item.tags) {
        if (tag.contains('price:') || tag.contains('currency:')) {
          return true;
        }
      }
    }
    return false;
  }

  bool _requiresCacheRefresh(List<CatalogItem> items) {
    if (_containsLegacyPricePattern(items)) {
      return true;
    }

    for (final item in items) {
      if (item.category != '주민') {
        continue;
      }
      final hasBirthday = item.tags.any((tag) => tag.startsWith('생일:'));
      final hasHobby = item.tags.any((tag) => tag.startsWith('취미:'));
      final hasCatchphrase = item.tags.any((tag) => tag.startsWith('말버릇:'));
      final hasNhImage = item.tags.any((tag) => tag.startsWith('주민사진URL:'));
      if (!hasBirthday || !hasHobby || !hasCatchphrase || !hasNhImage) {
        return true;
      }
    }

    for (final item in items) {
      if (item.category != '패션') {
        continue;
      }
      final hasVariationImage = item.tags.any(
        (tag) => tag.startsWith('옵션이미지URL:'),
      );
      if (!hasVariationImage) {
        return true;
      }
    }

    for (final item in items) {
      if (item.category != '미술품') {
        continue;
      }
      final hasAnyArtImage = item.tags.any(
        (tag) =>
            tag.startsWith('진품텍스처URL:') ||
            tag.startsWith('가품아이콘URL:') ||
            tag.startsWith('가품텍스처URL:'),
      );
      if (!hasAnyArtImage) {
        return true;
      }
    }
    return false;
  }

  String _extractBellPriceFromText(String text) {
    final pattern = RegExp(
      r'price:\s*([0-9,]+)\s*,\s*currency:\s*([^,\}\]]+)',
      caseSensitive: false,
    );
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) {
      return '';
    }

    String fallback = '';
    for (final match in matches) {
      final price = match.group(1)?.trim() ?? '';
      final currency = (match.group(2) ?? '').trim();
      if (price.isEmpty) {
        continue;
      }
      if (fallback.isEmpty) {
        fallback = price;
      }
      if (currency == '벨') {
        return price;
      }
    }
    return fallback;
  }
}
