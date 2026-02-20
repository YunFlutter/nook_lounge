import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/error/firebase_error_mapper.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';

class SessionViewModel extends StateNotifier<SessionViewState> {
  SessionViewModel({
    required AuthRepository authRepository,
    required IslandRepository islandRepository,
  }) : _authRepository = authRepository,
       _islandRepository = islandRepository,
       super(const SessionViewState()) {
    _subscription = _authRepository.watchUserId().listen(_onUserChanged);
  }

  final AuthRepository _authRepository;
  final IslandRepository _islandRepository;

  late final StreamSubscription<String?> _subscription;

  Future<void> _onUserChanged(String? uid) async {
    // 유지보수 포인트:
    // 앱 시작 분기(로그인/섬생성/홈)는 캐시 기반으로 즉시 처리하고,
    // 서버 재검증은 백그라운드에서만 수행합니다.
    if (uid == null) {
      state = state.copyWith(
        isLoading: false,
        session: const SessionState.signedOut(),
        errorTitle: null,
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorTitle: null,
      errorMessage: null,
    );

    try {
      if (_authRepository.isAnonymous) {
        // 유지보수 포인트:
        // 비회원(익명) 세션은 여권 등록을 강제하지 않고 둘러보기 홈으로 보냅니다.
        state = state.copyWith(
          isLoading: false,
          errorTitle: null,
          errorMessage: null,
          session: SessionState.ready(uid: uid),
        );
        return;
      }

      final hasPrimaryIsland = await _islandRepository.hasPrimaryIsland(uid);

      _setSession(uid: uid, hasPrimaryIsland: hasPrimaryIsland);

      unawaited(_revalidateInBackground(uid));
    } catch (error) {
      final displayInfo = FirebaseErrorMapper.map(error);

      state = state.copyWith(
        isLoading: false,
        errorTitle: displayInfo.title,
        errorMessage: displayInfo.message,
      );
    }
  }

  Future<void> _revalidateInBackground(String uid) async {
    try {
      final hasPrimaryIsland = await _islandRepository.revalidatePrimaryIsland(
        uid,
      );

      if (!mounted || _authRepository.currentUserId != uid) {
        return;
      }

      if (hasPrimaryIsland == null) {
        // 네트워크 일시 장애 시 무시(초기 캐시 분기 유지)
        return;
      }

      final nextSession = hasPrimaryIsland
          ? SessionState.ready(uid: uid)
          : SessionState.needsIslandSetup(uid: uid);

      if (state.session == nextSession) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorTitle: null,
        errorMessage: null,
        session: nextSession,
      );
    } catch (error, stackTrace) {
      // 백그라운드 재검증 실패는 UX를 막지 않도록 로그만 남깁니다.
      debugPrint('Background revalidate failed: $error\n$stackTrace');
    }
  }

  void _setSession({required String uid, required bool hasPrimaryIsland}) {
    state = state.copyWith(
      isLoading: false,
      errorTitle: null,
      errorMessage: null,
      session: hasPrimaryIsland
          ? SessionState.ready(uid: uid)
          : SessionState.needsIslandSetup(uid: uid),
    );
  }

  Future<void> refresh() async {
    await _onUserChanged(_authRepository.currentUserId);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
