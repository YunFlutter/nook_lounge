import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:nook_lounge_app/presentation/view/common/app_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/error/resident_limit_exceeded_exception.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_badge_palette.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';

class CatalogCollectionPage extends ConsumerStatefulWidget {
  const CatalogCollectionPage({
    required this.uid,
    required this.islandId,
    required this.title,
    required this.category,
    required this.allItems,
    this.startWithResidentFilter = false,
    this.readOnly = false,
    super.key,
  });

  final String uid;
  final String islandId;
  final String title;
  final String category;
  final List<CatalogItem> allItems;
  final bool startWithResidentFilter;
  final bool readOnly;

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
  void initState() {
    super.initState();
    if (widget.category == '주민' && widget.startWithResidentFilter) {
      _villagerResidentFilter = _VillagerResidentFilter.resident;
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.of(context).viewPadding.bottom;
    final completedOverrides = widget.readOnly
        ? const <String, CatalogUserState>{}
        : ref.watch(
            catalogBindingViewModelProvider((
              uid: widget.uid,
              islandId: widget.islandId,
            )),
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
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: AppSpacing.pageHorizontal,
        title: _buildHomeStyleAppBarTitle(widget.title),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.catalogHorizontal,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.s10),
                if (!widget.readOnly)
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
                                onToggleResident:
                                    widget.readOnly || widget.category != '주민'
                                    ? null
                                    : () => _setVillagerResident(
                                        item: item,
                                        current: completed,
                                      ),
                                onToggleFavorite:
                                    widget.readOnly || widget.category != '주민'
                                    ? null
                                    : () => _setVillagerFavorite(
                                        item: item,
                                        current: favorite,
                                      ),
                                showVillagerActions:
                                    !widget.readOnly && widget.category == '주민',
                              ),
                            );
                          },
                        ),
                ),
                if (widget.readOnly) ...<Widget>[
                  const SizedBox(height: AppSpacing.s10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.catalogChipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Text(
                      '비회원 둘러보기 모드에서는 상태 저장이 비활성화됩니다.',
                      style: AppTextStyles.captionSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.catalogHorizontal,
            right: AppSpacing.catalogHorizontal,
            // 유지보수 포인트:
            // iOS 홈 인디케이터 영역을 고려해 토스트가 하단에 잘리지 않도록 보정합니다.
            bottom: bottomSafeInset + AppSpacing.s10,
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
                                  'assets/app_icons.png',
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
                                style: AppTextStyles.bodyPrimaryStrong,
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
    return AppSegmentedControl<_CatalogCompletionFilter>(
      value: _completionFilter,
      items: _CatalogCompletionFilter.values
          .map(
            (filter) => (
              value: filter,
              label: filter.label(donationMode: donationMode),
              icon: null,
              selectedColor: AppColors.textPrimary,
              semanticsLabel: filter.label(donationMode: donationMode),
            ),
          )
          .toList(growable: false),
      // 유지보수 포인트:
      // 도감 상단 필터는 선택 패널만 슬라이드하고 텍스트는 즉시 전환해서
      // 빠르게 탭할 때 양쪽이 함께 번쩍이는 느낌을 줄입니다.
      textStyleBuilder: (context, item, foregroundColor, selected) {
        return selected
            ? AppTextStyles.bodyPrimaryHeavy
            : AppTextStyles.bodyMutedStrong;
      },
      onChanged: (filter) => setState(() => _completionFilter = filter),
    );
  }

  Widget _buildHomeStyleAppBarTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(title, style: AppTextStyles.appBarHomeTitle),
    );
  }

  Widget _buildVillagerResidentSegment() {
    return AppSegmentedControl<_VillagerResidentFilter>(
      value: _villagerResidentFilter,
      items: _VillagerResidentFilter.values
          .map(
            (filter) => (
              value: filter,
              label: filter.label,
              icon: null,
              selectedColor: AppColors.textPrimary,
              semanticsLabel: filter.label,
            ),
          )
          .toList(growable: false),
      textStyleBuilder: (context, item, foregroundColor, selected) {
        return selected
            ? AppTextStyles.bodyPrimaryHeavy
            : AppTextStyles.bodyMutedStrong;
      },
      onChanged: (filter) => setState(() => _villagerResidentFilter = filter),
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
          final displayValue = selected == '전체' ? filter.label : selected;
          final hasSelection = selected != '전체';

          return _CatalogDropdownFilter(
            width: filter.width,
            valueLabel: displayValue,
            selected: hasSelection,
            onTap: () async {
              final value = await _showDropdownFilterBottomSheet(
                title: filter.label,
                options: options,
                selectedValue: selected,
              );
              if (value == null || !mounted) {
                return;
              }
              setState(() => _selectedDropdownValues[filter.key] = value);
            },
          );
        },
      ),
    );
  }

  Future<String?> _showDropdownFilterBottomSheet({
    required String title,
    required List<String> options,
    required String selectedValue,
  }) {
    // 유지보수 포인트:
    // 도감 필터 선택 UX를 드롭다운 대신 바텀 시트로 통일합니다.
    // 옵션 추가/정렬은 _buildDropdownOptions 에서만 관리하면 이 시트에 자동 반영됩니다.
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.62;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.modalInner,
                AppSpacing.s16,
                AppSpacing.modalInner,
                AppSpacing.modalInner,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyPrimaryHeavy,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, unused) =>
                          const Divider(height: 1, color: AppColors.navBorder),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == selectedValue;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                          ),
                          title: Text(
                            option,
                            style: isSelected
                                ? AppTextStyles.bodyPrimaryHeavy
                                : AppTextStyles.bodyPrimaryStrong,
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primaryDefault,
                                )
                              : null,
                          onTap: () => Navigator.of(sheetContext).pop(option),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          Text('아직 데이터가 없어요...', style: AppTextStyles.headingH2Secondary),
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

    if (widget.readOnly) {
      // 유지보수 포인트:
      // 비회원 모드에서는 저장 상태가 없으므로 상태 기반 필터를 건너뜁니다.
    } else if (widget.category == '주민') {
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
      backgroundColor: AppColors.transparent,
      builder: (_) {
        final currentStates = widget.readOnly
            ? const <String, CatalogUserState>{}
            : ref.read(
                catalogBindingViewModelProvider((
                  uid: widget.uid,
                  islandId: widget.islandId,
                )),
              );
        return CatalogItemDetailSheet(
          item: item,
          isCompleted: _isCompleted(item, currentStates),
          isFavorite: _isFavorite(item, currentStates),
          isDonationMode: donationMode,
          readOnly: widget.readOnly,
          initialMemo: currentStates[item.id]?.memo ?? '',
          onMemoSaved: widget.readOnly
              ? null
              : item.category == '주민'
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
            if (widget.readOnly) {
              return;
            }
            try {
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
            } catch (error) {
              if (mounted) {
                _showToast(_actionErrorMessage(error));
              }
              rethrow;
            }
          },
          onFavoriteChanged: (value) async {
            if (widget.readOnly) {
              return;
            }
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
            if (!mounted) {
              return;
            }
            _showToast(_favoriteToastMessage(item: item, favorite: value));
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
    try {
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
            donationMode: false,
            completed: next,
          );
    } catch (error) {
      if (mounted) {
        _showToast(_actionErrorMessage(error));
      }
      return;
    }
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
        .read(
          catalogBindingViewModelProvider((
            uid: widget.uid,
            islandId: widget.islandId,
          )).notifier,
        )
        .setFavorite(itemId: item.id, category: item.category, favorite: next);
    if (!mounted) {
      return;
    }
    _showToast(_favoriteToastMessage(item: item, favorite: next));
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

  String _actionErrorMessage(Object error) {
    if (error is ResidentLimitExceededException) {
      return error.message;
    }
    return '처리 중 오류가 발생했어요. 다시 시도해주세요.';
  }

  String _favoriteToastMessage({
    required CatalogItem item,
    required bool favorite,
  }) {
    if (item.category == '주민') {
      return favorite ? '선호 주민으로 등록했어요.' : '선호 주민 해제했어요.';
    }
    return favorite ? '위시 리스트에 추가했어요.' : '위시 리스트에서 제거했어요.';
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
    required this.showVillagerActions,
  });

  final CatalogItem item;
  final bool completed;
  final bool favorite;
  final bool donationMode;
  final VoidCallback onTap;
  final VoidCallback? onToggleResident;
  final VoidCallback? onToggleFavorite;
  final bool showVillagerActions;

  @override
  Widget build(BuildContext context) {
    final rare = _isRare(item.tags);
    final isVillager = item.category == '주민';
    final hideCategoryBadge =
        item.category == '해산물' ||
        item.category == '화석' ||
        item.category == '미술품';
    final tag1 = _resolvePrimaryTag(item.tags) ?? item.category;
    final speciesLabel = isVillager
        ? (_extractPrefixedTagValue(item.tags, '종') ?? tag1)
        : tag1;
    final habitatLabel = isVillager
        ? null
        : _extractPrefixedTagValue(item.tags, '서식처');
    final habitatBadgeStyle =
        habitatLabel == null || habitatLabel != speciesLabel
        ? null
        : CatalogBadgePalette.resolveHabitat(habitatLabel);
    final personality = isVillager
        ? _extractPrefixedTagValue(item.tags, '성격')
        : null;
    final artAuthenticity = item.category == '미술품'
        ? CatalogBadgePalette.resolveArtAuthenticity(item.tags)
        : null;
    final personalityBadgeStyle = personality == null
        ? null
        : CatalogBadgePalette.resolveVillagerPersonality(personality);
    final statusStyle = _StatusStyle.resolve(
      completed: completed,
      donationMode: donationMode,
    );

    return AppInkWell(
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
                          style: AppTextStyles.headingH2,
                        ),
                      ),
                      if (rare)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.badgeRedBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '희귀종',
                            style: AppTextStyles.bodyWithSize(
                              13,
                              color: AppColors.badgeRedText,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (!hideCategoryBadge)
                        _SmallBadge(
                          label: speciesLabel,
                          background:
                              habitatBadgeStyle?.background ??
                              AppColors.transparent,
                          foreground:
                              habitatBadgeStyle?.foreground ??
                              AppColors.textMuted,
                        ),
                      if (isVillager && personality != null)
                        _SmallBadge(
                          label: personality,
                          background: personalityBadgeStyle!.background,
                          foreground: personalityBadgeStyle.foreground,
                        ),
                      if (artAuthenticity != null)
                        _SmallBadge(
                          label: artAuthenticity.label,
                          background: artAuthenticity.background,
                          foreground: artAuthenticity.foreground,
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
            if (isVillager && showVillagerActions) ...<Widget>[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _QuickIconToggleButton(
                    icon: Icons.home_rounded,
                    semanticLabel: completed ? '거주중' : '거주 선택',
                    selected: completed,
                    selectedBackground: AppColors.textPrimary.withValues(
                      alpha: 0.3,
                    ),
                    selectedForeground: AppColors.textPrimary,
                    onTap: onToggleResident,
                  ),
                  _QuickIconToggleButton(
                    icon: Icons.favorite_rounded,
                    semanticLabel: favorite ? '선호중' : '선호 선택',
                    selected: favorite,
                    selectedBackground: Colors.red.withValues(alpha: 0.3),
                    selectedForeground: Colors.red,
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

  String? _extractPrefixedTagValue(List<String> tags, String prefix) {
    final key = '$prefix:';
    for (final tag in tags) {
      if (!tag.startsWith(key)) {
        continue;
      }
      final value = tag.substring(key.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
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
      child: Text(label, style: AppTextStyles.captionWithColor(foreground)),
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
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          foregroundColor: selected ? selectedForeground : AppColors.textMuted,
          backgroundColor: selected
              ? selectedBackground
              : AppColors.catalogChipBg,
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
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
    required this.valueLabel,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String valueLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(999),
        child: AppInkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    valueLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyWithSize(
                      14,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      weight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ],
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
              background: AppColors.accentDeepOrange,
              foreground: AppColors.white,
            )
          : const _StatusStyle(
              background: AppColors.navActiveBg,
              foreground: AppColors.textSecondary,
            );
    }

    return completed
        ? const _StatusStyle(
            background: Color(0xffE1FFF4),
            foreground: AppColors.primaryPressed,
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
