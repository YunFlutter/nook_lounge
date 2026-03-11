import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/presentation/view/create_island_page.dart';
import 'package:nook_lounge_app/presentation/view/error_retry_view.dart';
import 'package:nook_lounge_app/presentation/view/guest_browse_page.dart';
import 'package:nook_lounge_app/presentation/view/home_shell_page.dart';
import 'package:nook_lounge_app/presentation/view/session_access_blocked_dialog.dart';
import 'package:nook_lounge_app/presentation/view/sign_in_page.dart';
import 'package:nook_lounge_app/presentation/view/splash_loading_page.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_inquiry_list_page.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';
import 'package:nook_lounge_app/presentation/viewmodel/session_view_model.dart';

class SessionGatePage extends ConsumerStatefulWidget {
  const SessionGatePage({super.key});

  @override
  ConsumerState<SessionGatePage> createState() => _SessionGatePageState();
}

class _SessionGatePageState extends ConsumerState<SessionGatePage> {
  bool _splashCompleted = false;
  ProviderSubscription<SessionViewState>? _sessionSubscription;
  String? _lastSignedOutMessage;
  String? _lastBlockedDialogKey;
  bool _isShowingBlockedDialog = false;

  @override
  void initState() {
    super.initState();
    // 유지보수 포인트:
    // 푸시 딥링크(알림 탭)를 앱 세션 시작 시 1회만 등록합니다.
    Future<void>.microtask(() async {
      try {
        await ref.read(pushMessageServiceProvider).initialize();
      } catch (error) {
        // 유지보수 포인트:
        // 푸시 초기화 실패는 세션 진입을 막지 않도록 방어합니다.
        debugPrint('[SessionGatePage] push initialize failed: $error');
      }
    });
    _sessionSubscription = ref.listenManual<SessionViewState>(
      sessionViewModelProvider,
      _handleSessionStateChanged,
    );
  }

  void _handleSessionStateChanged(
    SessionViewState? previous,
    SessionViewState next,
  ) {
    final nextSession = next.session;
    if (nextSession is SessionBlocked) {
      final blockedDialogKey = _buildBlockedDialogKey(nextSession);
      if (_isShowingBlockedDialog ||
          blockedDialogKey == _lastBlockedDialogKey) {
        return;
      }
      _lastBlockedDialogKey = blockedDialogKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showBlockedDialog(nextSession);
      });
      return;
    }

    _lastBlockedDialogKey = null;
    if (nextSession is! SessionSignedOut) {
      _lastSignedOutMessage = null;
      return;
    }

    final wasSignedOut = previous?.session is SessionSignedOut;
    final message = next.errorMessage?.trim() ?? '';
    final shouldShowMessage =
        message.isNotEmpty && message != _lastSignedOutMessage;

    if (!wasSignedOut && message.isNotEmpty) {
      _lastSignedOutMessage = message;
    } else if (shouldShowMessage) {
      _lastSignedOutMessage = message;
    }

    if (wasSignedOut && !shouldShowMessage) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (!wasSignedOut) {
        // 유지보수 포인트:
        // 로그아웃/강제로그아웃/탈퇴 후에는 누적된 상세 페이지를 모두 닫고
        // 세션 게이트(첫 화면)만 남겨 로그인 화면으로 복귀시킵니다.
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }

      if (shouldShowMessage) {
        _showSignedOutSnackBar(message);
        ref.read(sessionViewModelProvider.notifier).clearError();
      }
    });
  }

  String _buildBlockedDialogKey(SessionBlocked session) {
    return [
      session.uid,
      session.block.blockedUntilDateTime
          .toUtc()
          .millisecondsSinceEpoch
          .toString(),
      session.block.normalizedReason ?? '',
    ].join('|');
  }

  Future<void> _showBlockedDialog(SessionBlocked session) async {
    if (_isShowingBlockedDialog) {
      return;
    }

    _isShowingBlockedDialog = true;
    try {
      // 유지보수 포인트:
      // blocked 세션은 화면 이동을 막는 상태이므로, 동일 차단 정보에 대해
      // 다이얼로그가 중복으로 누적되지 않게 1회만 띄웁니다.
      await SessionAccessBlockedDialog.show(
        context: context,
        block: session.block,
      );
    } finally {
      _isShowingBlockedDialog = false;
    }
  }

  void _showSignedOutSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    try {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      // 유지보수 포인트:
      // 라우트 교체 직후에는 Scaffold attach 타이밍 이슈가 생길 수 있어
      // 한 프레임 뒤 재시도해 에러 오버레이(검은/빨간 경고 바)를 방지합니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final retryMessenger = ScaffoldMessenger.maybeOf(context);
        if (retryMessenger == null) {
          return;
        }
        retryMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  String _buildSplashStatusMessage({
    required SessionViewState state,
    required bool isAnonymous,
  }) {
    if (state.isLoading) {
      return '앱을 준비하는 중...';
    }

    final session = state.session;
    if (session == null) {
      return '다음 화면을 준비하는 중...';
    }

    // 유지보수 포인트:
    // 스플래시 안내 문구는 실제 세션 분기와 같은 기준을 사용해야
    // 로그인 여부와 무관하게 잘못된 목적 화면을 안내하지 않습니다.
    return session.when(
      signedOut: () => '로그인 화면으로 이동할게요.',
      needsIslandSetup: (_) => '섬 등록 화면으로 이동할게요.',
      ready: (uid) => uid == SessionViewModel.guestUid || isAnonymous
          ? '둘러보기 화면으로 이동할게요.'
          : '홈 화면으로 이동할게요.',
      blocked: (_, _) => '이용 제한 상태를 확인할게요.',
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionViewModelProvider);
    final isAnonymous = ref.watch(authRepositoryProvider).isAnonymous;
    final session = state.session;
    final isSignedOut = session is SessionSignedOut;
    final isBlocked = session is SessionBlocked;

    if (!_splashCompleted) {
      return SplashLoadingPage(
        statusMessage: _buildSplashStatusMessage(
          state: state,
          isAnonymous: isAnonymous,
        ),
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

    if (!isSignedOut && !isBlocked && state.errorMessage != null) {
      return ErrorRetryView(
        title: state.errorTitle ?? '데이터를 불러오지 못했어요',
        message: state.errorMessage ?? AppStrings.loadErrorMessage,
        onRetry: () => ref.read(sessionViewModelProvider.notifier).refresh(),
      );
    }

    if (state.isLoading || session == null) {
      return const SignInPage();
    }

    return session.when(
      signedOut: SignInPage.new,
      needsIslandSetup: (uid) => CreateIslandPage(uid: uid),
      ready: (uid) => uid == SessionViewModel.guestUid || isAnonymous
          ? GuestBrowsePage(uid: uid)
          : HomeShellPage(uid: uid),
      blocked: (uid, block) => SettingsInquiryListPage(
        uid: uid,
        blockedAccessMode: true,
        allowAppealSubmission: true,
      ),
    );
  }
}
