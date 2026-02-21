import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_dashboard_tab.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_page.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeShellViewModelProvider);
    final tabController = ref.read(homeShellViewModelProvider.notifier);
    final currentTab = homeState.selectedTabIndex;

    return Scaffold(
      appBar: _buildAppBar(currentTab, ref),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey<int>(currentTab),
          child: _buildTabBody(currentTab, ref),
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

  PreferredSizeWidget _buildAppBar(int tabIndex, WidgetRef ref) {
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

    if (tabIndex == 4) {
      return AppBar(
        centerTitle: false,
        title: const Text('무 주식 계산기'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () {
              ref.read(turnipViewModelProvider(uid).notifier).reset();
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

  Widget _buildTabBody(int tabIndex, WidgetRef ref) {
    switch (tabIndex) {
      case 0:
        return _buildAirportTab();
      case 1:
        return _buildMarketTab();
      case 2:
        return _buildHomeTab();
      case 3:
        return CatalogDashboardTab(uid: uid);
      case 4:
        return _buildTurnipTab();
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        AnimatedFadeSlide(
          child: Text(
            '홈 대시보드',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: Duration(milliseconds: 40),
          child: Card(
            child: ListTile(
              title: Text('요약 문서 기반 홈 렌더링'),
              subtitle: Text('homeSummaries/{islandId} 1문서로 첫 렌더 비용 최소화'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTurnipTab() {
    return TurnipPage(uid: uid);
  }
}
