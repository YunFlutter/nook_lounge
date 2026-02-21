import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/animation/app_motion.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_collection_page.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';

class CatalogDashboardTab extends ConsumerStatefulWidget {
  const CatalogDashboardTab({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<CatalogDashboardTab> createState() =>
      _CatalogDashboardTabState();
}

class _CatalogDashboardTabState extends ConsumerState<CatalogDashboardTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CatalogItem> _items = const <CatalogItem>[];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ref.read(catalogRepositoryProvider).loadAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '도감 데이터를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(catalogBindingViewModelProvider(widget.uid));

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.s10),
              FilledButton(onPressed: _loadCatalog, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.catalogHorizontal,
          AppSpacing.s10,
          AppSpacing.catalogHorizontal,
          AppSpacing.s10 * 2,
        ),
        children: <Widget>[
          _buildVillagerSection(context, overrides),
          const SizedBox(height: AppSpacing.s10 * 2),
          _buildMuseumSection(context, overrides),
          const SizedBox(height: AppSpacing.s10 * 2),
          _buildCollectionSection(context, overrides),
        ],
      ),
    );
  }

  Widget _buildVillagerSection(
    BuildContext context,
    Map<String, CatalogUserState> userStates,
  ) {
    final villagers = _items
        .where((item) => item.category == '주민')
        .where(
          (item) => resolveCatalogCompleted(item: item, userStates: userStates),
        )
        .take(8)
        .toList(growable: false);
    final hasResidentVillagers = villagers.isNotEmpty;

    return AnimatedFadeSlide(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitleRow(
            title: '섬 주민들',
            onTap: () => _openCategoryPage(
              context,
              title: '주민 도감',
              category: '주민',
              allItems: _items,
            ),
          ),
          if (hasResidentVillagers) ...<Widget>[
            const SizedBox(height: AppSpacing.s10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: villagers.length,
                separatorBuilder: (_, unused) =>
                    const SizedBox(width: AppSpacing.s10),
                itemBuilder: (context, index) {
                  final item = villagers[index];
                  return _VillagerAvatarItem(
                    item: item,
                    onTap: () => _openVillagerDetailSheet(
                      item: item,
                      userStates: userStates,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuseumSection(
    BuildContext context,
    Map<String, CatalogUserState> userStates,
  ) {
    final data = <_ProgressCardData>[
      _buildProgressCardData(
        label: '곤충',
        category: '곤충',
        iconAssetPath: 'assets/images/icon_ladybug_with_shell.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '물고기',
        category: '물고기',
        iconAssetPath: 'assets/images/icon_blue_fish.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '해산물',
        category: '해산물',
        iconAssetPath: 'assets/images/icon_shell_with_seaweed.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '화석',
        category: '화석',
        iconAssetPath: 'assets/images/icon_skull_in_rock.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '미술품',
        category: '미술품',
        iconAssetPath: 'assets/images/icon_landscape_painting_frame.png',
        userStates: userStates,
      ),
    ];

    return AnimatedFadeSlide(
      delay: const Duration(milliseconds: 40),
      child: _ProgressSection(
        title: '박물관 기증 진행률',
        icon: Icons.account_balance,
        cards: data,
        onViewAll: () => _openCategoryPage(
          context,
          title: '물고기 도감',
          category: '물고기',
          allItems: _items,
        ),
        onCardTap: (card) => _openCategoryPage(
          context,
          title: '${card.label} 도감',
          category: card.category,
          allItems: _items,
        ),
      ),
    );
  }

  Widget _buildCollectionSection(
    BuildContext context,
    Map<String, CatalogUserState> userStates,
  ) {
    final data = <_ProgressCardData>[
      _buildProgressCardData(
        label: '패션',
        category: '패션',
        iconAssetPath: 'assets/images/icon_teddy_bear_with_plant.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '레시피',
        category: '레시피',
        iconAssetPath: 'assets/images/icon_open_recipe_book.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '가구',
        category: '가구',
        iconAssetPath: 'assets/images/icon_striped_armchair_side_table.png',
        userStates: userStates,
      ),
      _buildProgressCardData(
        label: '벽지 등',
        category: '아이템',
        iconAssetPath: 'assets/images/icon_mountain_pattern_square.png',
        userStates: userStates,
      ),
    ];

    return AnimatedFadeSlide(
      delay: const Duration(milliseconds: 70),
      child: _ProgressSection(
        title: '수집 진행률',
        icon: Icons.inventory_2,
        cards: data,
        onViewAll: () => _openCategoryPage(
          context,
          title: '패션 도감',
          category: '패션',
          allItems: _items,
        ),
        onCardTap: (card) => _openCategoryPage(
          context,
          title: '${card.label} 도감',
          category: card.category,
          allItems: _items,
        ),
      ),
    );
  }

  _ProgressCardData _buildProgressCardData({
    required String label,
    required String category,
    required String iconAssetPath,
    required Map<String, CatalogUserState> userStates,
  }) {
    final categoryItems = _items
        .where((item) => item.category == category)
        .toList(growable: false);
    final total = categoryItems.length;
    final completed = resolveCatalogCompletedCount(
      category: category,
      items: categoryItems,
      userStates: userStates,
    );

    final percent = total == 0 ? 0.0 : completed / total;
    return _ProgressCardData(
      label: label,
      category: category,
      iconAssetPath: iconAssetPath,
      completed: completed,
      total: total,
      percent: percent,
    );
  }

  void _openCategoryPage(
    BuildContext context, {
    required String title,
    required String category,
    required List<CatalogItem> allItems,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.screen,
        reverseTransitionDuration: AppMotion.screen,
        pageBuilder: (_, animation, secondaryAnimation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasized,
          );
          return FadeTransition(
            opacity: curved,
            child: CatalogCollectionPage(
              uid: widget.uid,
              title: title,
              category: category,
              allItems: allItems,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openVillagerDetailSheet({
    required CatalogItem item,
    required Map<String, CatalogUserState> userStates,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CatalogItemDetailSheet(
          item: item,
          isCompleted: _isResident(item, userStates),
          isFavorite: _isFavorite(item, userStates),
          isDonationMode: false,
          onCompletedChanged: (value) async {
            await ref
                .read(catalogBindingViewModelProvider(widget.uid).notifier)
                .setCompleted(
                  itemId: item.id,
                  category: item.category,
                  donationMode: false,
                  completed: value,
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
          },
        );
      },
    );
  }

  bool _isResident(CatalogItem item, Map<String, CatalogUserState> userStates) {
    return userStates[item.id]?.owned ?? false;
  }

  bool _isFavorite(CatalogItem item, Map<String, CatalogUserState> userStates) {
    return userStates[item.id]?.favorite ?? false;
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDefault,
            minimumSize: const Size(0, 0),
            padding: EdgeInsets.zero,
          ),
          child: const Text('전체보기'),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.title,
    required this.icon,
    required this.cards,
    required this.onViewAll,
    required this.onCardTap,
  });

  final String title;
  final IconData icon;
  final List<_ProgressCardData> cards;
  final VoidCallback onViewAll;
  final ValueChanged<_ProgressCardData> onCardTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDefault,
                minimumSize: const Size(0, 0),
                padding: EdgeInsets.zero,
              ),
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s10),
        Wrap(
          spacing: AppSpacing.s10,
          runSpacing: AppSpacing.s10,
          children: cards
              .map(
                (card) => _ProgressCircleCard(
                  data: card,
                  onTap: () => onCardTap(card),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ProgressCircleCard extends StatelessWidget {
  const _ProgressCircleCard({required this.data, required this.onTap});

  final _ProgressCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 30) / 2;
    final percentLabel = '${(data.percent * 100).round()} %';

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s10),
          decoration: BoxDecoration(
            color: AppColors.catalogCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.catalogChipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${data.completed}/${data.total}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s10),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: _DonutImageChart(
                    imageAssetPath: data.iconAssetPath,
                    percent: data.percent,
                    percentLabel: percentLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VillagerAvatarItem extends StatelessWidget {
  const _VillagerAvatarItem({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: item.imageUrl.isEmpty
                      ? Image.asset(
                          'assets/images/icon_raccoon_character.png',
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'assets/images/icon_raccoon_character.png',
                                fit: BoxFit.contain,
                              ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutImageChart extends StatelessWidget {
  const _DonutImageChart({
    required this.imageAssetPath,
    required this.percent,
    required this.percentLabel,
  });

  final String imageAssetPath;
  final double percent;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            painter: _DonutRingPainter(progress: clampedPercent),
          ),
        ),
        Container(
          width: 98,
          height: 98,
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                imageAssetPath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                percentLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutRingPainter extends CustomPainter {
  const _DonutRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final trackPaint = Paint()
      ..color = AppColors.catalogProgressTrack
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    final progressPaint = Paint()
      ..color = AppColors.catalogProgressAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (math.pi * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ProgressCardData {
  const _ProgressCardData({
    required this.label,
    required this.category,
    required this.iconAssetPath,
    required this.completed,
    required this.total,
    required this.percent,
  });

  final String label;
  final String category;
  final String iconAssetPath;
  final int completed;
  final int total;
  final double percent;
}
