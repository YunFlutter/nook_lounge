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
        final platform = Theme.of(context).platform;
        final appChild = child ?? const SizedBox.shrink();

        // 유지보수 포인트:
        // 전역 하단 SafeArea는 안드로이드 시스템 네비게이션 바 대응 용도입니다.
        // iOS는 개별 위젯(예: NavigationBar)이 자체 safe inset을 처리하므로
        // 전역 적용 시 하단 여백이 중복되어 UI가 과하게 떠 보일 수 있습니다.
        final shouldApplyGlobalBottomSafeArea =
            platform == TargetPlatform.android;

        return ColoredBox(
          color: scaffoldBackground,
          child: shouldApplyGlobalBottomSafeArea
              ? SafeArea(
                  // 안드로이드 시스템 바텀 네비게이션 영역과 겹치지 않도록
                  // 앱 전체를 한 번 감싸서 하단 인셋을 공통 적용한다.
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  maintainBottomViewPadding: true,
                  child: appChild,
                )
              : appChild,
        );
      },
      routerConfig: router,
    );
  }
}
