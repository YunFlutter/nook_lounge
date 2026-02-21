import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';

class MarketItemPickerSheet extends ConsumerStatefulWidget {
  const MarketItemPickerSheet({
    required this.title,
    this.initialKeyword = '',
    this.initialCategoryKey = _allCategoryKey,
    super.key,
  });

  final String title;
  final String initialKeyword;
  final String initialCategoryKey;

  static const String _allCategoryKey = 'all';
  static const String _furnitureCategoryKey = 'furniture';
  static const String _wallpaperCategoryKey = 'wallpaper';
  static const String _fashionCategoryKey = 'fashion';
  static const String _recipeCategoryKey = 'recipe';
  static const String _villagerCategoryKey = 'villager';
  static const String _fossilCategoryKey = 'fossil';
  static const String _seaCategoryKey = 'sea';
  static const String _fishCategoryKey = 'fish';
  static const String _bugCategoryKey = 'bug';
  static const String _artCategoryKey = 'art';

  static const List<String> _categoryKeys = <String>[
    _allCategoryKey,
    _furnitureCategoryKey,
    _wallpaperCategoryKey,
    _fashionCategoryKey,
    _recipeCategoryKey,
    _villagerCategoryKey,
    _fossilCategoryKey,
    _seaCategoryKey,
    _fishCategoryKey,
    _bugCategoryKey,
    _artCategoryKey,
  ];

  static const Map<String, String> _categoryLabels = <String, String>{
    _allCategoryKey: '전체',
    _furnitureCategoryKey: '가구',
    _wallpaperCategoryKey: '벽지',
    _fashionCategoryKey: '의상',
    _recipeCategoryKey: '레시피',
    _villagerCategoryKey: '주민',
    _fossilCategoryKey: '화석',
    _seaCategoryKey: '해산물',
    _fishCategoryKey: '물고기',
    _bugCategoryKey: '곤충',
    _artCategoryKey: '미술품',
  };

  @override
  ConsumerState<MarketItemPickerSheet> createState() =>
      _MarketItemPickerSheetState();
}

class _MarketItemPickerSheetState extends ConsumerState<MarketItemPickerSheet> {
  late final Future<List<CatalogItem>> _itemsFuture;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late String _selectedCategoryKey;
  bool _isSearchFocused = false;
  CatalogItem? _selectedItem;
  String _expandedItemId = '';

