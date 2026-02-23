import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/create_island_page.dart';
import 'package:nook_lounge_app/presentation/view/home/home_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/home/island_switch_sheet.dart';
import 'package:nook_lounge_app/presentation/view/market/market_tab_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_detail_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_realtime_listener.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_page.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(pushOfferIntentNotifierProvider, (previous, next) {
      if (next == null || next == previous) {
        return;
      }
      unawaited(_openOfferDetailFromPush(context, ref, next));
    });

    final pendingOfferId = ref.watch(pushOfferIntentNotifierProvider);
    if (pendingOfferId != null && pendingOfferId.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openOfferDetailFromPush(context, ref, pendingOfferId));
      });
    }

    final homeState = ref.watch(homeShellViewModelProvider);
    final tabController = ref.read(homeShellViewModelProvider.notifier);
    final currentTab = homeState.selectedTabIndex;
    final selectedIslandId =
        ref.watch(homeDashboardPrimaryIslandIdProvider(uid)).valueOrNull ?? '';

    return MarketRealtimeListener(
      uid: uid,
      child: Scaffold(
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
            NavigationDestination(
              icon: _NavPngIcon(assetPath: 'assets/icon/boarding_pass.png'),
              selectedIcon: _NavPngIcon(
                assetPath: 'assets/icon/boarding_pass_act.png',
              ),
              label: '비행장',
            ),
            NavigationDestination(
              icon: _NavPngIcon(assetPath: 'assets/icon/shop.png'),
              selectedIcon: _NavPngIcon(assetPath: 'assets/icon/shop_act.png'),
              label: '마켓',
            ),
            NavigationDestination(
              icon: _NavPngIcon(assetPath: 'assets/icon/house.png'),
              selectedIcon: _NavPngIcon(assetPath: 'assets/icon/house_act.png'),
              label: '홈',
            ),
            NavigationDestination(
              icon: _NavPngIcon(assetPath: 'assets/icon/book_stack.png'),
              selectedIcon: _NavPngIcon(
                assetPath: 'assets/icon/book_stack_act.png',
              ),
              label: '도감',
            ),
            NavigationDestination(
              icon: _NavPngIcon(assetPath: 'assets/icon/combo_chart.png'),
              selectedIcon: _NavPngIcon(
                assetPath: 'assets/icon/combo_chart_act.png',
              ),
              label: '무주식',
            ),
          ],
        ),
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
                  style: AppTextStyles.bodyWithSize(
                    16,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
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

    if (tabIndex == 1) {
      return AppBar(
        centerTitle: false,
        titleSpacing: AppSpacing.pageHorizontal,
        title: const Text('너굴 마켓'),
        actions: <Widget>[
          IconButton(
            onPressed: () => MarketTabPage.openMyTradesPage(context),
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: '내 거래관리',
          ),
          const SizedBox(width: 10),
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
              textStyle: AppTextStyles.bodyWithSize(
                16,
                color: AppColors.textSecondary,
                weight: FontWeight.w700,
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
      children: <Widget>[
        AnimatedFadeSlide(
          child: Text('비행장 관리', style: AppTextStyles.dialogTitleWithSize(28)),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 40),
          child: Card(
            child: ListTile(
              title: const Text('게이트 상태'),
              subtitle: const Text('방문객에게 열림 / 도도코드 관리'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarketTab() {
    return MarketTabPage(uid: uid);
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

  Future<void> _openOfferDetailFromPush(
    BuildContext context,
    WidgetRef ref,
    String offerId,
  ) async {
    ref.read(pushOfferIntentNotifierProvider.notifier).clear();

    final normalizedId = offerId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final offer = await ref
        .read(marketRepositoryProvider)
        .fetchOfferById(normalizedId);

    if (!context.mounted) {
      return;
    }

    if (offer == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('거래 정보를 찾지 못했어요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    ref.read(homeShellViewModelProvider.notifier).changeTab(1);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarketOfferDetailPage(offer: offer),
      ),
    );
  }
}

class _NavPngIcon extends StatelessWidget {
  const _NavPngIcon({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: 30, height: 30, fit: BoxFit.contain);
  }
}
