import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/app_telemetry_scope.dart';
import 'package:nook_lounge_app/app/router/app_router_provider.dart';
import 'package:nook_lounge_app/app/theme/app_theme.dart';
import 'package:nook_lounge_app/presentation/view/app_update_guard.dart';

class NookLoungeApp extends ConsumerWidget {
  const NookLoungeApp({super.key});

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _dismissKeyboardOnPointerDown(PointerDownEvent event) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null) {
      return;
    }

    final focusedContext = focusedNode.context;
    if (focusedContext != null) {
      final renderObject = focusedContext.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        final focusedRect =
            renderObject.localToGlobal(Offset.zero) & renderObject.size;
        if (focusedRect.contains(event.position)) {
          // 유지보수 포인트:
          // 현재 포커스된 입력 필드 내부를 다시 터치한 경우에는
          // 키보드를 유지해 커서 이동/선택 동작을 방해하지 않습니다.
          return;
        }
      }
    }

    focusedNode.unfocus();
  }

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
        final appChild = AppUpdateGuard(
          child: AppTelemetryScope(child: child ?? const SizedBox.shrink()),
        );

        // 유지보수 포인트:
        // 전역 하단 SafeArea는 안드로이드 시스템 네비게이션 바 대응 용도입니다.
        // iOS는 개별 위젯(예: NavigationBar)이 자체 safe inset을 처리하므로
        // 전역 적용 시 하단 여백이 중복되어 UI가 과하게 떠 보일 수 있습니다.
        final shouldApplyGlobalBottomSafeArea =
            platform == TargetPlatform.android;
        final shouldUseTapDismissKeyboardOnRoot =
            platform == TargetPlatform.iOS ||
            platform == TargetPlatform.android;

        final wrappedChild = ColoredBox(
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

        if (shouldUseTapDismissKeyboardOnRoot) {
          // 유지보수 포인트:
          // iOS/Android에서는 스크롤 시작 터치도 pointer down으로 들어오므로
          // 전역 포인터 다운 dismiss를 쓰면 입력 중 스크롤만으로 키보드가 내려갑니다.
          // 탭 확정 시점(onTap)으로만 dismiss해 입력/스크롤 UX를 분리합니다.
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissKeyboard,
            child: wrappedChild,
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _dismissKeyboardOnPointerDown,
          child: wrappedChild,
        );
      },
      routerConfig: router,
    );
  }
}