  @override
  void initState() {
    super.initState();
    _itemsFuture = ref.read(catalogRepositoryProvider).loadAll();
    _searchController = TextEditingController(text: widget.initialKeyword);
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _selectedCategoryKey = widget.initialCategoryKey;
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.modalOuter,
          8,
          AppSpacing.modalOuter,
          AppSpacing.modalOuter,
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 78,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<CatalogItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          '아이템 데이터를 불러오지 못했어요.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final items = _filterItems(snapshot.data!);
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        '검색 결과가 없어요.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final expanded = item.id == _expandedItemId;
                      final selected = _selectedItem?.id == item.id;
                      return _buildItemTile(
                        item: item,
                        expanded: expanded,
                        selected: selected,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selectedItem == null
                  ? null
                  : () => Navigator.of(context).pop(_selectedItem),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentDeepOrange,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text(
                _selectedItem?.category == '주민' ? '주민을 선택했어요' : '아이템을 선택했어요',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final borderColor = _isSearchFocused
        ? AppColors.accentDeepOrange
        : AppColors.borderStrong;
    final iconColor = _isSearchFocused
        ? AppColors.accentDeepOrange
        : AppColors.borderStrong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: _isSearchFocused ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              cursorColor: AppColors.accentDeepOrange,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: '가구, 레시피, 주민 검색...',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MarketItemPickerSheet._categoryKeys.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoryKey = MarketItemPickerSheet._categoryKeys[index];
          final selected = categoryKey == _selectedCategoryKey;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              setState(() {
                _selectedCategoryKey = categoryKey;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.catalogChipSelectedBg
                    : AppColors.catalogChipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                MarketItemPickerSheet._categoryLabels[categoryKey] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? AppColors.accentDeepOrange
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemTile({
    required CatalogItem item,
    required bool expanded,
    required bool selected,
  }) {
    final priceTag = _extractPrefixedTagValue(item, '판매가');
    final infoRows = _buildInfoRows(item);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _selectedItem = item;
          _expandedItemId = expanded ? '' : item.id;
        });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.accentDeepOrange
                : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                ClipOval(
                  child: Container(
                    width: 42,
                    height: 42,
                    color: AppColors.catalogChipBg,
                    child: _buildItemImage(item.imageUrl),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (priceTag.isNotEmpty)
                        Text(
                          '판매가 $priceTag',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.catalogChipBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                ),
              ],
            ),
            if (expanded) ...<Widget>[
              const SizedBox(height: 10),
              if (infoRows.isEmpty) _buildFallbackMetaChip(item.category),
              if (infoRows.isNotEmpty) _buildInfoGrid(infoRows),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackMetaChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<MapEntry<String, String>> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final isWide = constraints.maxWidth >= 320;
        final columns = isWide ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: rows
              .map(
                (entry) => SizedBox(
                  width: itemWidth,
                  child: _buildInfoCell(label: entry.key, value: entry.value),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildInfoCell({required String label, required String value}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _buildInfoRows(CatalogItem item) {
    final fields = switch (item.category) {
      '주민' => <String>['종', '성격', '성별', '취미', '생일', '별자리', '말버릇'],
      '물고기' => <String>['판매가', '서식처', '희귀도', '출현시간', '북반구', '남반구'],
      '곤충' => <String>['판매가', '서식처', '희귀도', '출현시간', '북반구', '남반구'],
      '해산물' => <String>['판매가', '희귀도', '출현시간', '북반구', '남반구'],
      '화석' => <String>['판매가', '그룹'],
      '미술품' => <String>['판매가', '구매가', '획득처', '가품'],
      '레시피' => <String>['판매가', '획득처', '재료'],
      '패션' => <String>['판매가', '구매가', '획득처', '스타일', '성별'],
      '벽지' => <String>['유형', '태그', '판매가', '구매가', '획득처', '색상', '테마'],
      '가구' => <String>['판매가', '구매가', '획득처', '크기', '리폼', '스타일'],
      '아이템' => <String>['판매가', '구매가', '획득처', '스타일', '크기', '리폼'],
      _ => <String>['판매가', '구매가', '획득처'],
    };

    final rows = <MapEntry<String, String>>[];
    for (final field in fields) {
      final value = _extractPrefixedTagValue(item, field);
      if (!_isMeaningfulValue(value)) {
        continue;
      }
      rows.add(MapEntry<String, String>(field, value));
      if (rows.length >= 8) {
        break;
      }
    }

    final variationValues = _extractPrefixedTagValues(
      item,
      '색상옵션',
    ).where(_isMeaningfulValue).toSet().take(4).toList(growable: false);
    if (variationValues.isNotEmpty) {
      rows.add(MapEntry<String, String>('색상옵션', variationValues.join(', ')));
    }

    return rows;
  }

  bool _isMeaningfulValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }
    const hiddenValues = <String>{'-', '--', 'null', 'none', 'n/a', 'na'};
    return !hiddenValues.contains(normalized.toLowerCase());
  }

  String _extractPrefixedTagValue(CatalogItem item, String prefix) {
    final targetPrefix = '$prefix:';
    final tag = item.tags.firstWhere(
      (value) => value.startsWith(targetPrefix),
      orElse: () => '',
    );
    if (tag.isEmpty) {
      return '';
    }
    return tag.substring(targetPrefix.length).trim();
  }

  List<String> _extractPrefixedTagValues(CatalogItem item, String prefix) {
    final targetPrefix = '$prefix:';
    return item.tags
        .where((value) => value.startsWith(targetPrefix))
        .map((value) => value.substring(targetPrefix.length).trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Widget _buildItemImage(String source) {
    if (source.isEmpty) {
      return const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textHint,
      );
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
    );
  }

  List<CatalogItem> _filterItems(List<CatalogItem> source) {
    final keyword = _searchController.text.trim().toLowerCase();
    return source
        .where((item) {
          if (!_matchesSelectedCategory(item)) {
            return false;
          }
          if (keyword.isEmpty) {
            return true;
          }
          return item.name.toLowerCase().contains(keyword) ||
              item.tags.any((tag) => tag.toLowerCase().contains(keyword));
        })
        .take(100)
        .toList(growable: false);
  }

  bool _matchesSelectedCategory(CatalogItem item) {
    switch (_selectedCategoryKey) {
      case MarketItemPickerSheet._allCategoryKey:
        return true;
      case MarketItemPickerSheet._furnitureCategoryKey:
        return item.category == '가구';
      case MarketItemPickerSheet._wallpaperCategoryKey:
        return item.category == '벽지';
      case MarketItemPickerSheet._fashionCategoryKey:
        return item.category == '패션';
      case MarketItemPickerSheet._recipeCategoryKey:
        return item.category == '레시피';
      case MarketItemPickerSheet._villagerCategoryKey:
        return item.category == '주민';
      case MarketItemPickerSheet._fossilCategoryKey:
        return item.category == '화석';
      case MarketItemPickerSheet._seaCategoryKey:
        return item.category == '해산물';
      case MarketItemPickerSheet._fishCategoryKey:
        return item.category == '물고기';
      case MarketItemPickerSheet._bugCategoryKey:
        return item.category == '곤충';
      case MarketItemPickerSheet._artCategoryKey:
        return item.category == '미술품';
      default:
        return true;
    }
  }
}
