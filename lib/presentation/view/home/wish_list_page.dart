import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';

final wishListCatalogProvider = FutureProvider.autoDispose
    .family<List<CatalogItem>, String>((ref, uid) async {
      return ref.watch(catalogRepositoryProvider).loadAll();
    });

class WishListPage extends ConsumerStatefulWidget {
  const WishListPage({
    required this.uid,
    required this.islandId,
    this.initialCategory = '전체',
    super.key,
  });

  final String uid;
  final String islandId;
  final String initialCategory;

  @override
  ConsumerState<WishListPage> createState() => _WishListPageState();
}

class _WishListPageState extends ConsumerState<WishListPage> {
  static const List<String> _categoryKeys = <String>[
    '전체',
    '주민',
    '물고기',
    '곤충',
    '해산물',
    '화석',
    '미술품',
    '패션',
    '레시피',
    '가구',
    '아이템',
  ];

  static const Map<String, String> _categoryLabels = <String, String>{
    '전체': '전체',
    '주민': '주민',
    '물고기': '물고기',
    '곤충': '곤충',
    '해산물': '해산물',
    '화석': '화석',
    '미술품': '미술품',
    '패션': '패션',
    '레시피': '레시피',
    '가구': '가구',
    '아이템': '벽지 등',
  };

  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryKeys.contains(widget.initialCategory)
        ? widget.initialCategory
        : '전체';
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wishListCatalogProvider(widget.uid));
    final userStates = ref.watch(
      catalogBindingViewModelProvider((
        uid: widget.uid,
        islandId: widget.islandId,
      )),
    );

    final allItems = itemsAsync.valueOrNull ?? const <CatalogItem>[];
    final favorites = allItems
        .where((item) => userStates[item.id]?.favorite ?? false)
        .toList(growable: false);
    final filtered = _selectedCategory == '전체'
        ? favorites
        : favorites
              .where((item) => item.category == _selectedCategory)
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('카테고리 위시 리스트')),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.s10),
            _buildCategoryFilter(favorites),
            const SizedBox(height: AppSpacing.s10),
            Expanded(
              child: itemsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : itemsAsync.hasError
                  ? _buildInfoText('위시 리스트를 불러오지 못했어요.')
                  : filtered.isEmpty
                  ? _buildInfoText('선택한 카테고리의 위시 아이템이 없어요.')
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, unused) =>
                          const SizedBox(height: AppSpacing.s10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return AnimatedFadeSlide(
                          delay: Duration(milliseconds: 20 * (index % 6)),
                          child: _buildWishItemCard(
                            context: context,
                            item: item,
                            userStates: userStates,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<CatalogItem> favorites) {
    final counts = <String, int>{};
    for (final key in _categoryKeys) {
      if (key == '전체') {
        counts[key] = favorites.length;
        continue;
      }
      counts[key] = favorites.where((item) => item.category == key).length;
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryKeys.length,
        separatorBuilder: (_, unused) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = _categoryKeys[index];
          final selected = _selectedCategory == key;
          final count = counts[key] ?? 0;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.catalogChipSelectedBg
                    : AppColors.catalogChipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _categoryLabels[key] ?? key,
                    style: AppTextStyles.bodyWithSize(
                      14,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: AppTextStyles.captionWithColor(
                      selected ? AppColors.textPrimary : AppColors.textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishItemCard({
    required BuildContext context,
    required CatalogItem item,
    required Map<String, CatalogUserState> userStates,
  }) {
    final displayCategory = _categoryLabels[item.category] ?? item.category;
    final details = item.tags
        .where((tag) => !tag.contains(':'))
        .take(2)
        .join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetailSheet(item: item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.catalogCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.bgSecondary,
                  child: item.imageUrl.isEmpty
                      ? Image.asset(
                          'assets/images/no_data_image.png',
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'assets/images/no_data_image.png',
                                fit: BoxFit.contain,
                              ),
                        ),
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
                      style: AppTextStyles.bodyWithSize(
                        16,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBlueBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        displayCategory,
                        style: AppTextStyles.captionWithColor(
                          AppColors.badgeBlueText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (details.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionWithColor(
                          AppColors.textSecondary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: '위시 해제',
                onPressed: () async {
                  await ref
                      .read(
                        catalogBindingViewModelProvider((
                          uid: widget.uid,
                          islandId: widget.islandId,
                        )).notifier,
                      )
                      .setFavorite(
                        itemId: item.id,
                        category: item.category,
                        favorite: false,
                      );
                },
                icon: const Icon(Icons.favorite, color: AppColors.badgeRedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyWithSize(
          14,
          color: AppColors.textSecondary,
          weight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }

  Future<void> _openDetailSheet({required CatalogItem item}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final states = ref.read(
          catalogBindingViewModelProvider((
            uid: widget.uid,
            islandId: widget.islandId,
          )),
        );
        return CatalogItemDetailSheet(
          item: item,
          isCompleted: resolveCatalogCompleted(item: item, userStates: states),
          isFavorite: states[item.id]?.favorite ?? false,
          isDonationMode: _isDonationCategory(item.category),
          initialMemo: states[item.id]?.memo ?? '',
          onMemoSaved: item.category == '주민'
              ? (memo) async {
                  await ref
                      .read(
                        catalogBindingViewModelProvider((
                          uid: widget.uid,
                          islandId: widget.islandId,
                        )).notifier,
                      )
                      .setVillagerMemo(
                        itemId: item.id,
                        category: item.category,
                        memo: memo,
                      );
                }
              : null,
          onCompletedChanged: (value) async {
            await ref
                .read(
                  catalogBindingViewModelProvider((
                    uid: widget.uid,
                    islandId: widget.islandId,
                  )).notifier,
                )
                .setCompleted(
                  itemId: item.id,
                  category: item.category,
                  donationMode: _isDonationCategory(item.category),
                  completed: value,
                );
          },
          onFavoriteChanged: (value) async {
            await ref
                .read(
                  catalogBindingViewModelProvider((
                    uid: widget.uid,
                    islandId: widget.islandId,
                  )).notifier,
                )
                .setFavorite(
                  itemId: item.id,
                  category: item.category,
                  favorite: value,
                );
          },
        );
      },
    );
  }

  bool _isDonationCategory(String category) {
    return category == '물고기' ||
        category == '곤충' ||
        category == '해산물' ||
        category == '화석' ||
        category == '미술품';
  }
}
