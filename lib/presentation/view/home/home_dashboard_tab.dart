import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_view.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/state/turnip_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_collection_page.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_completion_resolver.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_item_detail_sheet.dart';
import 'package:nook_lounge_app/presentation/view/airport/widgets/airport_gate_pill_toggle.dart';
import 'package:nook_lounge_app/presentation/view/common/app_owl_empty_state.dart';
import 'package:nook_lounge_app/presentation/view/home/wish_list_page.dart';
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
  // 유지보수 포인트:
  // 주민 슬롯 수는 주민 최대 거주 가능 수(10명)와 동일해야 합니다.
  // 홈 UI 슬롯 수와 저장 제한이 어긋나지 않도록 함께 관리해 주세요.
  static const int _residentSlotCount = 10;
  static const double _residentSlotListHeight = 104;
  static const double _residentSlotWidth = 84;
  static const double _residentAvatarSize = 70;
  // 유지보수 포인트:
  // 무주식 빈 상태 CTA 색상/사이즈는 Figma(603:12282) 기준으로 잡았습니다.
  // 디자인 변경 시 아래 토큰만 수정하면 홈 빈 카드가 함께 반영됩니다.
  static const Color _turnipEmptyCtaColor = Color(0xFF72D7B2);
  static const Color _turnipEmptyCtaShadowColor = Color(0x1A000000);
  static const double _turnipEmptyMinHeight = 300;
  static const double _turnipEmptyButtonWidth = 288;
  static const double _turnipEmptyButtonHeight = 56;
  static const double _turnipEmptyButtonRadius = 30;
  static const String _noDataImageAssetPath = 'assets/images/no_data_image.png';

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

    return AppScreenView(
      screenName: AppScreenNames.homeDashboard,
      child: RefreshIndicator(
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
                loading:
                    islandsAsync.isLoading || primaryIslandIdAsync.isLoading,
                hasError:
                    islandsAsync.hasError || primaryIslandIdAsync.hasError,
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
            const SizedBox(height: AppSpacing.s10 * 2),
            AnimatedFadeSlide(
              delay: const Duration(milliseconds: 160),
              child: _buildWishListSection(
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
        ? Text('섬 정보를 불러오지 못했어요.', style: AppTextStyles.bodySecondaryStrong)
        : selectedIsland == null
        ? const AppOwlEmptyState(
            useCard: false,
            imageSize: 72,
            title: '등록된 섬이 없어요.',
            subtitle: '새 섬을 추가해서 시작해보세요.',
          )
        : _buildIslandHeroContent(
            context: context,
            ref: ref,
            island: selectedIsland,
          );

    return Column(
      children: <Widget>[
        content,
        const SizedBox(height: AppSpacing.s14),
        Container(height: 1, color: AppColors.borderDefault),
      ],
    );
  }

  Widget _buildIslandHeroContent({
    required BuildContext context,
    required WidgetRef ref,
    required IslandProfile island,
  }) {
    final airportArgs = (uid: uid, islandId: island.id);
    final airportState = ref.watch(airportViewModelProvider(airportArgs));
    final gateOpen = airportState.session?.gateOpen ?? false;
    final fruitEmoji = _fruitEmojiByName[island.nativeFruit] ?? '🍑';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 20),
          offset: const Offset(-0.08, 0),
          child: ClipOval(
            child: Container(
              width: 90,
              height: 90,
              color: AppColors.bgSecondary,
              child: _buildNetworkImage(island.imageUrl),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s14),
        Expanded(
          child: AnimatedFadeSlide(
            delay: const Duration(milliseconds: 55),
            offset: const Offset(0.08, 0),
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
                        style: AppTextStyles.bodyWithSize(
                          24,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      fruitEmoji,
                      style: AppTextStyles.bodyWithSize(
                        20,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s10),
                Row(
                  children: <Widget>[
                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 75),
                      child: _buildHemisphereBadge(island.hemisphere),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 95),
                      child: AirportGatePillToggle(
                        gateOpen: gateOpen,
                        onTap: () {
                          unawaited(
                            _toggleGateFromHome(
                              ref: ref,
                              island: island,
                              gateOpen: gateOpen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHemisphereBadge(String hemisphere) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      decoration: BoxDecoration(
        color: hemisphere == '북반구'
            ? AppColors.badgeBlueBg
            : AppColors.accentOrange,
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
          const SizedBox(width: AppSpacing.s6),
          Text(
            hemisphere,
            style: AppTextStyles.bodyWithSize(
              14,
              color: AppColors.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleGateFromHome({
    required WidgetRef ref,
    required IslandProfile island,
    required bool gateOpen,
  }) async {
    final args = (uid: uid, islandId: island.id);
    final airportState = ref.read(airportViewModelProvider(args));
    final airportViewModel = ref.read(airportViewModelProvider(args).notifier);

    if (airportState.session == null) {
      // 유지보수 포인트:
      // 홈에서 처음 토글하는 경우에도 비행장 탭과 동일한 세션 문서를 먼저 보장합니다.
      await airportViewModel.ensureSession(
        islandName: island.islandName,
        hostName: island.representativeName,
        hostAvatarUrl: island.imageUrl ?? '',
        islandImageUrl: island.imageUrl ?? '',
      );
    }

    await airportViewModel.toggleGateOpen(!gateOpen);
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
        .take(_residentSlotCount)
        .toList(growable: false);
    final residentSlots = List<CatalogItem?>.generate(
      _residentSlotCount,
      (index) => index < residents.length ? residents[index] : null,
      growable: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          context: context,
          title: '우리 섬 주민들',
          onTap: () async {
            await _openResidentCollectionPage(
              context: context,
              islandId: currentIslandId,
              items: items,
            );
          },
        ),
        const SizedBox(height: AppSpacing.s10),
        if (loading)
          const SizedBox(
            height: 82,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (hasError)
          Text('주민 정보를 불러오지 못했어요.', style: AppTextStyles.bodySecondaryStrong)
        else
          SizedBox(
            height: _residentSlotListHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: residentSlots.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(width: AppSpacing.s12),
              itemBuilder: (context, index) {
                final item = residentSlots[index];
                return AnimatedFadeSlide(
                  delay: Duration(milliseconds: 30 + (index * 24)),
                  offset: const Offset(0.06, 0),
                  child: item == null
                      ? _buildResidentEmptySlot(
                          context: context,
                          islandId: currentIslandId,
                          items: items,
                          slotIndex: index,
                        )
                      : _buildResidentFilledSlot(
                          context: context,
                          ref: ref,
                          islandId: currentIslandId,
                          item: item,
                          userStates: userStates,
                          slotIndex: index,
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
        const SizedBox(height: AppSpacing.s10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s20,
            AppSpacing.s14,
          ),
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
                return _buildTurnipEmptyCard(
                  ref: ref,
                  errorMessage: turnipState.errorMessage,
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
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('예측 결과', style: AppTextStyles.headingH2),
                        const Row(
                          children: <Widget>[
                            TurnipLegendDot(
                              color: AppColors.turnipPredictionMinLine,
                              label: '최소',
                            ),
                            SizedBox(width: AppSpacing.s8),
                            TurnipLegendDot(
                              color: AppColors.turnipPredictionMaxLine,
                              label: '최대',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 45),
                    child: Text(
                      '입력된 정보를 기반으로 한 결과입니다.',
                      style: AppTextStyles.captionMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 60),
                    child: TurnipPredictionChart(
                      minValues: minValues,
                      maxValues: maxValues,
                      peakDayIndex: (prediction.peakIndex / 2).floor(),
                      peakLabel: _slotLabel(prediction.peakIndex),
                      peakValue: prediction.peakMaxValue,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTurnipEmptyCard({
    required WidgetRef ref,
    required String? errorMessage,
  }) {
    final hasError = errorMessage != null && errorMessage.trim().isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _turnipEmptyMinHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '예측 결과',
            // 유지보수 포인트:
            // 홈 무주식 카드 헤더는 무주식 본문 결과 카드와 같은 토큰을 써야
            // 폰트 크기/두께가 화면별로 따로 어긋나지 않습니다.
            style: AppTextStyles.headingH2,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text('입력된 정보를 기반으로 한 결과입니다.', style: AppTextStyles.captionMuted),
          if (hasError) ...<Widget>[
            const SizedBox(height: AppSpacing.s6),
            Text(
              errorMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyWithSize(
                12,
                color: AppColors.accentDeepOrange,
                weight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          const Center(
            child: AppOwlEmptyState(
              useCard: false,
              title: '데이터가 없어요.',
              subtitle: '무 가격을 입력하고 계산해 주세요.',
              imageSemanticLabel: '무주식 데이터 없음 이미지',
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = math.min(
                  _turnipEmptyButtonWidth,
                  constraints.maxWidth,
                );
                return SizedBox(
                  width: buttonWidth,
                  height: _turnipEmptyButtonHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        _turnipEmptyButtonRadius,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _turnipEmptyCtaShadowColor,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(homeShellViewModelProvider.notifier)
                          .changeTab(4),
                      style: ElevatedButton.styleFrom(
                        overlayColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: _turnipEmptyCtaColor,
                        foregroundColor: AppColors.textInverse,
                        elevation: 0,
                        shadowColor: AppColors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _turnipEmptyButtonRadius,
                          ),
                        ),
                        textStyle: AppTextStyles.bodyWithSize(
                          18,
                          color: AppColors.textInverse,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('계산하러 가기 \u2192'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        const SizedBox(height: AppSpacing.s10),
        if (loading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (hasError)
          Text('도감 진행률을 불러오지 못했어요.', style: AppTextStyles.bodySecondaryStrong)
        else
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.s10,
            crossAxisSpacing: AppSpacing.s10,
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
                delay: const Duration(milliseconds: 20),
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
                delay: const Duration(milliseconds: 45),
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
                delay: const Duration(milliseconds: 70),
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
                delay: const Duration(milliseconds: 95),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWishListSection({
    required BuildContext context,
    required WidgetRef ref,
    required String currentIslandId,
    required List<CatalogItem> items,
    required Map<String, CatalogUserState> userStates,
    required bool loading,
    required bool hasError,
  }) {
    final favorites = items
        .where((item) => userStates[item.id]?.favorite ?? false)
        .toList(growable: false);
    final grouped = <String, List<CatalogItem>>{};
    for (final item in favorites) {
      grouped.putIfAbsent(item.category, () => <CatalogItem>[]).add(item);
    }
    final categoryOrder = <String>[
      '가구',
      '패션',
      '레시피',
      '주민',
      '물고기',
      '곤충',
      '해산물',
      '화석',
      '미술품',
      '아이템',
    ];
    // 유지보수 포인트:
    // 홈 위시 리스트는 일부 카테고리에만 데이터가 있어도 전체 카테고리 박스를
    // 같은 순서로 유지해야 사용자가 빈 카테고리도 바로 진입할 수 있습니다.
    final orderedKeys = List<String>.unmodifiable(categoryOrder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          context: context,
          title: '위시 리스트',
          onTap: () => _openWishListPage(
            context: context,
            uid: uid,
            islandId: currentIslandId,
            initialCategory: '전체',
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        if (loading)
          const SizedBox(
            height: 84,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (hasError)
          Text('위시 리스트를 불러오지 못했어요.', style: AppTextStyles.bodySecondaryStrong)
        else ...<Widget>[
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: orderedKeys.length,
              separatorBuilder: (_, unused) =>
                  const SizedBox(width: AppSpacing.s10),
              itemBuilder: (context, index) {
                final key = orderedKeys[index];
                final bucket = grouped[key] ?? const <CatalogItem>[];
                final preview = bucket.isEmpty ? null : bucket.first;
                return AnimatedFadeSlide(
                  delay: Duration(milliseconds: 25 + (index * 20)),
                  child: Material(
                    color: AppColors.transparent,
                    child: AppInkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openWishListPage(
                        context: context,
                        uid: uid,
                        islandId: currentIslandId,
                        initialCategory: key,
                      ),
                      child: Container(
                        width: 132,
                        padding: const EdgeInsets.all(AppSpacing.s10),
                        decoration: BoxDecoration(
                          color: AppColors.catalogCardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 42,
                                height: 42,
                                color: AppColors.bgSecondary,
                                child: preview == null
                                    ? Image.asset(
                                        _noDataImageAssetPath,
                                        fit: BoxFit.contain,
                                      )
                                    : _buildNetworkImage(preview.imageUrl),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  _wishCategoryLabel(key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySecondaryStrong,
                                ),
                                Expanded(child: SizedBox()),
                                Text(
                                  '${bucket.length}개',
                                  style: AppTextStyles.captionMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
    Duration delay = Duration.zero,
  }) {
    final progress = _safeProgress(completed, total);
    final percentage = (progress * 100).round();

    return AnimatedFadeSlide(
      delay: delay,
      child: Material(
        color: AppColors.transparent,
        child: AppInkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.of(context).push(
              AppPageRoute<void>(
                screenName: AppScreenNames.catalogCollection,
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
            padding: const EdgeInsets.all(AppSpacing.s12),
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
                      child: Text(title, style: AppTextStyles.bodyPrimaryHeavy),
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
                        style: AppTextStyles.captionMuted,
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
                            const SizedBox(height: AppSpacing.s6),
                            Text(
                              '$percentage%',
                              style: AppTextStyles.bodyWithSize(
                                14,
                                color: AppColors.textMuted,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.s12),
              ],
            ),
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
            style: AppTextStyles.bodyWithSize(
              22,
              color: AppColors.textPrimary,
              weight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            foregroundColor: AppColors.primaryDefault,
            textStyle: AppTextStyles.bodyPrimaryHeavy,
          ),
          child: const Text('전체보기'),
        ),
      ],
    );
  }

  Future<void> _openWishListPage({
    required BuildContext context,
    required String uid,
    required String islandId,
    required String initialCategory,
  }) async {
    await Navigator.of(context).push(
      AppPageRoute<void>(
        screenName: AppScreenNames.wishList,
        builder: (_) => WishListPage(
          uid: uid,
          islandId: islandId,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  Widget _buildResidentFilledSlot({
    required BuildContext context,
    required WidgetRef ref,
    required String islandId,
    required CatalogItem item,
    required Map<String, CatalogUserState> userStates,
    required int slotIndex,
  }) {
    return Semantics(
      label: '주민 슬롯 ${slotIndex + 1}: ${item.name}',
      button: true,
      child: AppInkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openResidentDetailSheet(
          context: context,
          ref: ref,
          islandId: islandId,
          item: item,
          userStates: userStates,
        ),
        child: SizedBox(
          width: _residentSlotWidth,
          child: Column(
            children: <Widget>[
              ClipOval(
                child: Container(
                  width: _residentAvatarSize,
                  height: _residentAvatarSize,

                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: _buildNetworkImage(_resolveResidentThumbUrl(item)),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondaryStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResidentEmptySlot({
    required BuildContext context,
    required String islandId,
    required List<CatalogItem> items,
    required int slotIndex,
  }) {
    final canOpenCollection = items.isNotEmpty;
    return Semantics(
      label: canOpenCollection
          ? '빈 주민 슬롯 ${slotIndex + 1}, 탭해서 주민 추가'
          : '빈 주민 슬롯 ${slotIndex + 1}',
      button: canOpenCollection,
      child: Material(
        color: AppColors.transparent,
        child: AppInkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canOpenCollection
              ? () async {
                  await _openResidentCollectionPage(
                    context: context,
                    islandId: islandId,
                    items: items,
                    startWithResidentFilter: false,
                  );
                }
              : null,
          child: SizedBox(
            width: _residentSlotWidth,
            child: Column(
              children: <Widget>[
                Container(
                  width: _residentAvatarSize,
                  height: _residentAvatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSecondary,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  '추가',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openResidentCollectionPage({
    required BuildContext context,
    required String islandId,
    required List<CatalogItem> items,
    bool startWithResidentFilter = true,
  }) async {
    if (items.isEmpty) {
      return;
    }
    await Navigator.of(context).push(
      AppPageRoute<void>(
        screenName: AppScreenNames.catalogCollection,
        builder: (_) => CatalogCollectionPage(
          uid: uid,
          islandId: islandId,
          title: '우리 섬 주민들',
          category: '주민',
          allItems: items,
          startWithResidentFilter: startWithResidentFilter,
        ),
      ),
    );
  }

  String _wishCategoryLabel(String category) {
    if (category == '아이템') {
      return '벽지 등';
    }
    return category;
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
      backgroundColor: AppColors.transparent,
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
