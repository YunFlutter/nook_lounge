import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/presentation/view/create_island_page.dart';
import 'package:nook_lounge_app/presentation/view/error_retry_view.dart';
import 'package:nook_lounge_app/presentation/view/guest_browse_page.dart';
import 'package:nook_lounge_app/presentation/view/home_shell_page.dart';
import 'package:nook_lounge_app/presentation/view/sign_in_page.dart';
import 'package:nook_lounge_app/presentation/view/splash_loading_page.dart';
import 'package:nook_lounge_app/presentation/viewmodel/session_view_model.dart';

class SessionGatePage extends ConsumerStatefulWidget {
  const SessionGatePage({super.key});

  @override
  ConsumerState<SessionGatePage> createState() => _SessionGatePageState();
}

class _SessionGatePageState extends ConsumerState<SessionGatePage> {
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    // 유지보수 포인트:
    // 푸시 딥링크(알림 탭)를 앱 세션 시작 시 1회만 등록합니다.
    Future<void>.microtask(() async {
      await ref.read(pushMessageServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionViewModelProvider);
    final isAnonymous = ref.watch(authRepositoryProvider).isAnonymous;

    if (!_splashCompleted) {
      return SplashLoadingPage(
        waitingForSession: state.isLoading,
        onCompleted: () {
          if (!mounted || _splashCompleted) {
            return;
          }
          setState(() {
            _splashCompleted = true;
          });
        },
      );
    }

    if (state.errorMessage != null) {
      return ErrorRetryView(
        title: state.errorTitle ?? '데이터를 불러오지 못했어요',
        message: state.errorMessage ?? AppStrings.loadErrorMessage,
        onRetry: () => ref.read(sessionViewModelProvider.notifier).refresh(),
      );
    }

    final session = state.session;

    if (state.isLoading || session == null) {
      return const SignInPage();
    }

    return session.when(
      signedOut: SignInPage.new,
      needsIslandSetup: (uid) => CreateIslandPage(uid: uid),
      ready: (uid) => uid == SessionViewModel.guestUid || isAnonymous
          ? GuestBrowsePage(uid: uid)
          : HomeShellPage(uid: uid),
    );
  }
}
