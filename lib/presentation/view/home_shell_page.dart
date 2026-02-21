import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/create_island_page.dart';
import 'package:nook_lounge_app/presentation/view/home/home_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/home/island_switch_sheet.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_page.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeShellViewModelProvider);
    final tabController = ref.read(homeShellViewModelProvider.notifier);
    final currentTab = homeState.selectedTabIndex;
    final selectedIslandId =
        ref.watch(homeDashboardPrimaryIslandIdProvider(uid)).valueOrNull ?? '';

    return Scaffold(
      appBar: _buildAppBar(context, currentTab, ref, selectedIslandId),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey<int>(currentTab),
          child: _buildTabBody(currentTab, ref, selectedIslandId),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.navBackground,
        selectedIndex: currentTab,
        onDestinationSelected: tabController.changeTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.flight), label: '비행장'),
          NavigationDestination(icon: Icon(Icons.storefront), label: '마켓'),
          NavigationDestination(icon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: '도감'),
          NavigationDestination(icon: Icon(Icons.insert_chart), label: '무주식'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    int tabIndex,
    WidgetRef ref,
    String selectedIslandId,
  ) {
    if (tabIndex == 3) {
      return AppBar(
        title: const Text('도감 관리'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
            tooltip: '알림',
          ),
        ],
      );
    }

    if (tabIndex == 2) {
      final islandsAsync = ref.watch(homeDashboardIslandsProvider(uid));
      final primaryIslandIdAsync = ref.watch(
        homeDashboardPrimaryIslandIdProvider(uid),
      );
      final islands = islandsAsync.valueOrNull ?? const <IslandProfile>[];
      final selectedIsland = resolveHomeSelectedIsland(
        islands: islands,
        primaryIslandId: primaryIslandIdAsync.valueOrNull,
      );
      final islandTitle = islandsAsync.isLoading
          ? '섬 불러오는 중...'
          : selectedIsland?.islandName ?? '섬 선택';

      return AppBar(
        centerTitle: false,
        titleSpacing: AppSpacing.pageHorizontal,
        title: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _openIslandSwitchSheet(
            context: context,
            ref: ref,
            islands: islands,
            selectedIslandId: selectedIsland?.id,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  islandTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: AppColors.textPrimary),
            tooltip: '알림',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            tooltip: '설정',
          ),
          const SizedBox(width: 6),
        ],
      );
    }

    if (tabIndex == 4) {
      return AppBar(
        centerTitle: false,
        title: const Text('무 주식 계산기'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              ref
                  .read(
                    turnipViewModelProvider((
                      uid: uid,
                      islandId: selectedIslandId,
                    )).notifier,
                  )
                  .reset();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('초기화'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      );
    }

    return AppBar(
      title: const Text('Nook Lounge'),
      actions: <Widget>[
        IconButton(
          onPressed: () async {
            await ref.read(authRepositoryProvider).signOut();
          },
          icon: const Icon(Icons.logout),
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  Widget _buildTabBody(int tabIndex, WidgetRef ref, String selectedIslandId) {
    switch (tabIndex) {
      case 0:
        return _buildAirportTab();
      case 1:
        return _buildMarketTab();
      case 2:
        return _buildHomeTab();
      case 3:
        return CatalogDashboardTab(uid: uid, islandId: selectedIslandId);
      case 4:
        return _buildTurnipTab(selectedIslandId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAirportTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        AnimatedFadeSlide(
          child: Text(
            '비행장 관리',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: Duration(milliseconds: 40),
          child: Card(
            child: ListTile(
              title: Text('게이트 상태'),
              subtitle: Text('방문객에게 열림 / 도도코드 관리'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        AnimatedFadeSlide(
          child: Text(
            '너굴 마켓',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: Duration(milliseconds: 40),
          child: Card(
            child: ListTile(
              title: Text('거래 제안 목록'),
              subtitle: Text('실시간 상태는 거래 카드만 선택적으로 구독합니다.'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return HomeDashboardTab(uid: uid);
  }

  Widget _buildTurnipTab(String islandId) {
    return TurnipPage(uid: uid, islandId: islandId);
  }

  Future<void> _openIslandSwitchSheet({
    required BuildContext context,
    required WidgetRef ref,
    required List<IslandProfile> islands,
    required String? selectedIslandId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return IslandSwitchSheet(
          islands: islands,
          selectedIslandId: selectedIslandId,
          onSelectIsland: (islandId) async {
            await ref
                .read(islandRepositoryProvider)
                .setPrimaryIsland(uid: uid, islandId: islandId);
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
          onAddIsland: () async {
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CreateIslandPage(
                  uid: uid,
                  popToDashboardOnEnter: true,
                  onIslandEntered: (islandId) async {
                    await ref
                        .read(islandRepositoryProvider)
                        .setPrimaryIsland(uid: uid, islandId: islandId);
                    ref.read(homeShellViewModelProvider.notifier).changeTab(2);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
