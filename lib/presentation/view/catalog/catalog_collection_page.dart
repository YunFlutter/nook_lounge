import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';

class CatalogCollectionPage extends ConsumerStatefulWidget {
  const CatalogCollectionPage({
    required this.uid,
    required this.title,
    required this.category,
    required this.allItems,
    super.key,
  });

  final String uid;
  final String title;
  final String category;
  final List<CatalogItem> allItems;

  @override
  ConsumerState<CatalogCollectionPage> createState() =>
      _CatalogCollectionPageState();
}

class _CatalogCollectionPageState extends ConsumerState<CatalogCollectionPage> {
  final TextEditingController _searchController = TextEditingController();

  _CatalogCompletionFilter _completionFilter = _CatalogCompletionFilter.all;
  _VillagerResidentFilter _villagerResidentFilter = _VillagerResidentFilter.all;
  final Map<String, String> _selectedDropdownValues = <String, String>{};

  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedOverrides = ref.watch(
      catalogBindingViewModelProvider(widget.uid),
    );
    final config = _CategoryViewConfig.from(widget.category);
    final categoryItems = widget.allItems
        .where((item) => item.category == widget.category)
        .toList(growable: false);
    final filtered = categoryItems
        .where(
          (item) =>
              _matchesFilters(item, completedOverrides, config.dropdownFilters),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.catalogHorizontal,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.s10),
                if (widget.category == '주민')
                  _buildVillagerResidentSegment()
                else
                  _buildCompletionSegment(donationMode: config.donationMode),
                const SizedBox(height: AppSpacing.s10),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '이름으로 검색...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                if (config.dropdownFilters.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.s10),
                  _buildDropdownFilters(config.dropdownFilters, categoryItems),
                ],
                const SizedBox(height: AppSpacing.s10),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyView()
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, unused) =>
                              const SizedBox(height: AppSpacing.s10),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final completed = _isCompleted(
                              item,
                              completedOverrides,
                            );
                            final favorite = _isFavorite(
                              item,
                              completedOverrides,
                            );
                            return AnimatedFadeSlide(
                              delay: Duration(
                                milliseconds: 30 + ((index % 8) * 20),
                              ),
                              child: _CatalogItemCard(
                                item: item,
                                completed: completed,
                                favorite: favorite,
                                donationMode: config.donationMode,
                                onTap: () => _openDetailSheet(
                                  item: item,
                                  donationMode: config.donationMode,
                                ),
                                onToggleResident: widget.category == '주민'
                                    ? () => _setVillagerResident(
                                        item: item,
                                        current: completed,
                                      )
                                    : null,
                                onToggleFavorite: widget.category == '주민'
                                    ? () => _setVillagerFavorite(
                                        item: item,
                                        current: favorite,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.catalogHorizontal,
            right: AppSpacing.catalogHorizontal,
            bottom: AppSpacing.s10,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 240),
              offset: _toastMessage == null
                  ? const Offset(0, 1.2)
                  : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _toastMessage == null ? 0 : 1,
                child: _toastMessage == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.catalogCardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderStrong,
                            width: 2,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.bgSecondary,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/icon_blue_fish.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _toastMessage!,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.catalogProgressAccent,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSegment({required bool donationMode}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: _CatalogCompletionFilter.values
            .map((filter) {
              final selected = _completionFilter == filter;
              final label = filter.label(donationMode: donationMode);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _completionFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.shadowSoft,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildVillagerResidentSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: _VillagerResidentFilter.values
            .map((filter) {
              final selected = _villagerResidentFilter == filter;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _villagerResidentFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected
                          ? const <BoxShadow>[
                              BoxShadow(
                                color: AppColors.shadowSoft,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildDropdownFilters(
    List<_DropdownFilterDefinition> dropdownFilters,
    List<CatalogItem> categoryItems,
  ) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dropdownFilters.length,
        separatorBuilder: (_, unused) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = dropdownFilters[index];
          final options = _buildDropdownOptions(filter, categoryItems);
          final selectedRaw = _selectedDropdownValues[filter.key] ?? '전체';
          final selected = options.contains(selectedRaw) ? selectedRaw : '전체';

          return _CatalogDropdownFilter(
            width: filter.width,
            title: filter.label,
            selectedValue: selected,
            options: options,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedDropdownValues[filter.key] = value);
            },
          );
        },
      ),
    );
  }

  List<String> _buildDropdownOptions(
    _DropdownFilterDefinition definition,
    List<CatalogItem> categoryItems,
  ) {
    final options = <String>{'전체'};

    switch (definition.type) {
      case _DropdownFilterType.prefixedTag:
        final prefix = definition.prefix;
        if (prefix == null || prefix.isEmpty) {
          return options.toList(growable: false);
        }
        for (final item in categoryItems) {
          for (final tag in item.tags) {
            final key = '$prefix:';
            if (!tag.startsWith(key)) {
              continue;
            }
            final value = tag.substring(key.length).trim();
            if (value.isEmpty) {
              continue;
            }
            options.add(value);
          }
        }
      case _DropdownFilterType.artAuthenticity:
        for (final item in categoryItems) {
          if (item.tags.contains('가품:있음')) {
            options.add('가품 있음');
          }
          if (item.tags.contains('가품:없음')) {
            options.add('가품 없음');
          }
        }
    }

    final list = options.toList(growable: false);
    if (list.length <= 2) {
      return list;
    }

    final first = list.first;
    final rest = list.sublist(1)..sort();
    return <String>[first, ...rest];
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            'assets/images/no_data_image.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            '아직 데이터가 없어요...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  bool _matchesFilters(
    CatalogItem item,
    Map<String, CatalogUserState> completedOverrides,
    List<_DropdownFilterDefinition> dropdownFilters,
  ) {
    final keyword = _searchController.text.trim();
    if (!item.matches(keyword)) {
      return false;
    }

    if (widget.category == '주민') {
      final isResident = _isCompleted(item, completedOverrides);
      final isFavorite = _isFavorite(item, completedOverrides);
      if (_villagerResidentFilter == _VillagerResidentFilter.resident &&
          !isResident) {
        return false;
      }
      if (_villagerResidentFilter == _VillagerResidentFilter.favorite &&
          !isFavorite) {
        return false;
      }
    } else {
      final completed = _isCompleted(item, completedOverrides);
      switch (_completionFilter) {
        case _CatalogCompletionFilter.completed:
          if (!completed) {
            return false;
          }
        case _CatalogCompletionFilter.notCompleted:
          if (completed) {
            return false;
          }
        case _CatalogCompletionFilter.all:
          break;
      }
    }

    for (final filter in dropdownFilters) {
      final selected = _selectedDropdownValues[filter.key] ?? '전체';
      if (selected == '전체') {
        continue;
      }
      if (!_matchesDropdown(item, filter, selected)) {
        return false;
      }
    }

    return true;
  }

  bool _matchesDropdown(
    CatalogItem item,
    _DropdownFilterDefinition definition,
    String selected,
  ) {
    switch (definition.type) {
      case _DropdownFilterType.prefixedTag:
        final prefix = definition.prefix;
        if (prefix == null || prefix.isEmpty) {
          return true;
        }
        return item.tags.any((tag) => tag == '$prefix:$selected');
      case _DropdownFilterType.artAuthenticity:
        if (selected == '가품 있음') {
          return item.tags.any((tag) => tag == '가품:있음');
        }
        if (selected == '가품 없음') {
          return item.tags.any((tag) => tag == '가품:없음');
        }
        return true;
    }
  }

  bool _isCompleted(
    CatalogItem item,
    Map<String, CatalogUserState> completedOverrides,
  ) {
    return resolveCatalogCompleted(item: item, userStates: completedOverrides);
  }

  bool _isFavorite(
    CatalogItem item,
    Map<String, CatalogUserState> completedOverrides,
  ) {
    return completedOverrides[item.id]?.favorite ?? false;
  }

  Future<void> _openDetailSheet({
    required CatalogItem item,
    required bool donationMode,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CatalogItemDetailSheet(
          item: item,
          isCompleted: _isCompleted(
            item,
            ref.read(catalogBindingViewModelProvider(widget.uid)),
          ),
          isFavorite: _isFavorite(
            item,
            ref.read(catalogBindingViewModelProvider(widget.uid)),
          ),
          isDonationMode: donationMode,
          onCompletedChanged: (value) async {
            await ref
                .read(catalogBindingViewModelProvider(widget.uid).notifier)
                .setCompleted(
                  itemId: item.id,
                  category: item.category,
                  donationMode: donationMode,
                  completed: value,
                );
            if (!mounted) {
              return;
            }
            _showToast(
              widget.category == '주민'
                  ? (value ? '거주 주민으로 설정했어요.' : '거주 주민 해제했어요.')
                  : value
                  ? (donationMode ? '박물관 기증 완료!' : '아이템 보유 처리 완료!')
                  : (donationMode
                        ? '기증 상태를 미기증으로 변경했어요.'
                        : '보유 상태를 미보유로 변경했어요.'),
            );
          },
          onFavoriteChanged: (value) async {
            await ref
                .read(catalogBindingViewModelProvider(widget.uid).notifier)
                .setFavorite(
                  itemId: item.id,
                  category: item.category,
                  favorite: value,
                );
            if (!mounted) {
              return;
            }
            _showToast(value ? '선호 주민으로 등록했어요.' : '선호 주민 해제했어요.');
          },
        );
      },
    );
  }

  Future<void> _setVillagerResident({
    required CatalogItem item,
    required bool current,
  }) async {
    final next = !current;
    await ref
        .read(catalogBindingViewModelProvider(widget.uid).notifier)
        .setCompleted(
          itemId: item.id,
          category: item.category,
          donationMode: false,
          completed: next,
        );
    if (!mounted) {
      return;
    }
    _showToast(next ? '거주 주민으로 설정했어요.' : '거주 주민 해제했어요.');
  }

  Future<void> _setVillagerFavorite({
    required CatalogItem item,
    required bool current,
  }) async {
    final next = !current;
    await ref
        .read(catalogBindingViewModelProvider(widget.uid).notifier)
        .setFavorite(itemId: item.id, category: item.category, favorite: next);
    if (!mounted) {
      return;
    }
    _showToast(next ? '선호 주민으로 등록했어요.' : '선호 주민 해제했어요.');
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() => _toastMessage = null);
    });
  }
}

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({
    required this.item,
    required this.completed,
    required this.favorite,
    required this.donationMode,
    required this.onTap,
    required this.onToggleResident,
    required this.onToggleFavorite,
  });

  final CatalogItem item;
  final bool completed;
  final bool favorite;
  final bool donationMode;
  final VoidCallback onTap;
  final VoidCallback? onToggleResident;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final rare = _isRare(item.tags);
    final tag1 = _resolvePrimaryTag(item.tags) ?? item.category;
    final isVillager = item.category == '주민';
    final statusStyle = _StatusStyle.resolve(
      completed: completed,
      donationMode: donationMode,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.catalogCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: <Widget>[
            _CatalogAvatarThumb(item: item, size: isVillager ? 62 : 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (rare)
                        Text(
                          '희귀종',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.badgeRedText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _SmallBadge(
                        label: tag1,
                        background: AppColors.badgeBlueBg,
                        foreground: AppColors.badgeBlueText,
                      ),
                      if (!isVillager)
                        _SmallBadge(
                          label: donationMode
                              ? (completed ? '기증완료' : '미기증')
                              : (completed ? '보유' : '미보유'),
                          background: statusStyle.background,
                          foreground: statusStyle.foreground,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isVillager) ...<Widget>[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _QuickIconToggleButton(
                    icon: Icons.home_rounded,
                    semanticLabel: completed ? '거주중' : '거주 선택',
                    selected: completed,
                    selectedBackground: AppColors.catalogSuccessBg,
                    selectedForeground: AppColors.catalogSuccessText,
                    onTap: onToggleResident,
                  ),
                  const SizedBox(width: 8),
                  _QuickIconToggleButton(
                    icon: Icons.favorite_rounded,
                    semanticLabel: favorite ? '선호중' : '선호 선택',
                    selected: favorite,
                    selectedBackground: AppColors.badgePurpleBg,
                    selectedForeground: AppColors.badgePurpleText,
                    onTap: onToggleFavorite,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _resolvePrimaryTag(List<String> tags) {
    for (final tag in tags) {
      if (tag.contains(':')) {
        continue;
      }
      if (tag.trim().isEmpty) {
        continue;
      }
      return tag;
    }
    return null;
  }

  bool _isRare(List<String> tags) {
    for (final tag in tags) {
      if (tag == '희귀종') {
        return true;
      }
      if (!tag.startsWith('희귀도:')) {
        continue;
      }
      final value = tag.substring('희귀도:'.length).trim();
      if (value.contains('희귀')) {
        return true;
      }
    }
    return false;
  }
}

class _CatalogAvatarThumb extends StatelessWidget {
  const _CatalogAvatarThumb({required this.item, required this.size});

  final CatalogItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/icon_raccoon_character.png',
      fit: BoxFit.contain,
    );

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: item.imageUrl.isEmpty
              ? fallback
              : Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickIconToggleButton extends StatelessWidget {
  const _QuickIconToggleButton({
    required this.icon,
    required this.semanticLabel,
    required this.selected,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool selected;
  final Color selectedBackground;
  final Color selectedForeground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      child: IconButton(
        onPressed: onTap,
        tooltip: semanticLabel,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: selected ? selectedForeground : AppColors.textMuted,
          backgroundColor: selected
              ? selectedBackground
              : AppColors.catalogChipBg,
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected ? selectedForeground : AppColors.borderDefault,
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogDropdownFilter extends StatelessWidget {
  const _CatalogDropdownFilter({
    required this.width,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String title;
  final String selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.catalogChipBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              selectedItemBuilder: (context) {
                return options
                    .map(
                      (option) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          option == '전체' ? title : option,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    )
                    .toList(growable: false);
              },
              items: options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static _StatusStyle resolve({
    required bool completed,
    required bool donationMode,
  }) {
    if (donationMode) {
      return completed
          ? const _StatusStyle(
              background: AppColors.badgeRedBg,
              foreground: AppColors.badgeRedText,
            )
          : const _StatusStyle(
              background: AppColors.badgeBeigeBg,
              foreground: AppColors.badgeBeigeText,
            );
    }

    return completed
        ? const _StatusStyle(
            background: AppColors.catalogSuccessBg,
            foreground: AppColors.catalogSuccessText,
          )
        : const _StatusStyle(
            background: AppColors.badgeBeigeBg,
            foreground: AppColors.badgeBeigeText,
          );
  }
}

enum _CatalogCompletionFilter {
  all,
  completed,
  notCompleted;

  String label({required bool donationMode}) {
    switch (this) {
      case _CatalogCompletionFilter.all:
        return '전체';
      case _CatalogCompletionFilter.completed:
        return donationMode ? '기증완료' : '보유';
      case _CatalogCompletionFilter.notCompleted:
        return donationMode ? '미기증' : '미보유';
    }
  }
}

enum _VillagerResidentFilter {
  all,
  favorite,
  resident;

  String get label {
    switch (this) {
      case _VillagerResidentFilter.all:
        return '전체';
      case _VillagerResidentFilter.favorite:
        return '선호주민';
      case _VillagerResidentFilter.resident:
        return '거주주민';
    }
  }
}

class _CategoryViewConfig {
  const _CategoryViewConfig({
    required this.dropdownFilters,
    required this.donationMode,
  });

  final List<_DropdownFilterDefinition> dropdownFilters;
  final bool donationMode;

  static _CategoryViewConfig from(String category) {
    switch (category) {
      case '물고기':
      case '곤충':
      case '해산물':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'habitat',
              label: '서식처',
              prefix: '서식처',
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'rarity',
              label: '희귀도',
              prefix: '희귀도',
            ),
          ],
          donationMode: true,
        );
      case '화석':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'fossilGroup',
              label: '그룹',
              prefix: '그룹',
            ),
          ],
          donationMode: true,
        );
      case '미술품':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.artAuthenticity(),
          ],
          donationMode: true,
        );
      case '레시피':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'source',
              label: '획득처',
              prefix: '획득처',
              width: 130,
            ),
          ],
          donationMode: false,
        );
      case '패션':
      case '아이템':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'source',
              label: '획득처',
              prefix: '획득처',
              width: 130,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'style',
              label: '스타일',
              prefix: '스타일',
              width: 120,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'variation',
              label: '색상옵션',
              prefix: '색상옵션',
              width: 130,
            ),
          ],
          donationMode: false,
        );
      case '가구':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'source',
              label: '획득처',
              prefix: '획득처',
              width: 130,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'style',
              label: '스타일',
              prefix: '스타일',
              width: 120,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'variation',
              label: '색상옵션',
              prefix: '색상옵션',
              width: 130,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'remodel',
              label: '리폼',
              prefix: '리폼',
              width: 110,
            ),
          ],
          donationMode: false,
        );
      case '주민':
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[
            _DropdownFilterDefinition.prefixed(
              key: 'personality',
              label: '성격',
              prefix: '성격',
              width: 110,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'species',
              label: '종',
              prefix: '종',
              width: 110,
            ),
            _DropdownFilterDefinition.prefixed(
              key: 'gender',
              label: '성별',
              prefix: '성별',
              width: 110,
            ),
          ],
          donationMode: false,
        );
      default:
        return const _CategoryViewConfig(
          dropdownFilters: <_DropdownFilterDefinition>[],
          donationMode: false,
        );
    }
  }
}

enum _DropdownFilterType { prefixedTag, artAuthenticity }

class _DropdownFilterDefinition {
  const _DropdownFilterDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.prefix,
    this.width = 120,
  });

  const _DropdownFilterDefinition.prefixed({
    required String key,
    required String label,
    required String prefix,
    double width = 120,
  }) : this(
         key: key,
         label: label,
         type: _DropdownFilterType.prefixedTag,
         prefix: prefix,
         width: width,
       );

  const _DropdownFilterDefinition.artAuthenticity()
    : this(
        key: 'authenticity',
        label: '가품',
        type: _DropdownFilterType.artAuthenticity,
        width: 120,
      );

  final String key;
  final String label;
  final _DropdownFilterType type;
  final String? prefix;
  final double width;
}
