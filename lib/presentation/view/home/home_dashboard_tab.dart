import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/state/turnip_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_collection_page.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_legend_dot.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_chart.dart';

final homeDashboardCatalogProvider = FutureProvider.autoDispose
    .family<List<CatalogItem>, String>((ref, uid) async {
      return ref.watch(catalogRepositoryProvider).loadAll();
    });

final homeDashboardIslandsProvider = StreamProvider.autoDispose
    .family<List<IslandProfile>, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchIslands(uid);
    });

final homeDashboardPrimaryIslandIdProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchPrimaryIslandId(uid);
    });

final homeGateOpenedProvider = StateProvider.autoDispose.family<bool, String>(
  (ref, islandId) => false,
);

IslandProfile? resolveHomeSelectedIsland({
  required List<IslandProfile> islands,
  required String? primaryIslandId,
}) {
  if (islands.isEmpty) {
    return null;
  }
  if (primaryIslandId == null || primaryIslandId.isEmpty) {
    return islands.first;
  }
  for (final island in islands) {
    if (island.id == primaryIslandId) {
      return island;
    }
  }
  return islands.first;
}

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({required this.uid, super.key});

  final String uid;

  static const Map<String, String> _fruitEmojiByName = <String, String>{
    '사과': '🍎',
    '체리': '🍒',
    '오렌지': '🍊',
    '복숭아': '🍑',
    '배': '🍐',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(homeDashboardCatalogProvider(uid));
    final islandsAsync = ref.watch(homeDashboardIslandsProvider(uid));
    final primaryIslandIdAsync = ref.watch(
      homeDashboardPrimaryIslandIdProvider(uid),
    );
    final islands = islandsAsync.valueOrNull ?? const <IslandProfile>[];
    final selectedIsland = resolveHomeSelectedIsland(
      islands: islands,
      primaryIslandId: primaryIslandIdAsync.valueOrNull,
    );
    final currentIslandId =
        selectedIsland?.id ?? primaryIslandIdAsync.valueOrNull ?? '';
    final turnipState = ref.watch(
      turnipViewModelProvider((uid: uid, islandId: currentIslandId)),
    );
    final userStates = ref.watch(
      catalogBindingViewModelProvider((uid: uid, islandId: currentIslandId)),
    );
    final items = catalogAsync.valueOrNull ?? const <CatalogItem>[];

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          AppSpacing.s10 * 2,
        ),
        children: <Widget>[
          AnimatedFadeSlide(
            child: _buildIslandHeroCard(
              context: context,
              ref: ref,
              selectedIsland: selectedIsland,
              loading: islandsAsync.isLoading || primaryIslandIdAsync.isLoading,
              hasError: islandsAsync.hasError || primaryIslandIdAsync.hasError,
            ),
          ),
          const SizedBox(height: AppSpacing.s10 * 2),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 40),
            child: _buildResidentSection(
              context: context,
              ref: ref,
              currentIslandId: currentIslandId,
              items: items,
              userStates: userStates,
              loading: catalogAsync.isLoading,
              hasError: catalogAsync.hasError,
            ),
          ),
          const SizedBox(height: AppSpacing.s10 * 2),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 80),
            child: _buildTurnipSection(
              context: context,
              ref: ref,
              turnipState: turnipState,
            ),
          ),
          const SizedBox(height: AppSpacing.s10 * 2),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 120),
            child: _buildCatalogProgressSection(
              context: context,
              ref: ref,
              currentIslandId: currentIslandId,
              items: items,
              userStates: userStates,
              loading: catalogAsync.isLoading,
              hasError: catalogAsync.hasError,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(homeDashboardCatalogProvider(uid));
    ref.invalidate(homeDashboardIslandsProvider(uid));
    ref.invalidate(homeDashboardPrimaryIslandIdProvider(uid));
    await Future.wait<void>(<Future<void>>[
      ref.read(homeDashboardCatalogProvider(uid).future).then((_) {}),
      ref.read(homeDashboardIslandsProvider(uid).future).then((_) {}),
      ref.read(homeDashboardPrimaryIslandIdProvider(uid).future).then((_) {}),
    ]);
  }

  Widget _buildIslandHeroCard({
    required BuildContext context,
    required WidgetRef ref,
    required IslandProfile? selectedIsland,
    required bool loading,
    required bool hasError,
  }) {
    final content = loading
        ? const SizedBox(
            height: 84,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : hasError
        ? const Text(
            '섬 정보를 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
        : selectedIsland == null
        ? const Text(
            '등록된 섬이 없어요.\n새 섬을 추가해서 시작해보세요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          )
        : _buildIslandHeroContent(
            context: context,
            ref: ref,
            island: selectedIsland,
          );

    return Column(
      children: <Widget>[
        content,
        const SizedBox(height: 14),
        Container(height: 1, color: AppColors.borderDefault),
      ],
    );
  }

  Widget _buildIslandHeroContent({
    required BuildContext context,
    required WidgetRef ref,
    required IslandProfile island,
  }) {
    final gateOpen = ref.watch(homeGateOpenedProvider(island.id));
    final gateNotifier = ref.read(homeGateOpenedProvider(island.id).notifier);
    final fruitEmoji = _fruitEmojiByName[island.nativeFruit] ?? '🍑';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ClipOval(
          child: Container(
            width: 78,
            height: 78,
            color: AppColors.bgSecondary,
            child: _buildNetworkImage(island.imageUrl),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      island.islandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 40 / 2, // 20
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    fruitEmoji,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  _buildHemisphereBadge(island.hemisphere),
                  const SizedBox(width: 10),
                  _buildGatePillToggle(
                    gateOpen: gateOpen,
                    onTap: () => gateNotifier.state = !gateOpen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHemisphereBadge(String hemisphere) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.badgeBlueBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.explore_outlined,
            size: 15,
            color: AppColors.badgeYellowText,
          ),
          const SizedBox(width: 6),
          Text(
            hemisphere,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatePillToggle({
    required bool gateOpen,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      toggled: gateOpen,
      label: '비행장 방문 개방 토글',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 112,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: gateOpen ? AppColors.badgeBlueBg : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _AirportToggleTrackPainter(gateOpen: gateOpen),
                  ),
                ),
              ),
              if (gateOpen)
                const Positioned(
                  left: 12,
                  top: 11,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 14,
                    color: AppColors.bgCard,
                  ),
                ),
              if (gateOpen)
                const Positioned(
                  left: 28,
                  top: 7,
                  child: Icon(
                    Icons.cloud_rounded,
                    size: 16,
                    color: AppColors.bgCard,
                  ),
                ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: gateOpen
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderDefault),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flight_rounded,
                    size: 20,
                    color: AppColors.borderStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentSection({
    required BuildContext context,
    required WidgetRef ref,
    required String currentIslandId,
    required List<CatalogItem> items,
    required Map<String, CatalogUserState> userStates,
    required bool loading,
    required bool hasError,
  }) {
    final residents = items
        .where((item) => item.category == '주민')
        .where(
          (item) => resolveCatalogCompleted(item: item, userStates: userStates),
        )
        .take(10)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          context: context,
          title: '우리 섬 주민들',
          onTap: () async {
            if (items.isEmpty) {
              return;
            }
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CatalogCollectionPage(
                  uid: uid,
                  islandId: currentIslandId,
                  title: '우리 섬 주민들',
                  category: '주민',
                  allItems: items,
                  startWithResidentFilter: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        if (loading)
          const SizedBox(
            height: 82,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (hasError)
          const Text(
            '주민 정보를 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (residents.isEmpty)
          const Text(
            '아직 거주 주민이 없어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: residents.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = residents[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openResidentDetailSheet(
                    context: context,
                    ref: ref,
                    islandId: currentIslandId,
                    item: item,
                    userStates: userStates,
                  ),
                  child: SizedBox(
                    width: 84,
                    child: Column(
                      children: <Widget>[
                        ClipOval(
                          child: Container(
                            width: 70,
                            height: 70,
                            color: AppColors.bgSecondary,
                            child: _buildNetworkImage(
                              _resolveResidentThumbUrl(item),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTurnipSection({
    required BuildContext context,
    required WidgetRef ref,
    required TurnipViewState turnipState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          context: context,
          title: '무주식',
          onTap: () =>
              ref.read(homeShellViewModelProvider.notifier).changeTab(4),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.catalogCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Builder(
            builder: (context) {
              if (turnipState.isLoading) {
                return const SizedBox(
                  height: 82,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final prediction = turnipState.prediction;
              if (prediction == null) {
                final message =
                    turnipState.errorMessage ??
                    '입력된 무주식 데이터가 없어요.\n무주식 탭에서 계산 후 결과를 확인해보세요.';
                return Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                );
              }

              final minValues = _buildDailySeries(
                prediction.minMaxPattern,
                useMin: true,
              );
              final maxValues = _buildDailySeries(
                prediction.minMaxPattern,
                useMin: false,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '예측 결과',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          TurnipLegendDot(
                            color: AppColors.badgeYellowText,
                            label: '최소',
                          ),
                          SizedBox(width: 8),
                          TurnipLegendDot(
                            color: AppColors.primaryDefault,
                            label: '최대',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '입력된 정보를 기반으로 한 결과입니다.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TurnipPredictionChart(
                    minValues: minValues,
                    maxValues: maxValues,
                    peakDayIndex: (prediction.peakIndex / 2).floor(),
                    peakLabel: _slotLabel(prediction.peakIndex),
                    peakValue: prediction.peakMaxValue,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogProgressSection({
    required BuildContext context,
    required WidgetRef ref,
    required String currentIslandId,
    required List<CatalogItem> items,
    required Map<String, CatalogUserState> userStates,
    required bool loading,
    required bool hasError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          context: context,
          title: '도감 진행률',
          onTap: () =>
              ref.read(homeShellViewModelProvider.notifier).changeTab(3),
        ),
        const SizedBox(height: 10),
        if (loading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (hasError)
          const Text(
            '도감 진행률을 불러오지 못했어요.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.98,
            children: <Widget>[
              _buildProgressDonutCard(
                context: context,
                title: '곤충',
                uid: uid,
                islandId: currentIslandId,
                items: items,
                iconAssetPath: 'assets/images/icon_ladybug_with_shell.png',
                completed: _completedCount('곤충', items, userStates),
                total: _countByCategory('곤충', items),
              ),
              _buildProgressDonutCard(
                context: context,
                title: '물고기',
                uid: uid,
                islandId: currentIslandId,
                items: items,
                iconAssetPath: 'assets/images/icon_blue_fish.png',
                completed: _completedCount('물고기', items, userStates),
                total: _countByCategory('물고기', items),
              ),
              _buildProgressDonutCard(
                context: context,
                title: '해산물',
                uid: uid,
                islandId: currentIslandId,
                items: items,
                iconAssetPath: 'assets/images/icon_shell_with_seaweed.png',
                completed: _completedCount('해산물', items, userStates),
                total: _countByCategory('해산물', items),
              ),
              _buildProgressDonutCard(
                context: context,
                title: '미술품',
                uid: uid,
                islandId: currentIslandId,
                items: items,
                iconAssetPath:
                    'assets/images/icon_landscape_painting_frame.png',
                completed: _completedCount('미술품', items, userStates),
                total: _countByCategory('미술품', items),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProgressDonutCard({
    required BuildContext context,
    required String uid,
    required String islandId,
    required List<CatalogItem> items,
    required String title,
    required String iconAssetPath,
    required int completed,
    required int total,
  }) {
    final progress = _safeProgress(completed, total);
    final percentage = (progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CatalogCollectionPage(
                uid: uid,
                islandId: islandId,
                title: '$title 도감',
                category: title,
                allItems: items,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.catalogCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.catalogChipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$completed/$total',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 11,
                          color: AppColors.catalogProgressTrack,
                        ),
                      ),
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 11,
                          color: AppColors.catalogProgressAccent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(
                            iconAssetPath,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDefault,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('전체보기'),
        ),
      ],
    );
  }

  Future<void> _openResidentDetailSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String islandId,
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
          isCompleted: resolveCatalogCompleted(
            item: item,
            userStates: userStates,
          ),
          isFavorite: userStates[item.id]?.favorite ?? false,
          isDonationMode: false,
          initialMemo: userStates[item.id]?.memo ?? '',
          onMemoSaved: (memo) async {
            await ref
                .read(
                  catalogBindingViewModelProvider((
                    uid: uid,
                    islandId: islandId,
                  )).notifier,
                )
                .setVillagerMemo(
                  itemId: item.id,
                  category: item.category,
                  memo: memo,
                );
          },
          onCompletedChanged: (value) async {
            await ref
                .read(
                  catalogBindingViewModelProvider((
                    uid: uid,
                    islandId: islandId,
                  )).notifier,
                )
                .setCompleted(
                  itemId: item.id,
                  category: item.category,
                  donationMode: false,
                  completed: value,
                );
          },
          onFavoriteChanged: (value) async {
            await ref
                .read(
                  catalogBindingViewModelProvider((
                    uid: uid,
                    islandId: islandId,
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

  Widget _buildNetworkImage(String? url) {
    if (url == null || url.isEmpty) {
      return Image.asset(
        'assets/images/icon_raccoon_character.png',
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/icon_raccoon_character.png',
          fit: BoxFit.cover,
        );
      },
    );
  }

  String _resolveResidentThumbUrl(CatalogItem item) {
    if (item.category != '주민') {
      return item.imageUrl;
    }

    // 유지보수 포인트:
    // 홈 "우리 섬 주민들" 영역은 nh_details의 아이콘 이미지를 우선 노출합니다.
    // 파서에서 태그화한 아이콘URL/주민사진URL이 없을 때만 기본 imageUrl로 폴백합니다.
    final iconUrl = _extractTagValue(item.tags, '아이콘URL');
    if (iconUrl.isNotEmpty) {
      return iconUrl;
    }

    final photoUrl = _extractTagValue(item.tags, '주민사진URL');
    if (photoUrl.isNotEmpty) {
      return photoUrl;
    }

    return item.imageUrl;
  }

  String _extractTagValue(List<String> tags, String prefix) {
    final needle = '$prefix:';
    for (final tag in tags) {
      if (!tag.startsWith(needle)) {
        continue;
      }
      final value = tag.substring(needle.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  int _completedCount(
    String category,
    List<CatalogItem> items,
    Map<String, CatalogUserState> userStates,
  ) {
    return resolveCatalogCompletedCount(
      category: category,
      items: items.where((item) => item.category == category).toList(),
      userStates: userStates,
    );
  }

  int _countByCategory(String category, List<CatalogItem> items) {
    return items.where((item) => item.category == category).length;
  }

  double _safeProgress(int done, int total) {
    if (total <= 0) {
      return 0;
    }
    return math.min(done / total, 1);
  }

  static List<int> _buildDailySeries(
    List<List<int>> minMaxPattern, {
    required bool useMin,
  }) {
    if (minMaxPattern.length < 12) {
      return minMaxPattern
          .take(6)
          .map((value) => _readValue(value, useMin))
          .toList(growable: false);
    }

    final result = <int>[];
    for (var day = 0; day < 6; day++) {
      result.add(_readValue(minMaxPattern[day * 2], useMin));
    }
    return result;
  }

  static int _readValue(List<int> point, bool useMin) {
    if (point.isEmpty) {
      return 0;
    }
    if (useMin) {
      return point.first;
    }
    if (point.length >= 2) {
      return point[1];
    }
    return point.first;
  }

  static String _slotLabel(int index) {
    const days = <String>['월', '화', '수', '목', '금', '토'];
    final dayIndex = (index / 2).floor().clamp(0, 5);
    final isAfternoon = index.isOdd;
    return '${days[dayIndex]}요일 ${isAfternoon ? '오후' : '오전'}';
  }
}

class _AirportToggleTrackPainter extends CustomPainter {
  const _AirportToggleTrackPainter({required this.gateOpen});

  final bool gateOpen;

  @override
  void paint(Canvas canvas, Size size) {
    if (gateOpen) {
      return;
    }

    final paint = Paint()
      ..color = AppColors.bgCard.withValues(alpha: 0.35)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    // 유지보수 포인트:
    // OFF 상태는 Figma 시안처럼 가는 가로 라인이 반복되는 패턴을 사용합니다.
    const gap = 5.0;
    const lineLength = 17.0;
    var y = size.height * 0.25;
    while (y < size.height * 0.75) {
      var x = 8.0;
      while (x < size.width - 8) {
        final end = math.min(x + lineLength, size.width - 8);
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x += lineLength + gap;
      }
      y += 6.0;
    }
  }

  @override
  bool shouldRepaint(covariant _AirportToggleTrackPainter oldDelegate) {
    return oldDelegate.gateOpen != gateOpen;
  }
}
