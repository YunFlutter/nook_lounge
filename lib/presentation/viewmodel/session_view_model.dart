import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/constants/app_strings.dart';
import 'package:nook_lounge_app/core/error/firebase_error_mapper.dart';
import 'package:nook_lounge_app/domain/model/session_state.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';

class SessionViewModel extends StateNotifier<SessionViewState> {
  static const String guestUid = '__guest_local__';

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
  StreamSubscription<bool>? _userDocumentSubscription;
  bool _isGuestBrowsing = false;
  bool _isForcingSignOutForMissingUser = false;

  Future<void> _onUserChanged(String? uid) async {
    await _userDocumentSubscription?.cancel();
    _userDocumentSubscription = null;

    // 유지보수 포인트:
    // 앱 시작 분기(로그인/섬생성/홈)는 캐시 기반으로 즉시 처리하고,
    // 서버 재검증은 백그라운드에서만 수행합니다.
    if (uid != null) {
      _isGuestBrowsing = false;
    }

    if (uid == null) {
      final hasSignedOutMessage =
          state.session is SessionSignedOut &&
          (state.errorMessage?.trim().isNotEmpty ?? false);
      if (_isGuestBrowsing) {
        state = state.copyWith(
          isLoading: false,
          session: const SessionState.ready(uid: guestUid),
          errorTitle: null,
          errorMessage: null,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        session: const SessionState.signedOut(),
        errorTitle: hasSignedOutMessage ? state.errorTitle : null,
        errorMessage: hasSignedOutMessage ? state.errorMessage : null,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorTitle: null,
      errorMessage: null,
    );

    try {
      final hasUserDocument = await _authRepository.hasUserDocument(uid);
      if (!hasUserDocument) {
        await _handleMissingUserDocument(uid);
        return;
      }

      _watchUserDocument(uid);

      final activeServiceBlock = await _authRepository.getActiveServiceBlock(
        uid,
      );
      if (activeServiceBlock != null) {
        // 유지보수 포인트:
        // 로그인은 성공했더라도 서비스 차단 기간이면 홈/섬 생성 화면으로 보내지 않고
        // 세션 게이트에서 차단 모달만 띄울 수 있도록 blocked 상태로 고정합니다.
        state = state.copyWith(
          isLoading: false,
          errorTitle: null,
          errorMessage: null,
          session: SessionState.blocked(uid: uid, block: activeServiceBlock),
        );
        return;
      }

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

  Future<void> _handleMissingUserDocument(String uid) async {
    if (_authRepository.currentUserId != uid ||
        _authRepository.isWithdrawalInProgress ||
        _isForcingSignOutForMissingUser) {
      return;
    }

    _isForcingSignOutForMissingUser = true;

    // 유지보수 포인트:
    // users/{uid}가 없는 계정은 비정상 세션으로 간주하고
    // 즉시 로그아웃 처리해 로그인부터 다시 시작하도록 강제합니다.
    try {
      try {
        await _authRepository.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      final currentUid = _authRepository.currentUserId;
      if (currentUid != null && currentUid != uid) {
        // 다른 계정으로 이미 전환된 경우 안내 문구를 덮어쓰지 않습니다.
        return;
      }

      state = state.copyWith(
        isLoading: false,
        session: const SessionState.signedOut(),
        errorTitle: null,
        errorMessage: AppStrings.missingLoginInfoMessage,
      );
    } finally {
      _isForcingSignOutForMissingUser = false;
    }
  }

  void _watchUserDocument(String uid) {
    _userDocumentSubscription = _authRepository
        .watchUserDocumentExists(uid)
        .listen((exists) async {
          if (!exists) {
            await _handleMissingUserDocument(uid);
          }
        }, onError: (_, _) {});
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
    } catch (_) {
      // 백그라운드 재검증 실패는 UX를 막지 않도록 현재 세션을 유지합니다.
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
    if (_isGuestBrowsing) {
      state = state.copyWith(
        isLoading: false,
        session: const SessionState.ready(uid: guestUid),
        errorTitle: null,
        errorMessage: null,
      );
      return;
    }
    await _onUserChanged(_authRepository.currentUserId);
  }

  void markIslandSetupCompleted({required String uid}) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty ||
        _authRepository.currentUserId != normalizedUid) {
      return;
    }

    // 유지보수 포인트:
    // 여권 발급 직후에는 캐시 전파 지연으로 hasPrimaryIsland(cache)가
    // 잠시 false를 반환할 수 있어, 사용자가 "섬으로 입장하기"를 눌렀을 때
    // 즉시 홈으로 전환되도록 ready 상태를 선반영합니다.
    state = state.copyWith(
      isLoading: false,
      errorTitle: null,
      errorMessage: null,
      session: SessionState.ready(uid: normalizedUid),
    );

    // 서버 기준 실제 상태와의 불일치는 백그라운드 재검증으로 보정합니다.
    unawaited(_revalidateInBackground(normalizedUid));
  }

  void clearError() {
    if (state.errorTitle == null && state.errorMessage == null) {
      return;
    }
    state = state.copyWith(errorTitle: null, errorMessage: null);
  }

  void enterGuestBrowseMode() {
    _isGuestBrowsing = true;
    state = state.copyWith(
      isLoading: false,
      session: const SessionState.ready(uid: guestUid),
      errorTitle: null,
      errorMessage: null,
    );
  }

  void exitGuestBrowseMode() {
    _isGuestBrowsing = false;
    state = state.copyWith(
      isLoading: false,
      session: const SessionState.signedOut(),
      errorTitle: null,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _userDocumentSubscription?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
