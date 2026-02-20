import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // 앱 시작 분기(로그인/섬생성/홈)는 SessionViewModel 한 곳에서만 판단합니다.
    if (uid == null) {
      state = state.copyWith(
        isLoading: false,
        session: const SessionState.signedOut(),
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final hasPrimaryIsland = await _islandRepository.hasPrimaryIsland(uid);

      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        session: hasPrimaryIsland
            ? SessionState.ready(uid: uid)
            : SessionState.needsIslandSetup(uid: uid),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
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
