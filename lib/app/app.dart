import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/router/app_router_provider.dart';
import 'package:nook_lounge_app/app/theme/app_theme.dart';

class NookLoungeApp extends ConsumerWidget {
  const NookLoungeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Nook Lounge',
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;
        return ColoredBox(
          color: scaffoldBackground,
          child: SafeArea(
            // 안드로이드 시스템 바텀 네비게이션 영역과 겹치지 않도록
            // 앱 전체를 한 번 감싸서 하단 인셋을 공통 적용한다.
            top: false,
            left: false,
            right: false,
            bottom: true,
            maintainBottomViewPadding: true,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
