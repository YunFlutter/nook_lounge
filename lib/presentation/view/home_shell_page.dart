import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/presentation/state/catalog_search_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';

class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeShellViewModelProvider);
    final tabController = ref.read(homeShellViewModelProvider.notifier);
    final currentTab = homeState.selectedTabIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nook Lounge'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await ref
                  .read(catalogSearchViewModelProvider.notifier)
                  .loadInitial();
            },
            icon: const Icon(Icons.refresh),
            tooltip: '도감 새로고침',
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey<int>(currentTab),
          child: _buildTabBody(currentTab, ref),
        ),
      ),
      bottomNavigationBar: NavigationBar(
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

  Widget _buildTabBody(int tabIndex, WidgetRef ref) {
    switch (tabIndex) {
      case 0:
        return _buildAirportTab();
      case 1:
        return _buildMarketTab();
      case 2:
        return _buildHomeTab();
      case 3:
        return _buildCatalogTab(ref);
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

  Widget _buildCatalogTab(WidgetRef ref) {
    final state = ref.watch(catalogSearchViewModelProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const AnimatedFadeSlide(
          child: Text(
            '도감 / 주민 / 아이템',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: const Duration(milliseconds: 40),
          child: SearchBar(
            hintText: '이름이나 종으로 검색',
            leading: const Icon(Icons.search),
            onChanged: (keyword) {
              ref
                  .read(catalogSearchViewModelProvider.notifier)
                  .search(keyword: keyword);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildCatalogBody(state),
      ],
    );
  }

  Widget _buildCatalogBody(CatalogSearchViewState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Text(state.errorMessage!);
    }

    if (state.items.isEmpty) {
      return const Text('아직 데이터가 없어요.');
    }

    final visibleItems = state.items.take(20).toList(growable: false);

    return Column(
      children: visibleItems
          .map((item) => _buildCatalogItemCard(item))
          .toList(growable: false),
    );
  }

  Widget _buildCatalogItemCard(CatalogItem item) {
    return AnimatedFadeSlide(
      delay: const Duration(milliseconds: 60),
      child: Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: Text(item.category),
          trailing: item.imageUrl.isEmpty
              ? null
              : CircleAvatar(backgroundImage: NetworkImage(item.imageUrl)),
        ),
      ),
    );
  }

  Widget _buildTurnipTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const <Widget>[
        AnimatedFadeSlide(
          child: Text(
            '무주식 계산기',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(height: 12),
        AnimatedFadeSlide(
          delay: Duration(milliseconds: 40),
          child: Card(
            child: ListTile(
              title: Text('일일 무 가격 입력'),
              subtitle: Text('예측 로직은 로컬 계산 후 결과만 저장해 읽기 비용을 줄입니다.'),
            ),
          ),
        ),
      ],
    );
  }
}
