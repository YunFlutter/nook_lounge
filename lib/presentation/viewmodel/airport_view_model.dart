import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/presentation/state/airport_view_state.dart';

class AirportViewModel extends StateNotifier<AirportViewState> {
  AirportViewModel({
    required AirportRepository repository,
    required UserBlockRepository userBlockRepository,
    required String uid,
    required String islandId,
  }) : _repository = repository,
       _userBlockRepository = userBlockRepository,
       _uid = uid.trim(),
       _islandId = islandId.trim(),
       super(const AirportViewState()) {
    _bindBlockedUsers();
    _bindStreams();
  }

  final AirportRepository _repository;
  final UserBlockRepository _userBlockRepository;
  final String _uid;
  final String _islandId;

  StreamSubscription<AirportSession?>? _sessionSubscription;
  StreamSubscription<List<AirportVisitRequest>>? _incomingSubscription;
  StreamSubscription<List<AirportVisitRequest>>? _myRequestsSubscription;
  StreamSubscription<Set<String>>? _blockedUsersSubscription;

  List<AirportVisitRequest> _latestIncomingRequests =
      const <AirportVisitRequest>[];
  List<AirportVisitRequest> _latestMyRequests = const <AirportVisitRequest>[];
  Set<String> _blockedUserIds = const <String>{};

  bool get hasIsland => _islandId.isNotEmpty;

  Future<void> ensureSession({
    required String islandName,
    required String hostName,
    required String hostAvatarUrl,
    required String islandImageUrl,
  }) async {
    if (!hasIsland || _uid.isEmpty) {
      return;
    }

    final session = state.session;
    final savedIntroMessage = session?.introMessage.trim() ?? '';
    final savedRules = session?.rules.trim() ?? '';
    final next = AirportSession(
      islandId: _islandId,
      ownerUid: _uid,
      islandName: islandName.trim().isEmpty ? '이름 없는 섬' : islandName.trim(),
      hostName: hostName.trim().isEmpty ? '호스트' : hostName.trim(),
      hostAvatarUrl: hostAvatarUrl.trim(),
      islandImageUrl: islandImageUrl.trim(),
      introMessage: savedIntroMessage.isNotEmpty
          ? savedIntroMessage
          : AirportSession.defaultIntroMessage,
      rules: savedRules.isNotEmpty ? savedRules : AirportSession.defaultRules,
      purpose: session?.purpose ?? AirportVisitPurpose.touching,
      gateOpen: session?.gateOpen ?? false,
      dodoCode: session?.dodoCode ?? '',
      dodoCodeUpdatedAt: session?.dodoCodeUpdatedAt,
      updatedAt: DateTime.now(),
      capacity: session?.capacity ?? 8,
    );

    await _repository.ensureSession(session: next);
  }

  Future<void> toggleGateOpen(bool gateOpen) async {
    if (!hasIsland) {
      return;
    }

    final previousSession = state.session;
    if (previousSession != null) {
      state = state.copyWith(
        session: previousSession.copyWith(
          gateOpen: gateOpen,
          updatedAt: DateTime.now(),
        ),
      );
    }

    final succeeded = await _runAction(
      action: () =>
          _repository.setGateOpen(islandId: _islandId, gateOpen: gateOpen),
      fallbackErrorMessage: '게이트 상태 변경에 실패했어요.',
    );
    if (!succeeded && previousSession != null) {
      state = state.copyWith(session: previousSession);
    }
  }

  Future<void> updatePurposeAndIntro({
    required AirportVisitPurpose purpose,
    required String introMessage,
  }) async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () => _repository.updatePurposeAndIntro(
        islandId: _islandId,
        purpose: purpose,
        introMessage: introMessage,
      ),
      fallbackErrorMessage: '목적/소개 저장에 실패했어요.',
    );
  }

  Future<void> updateRules(String rules) async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () => _repository.updateRules(islandId: _islandId, rules: rules),
      fallbackErrorMessage: '규칙 저장에 실패했어요.',
      successMessage: '규칙을 저장했어요.',
    );
  }

  Future<void> updateDodoCode(String dodoCode) async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () =>
          _repository.updateDodoCode(islandId: _islandId, dodoCode: dodoCode),
      fallbackErrorMessage: '도도코드 저장에 실패했어요.',
      successMessage: '도도코드를 등록했어요.',
    );
  }

  Future<void> resetDodoCode() async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () => _repository.resetDodoCode(_islandId),
      fallbackErrorMessage: '도도코드 초기화에 실패했어요.',
      successMessage: '도도코드를 초기화했어요.',
    );
  }

  void toggleRequestSelection(String requestId) {
    final normalizedRequestId = requestId.trim();
    if (normalizedRequestId.isEmpty) {
      return;
    }
    final next = <String>{...state.selectedRequestIds};
    if (next.contains(normalizedRequestId)) {
      next.remove(normalizedRequestId);
    } else {
      next.add(normalizedRequestId);
    }
    state = state.copyWith(selectedRequestIds: next);
  }

  void selectAllPending() {
    final allPending = state.pendingRequests
        .map((request) => request.id)
        .toSet();
    state = state.copyWith(selectedRequestIds: allPending);
  }

  void clearSelectedRequests() {
    state = state.copyWith(selectedRequestIds: const <String>{});
  }

  Future<bool> inviteSelectedRequests({required String dodoCode}) async {
    if (!hasIsland) {
      return false;
    }
    final selected = state.selectedRequestIds.toList(growable: false);
    if (selected.isEmpty) {
      state = state.copyWith(errorMessage: '초대할 손님을 선택해 주세요.');
      return false;
    }

    return _runAction(
      action: () => _repository.inviteRequests(
        islandId: _islandId,
        requestIds: selected,
        dodoCode: dodoCode,
      ),
      fallbackErrorMessage: '초대장을 보내지 못했어요.',
      successMessage: '초대장과 도도코드를 전송했어요.',
      onSuccess: () => clearSelectedRequests(),
    );
  }

  Future<void> requestVisit({
    required AirportSession targetSession,
    required String requesterName,
    required String requesterAvatarUrl,
    required String requesterIslandName,
    required String requesterIslandImageUrl,
    required AirportVisitPurpose purpose,
    required String message,
  }) async {
    if (_uid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 방문 신청할 수 있어요.');
      return;
    }
    final hostUid = targetSession.ownerUid.trim();
    if (hostUid.isEmpty) {
      state = state.copyWith(errorMessage: '방문 신청할 섬 주인 정보를 찾지 못했어요.');
      throw StateError('invalid_host_uid');
    }
    if (_blockedUserIds.contains(hostUid) ||
        await _userBlockRepository.hasBlockRelationship(
          uid: _uid,
          otherUid: hostUid,
        )) {
      state = state.copyWith(errorMessage: '차단된 유저의 섬에는 방문 신청할 수 없어요.');
      throw StateError('blocked_user');
    }

    await _runAction(
      action: () => _repository.submitVisitRequest(
        islandId: targetSession.islandId,
        hostUid: hostUid,
        hostName: targetSession.hostName,
        hostIslandName: targetSession.islandName,
        hostIslandImageUrl: targetSession.islandImageUrl,
        requesterUid: _uid,
        requesterName: requesterName,
        requesterAvatarUrl: requesterAvatarUrl,
        requesterIslandName: requesterIslandName,
        requesterIslandImageUrl: requesterIslandImageUrl,
        purpose: purpose,
        message: message,
      ),
      fallbackErrorMessage: '방문 신청에 실패했어요.',
      successMessage: '방문 신청을 보냈어요.',
    );
  }

  Future<void> cancelVisitRequest(AirportVisitRequest request) async {
    await _runAction(
      action: () => _repository.cancelVisitRequest(
        islandId: request.islandId,
        requestId: request.id,
        cancelByUid: _uid,
      ),
      fallbackErrorMessage: '요청 취소에 실패했어요.',
      successMessage: '방문 요청을 취소했어요.',
    );
  }

  Future<void> markArrived(String requestId) async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () =>
          _repository.markArrived(islandId: _islandId, requestId: requestId),
      fallbackErrorMessage: '도착 처리에 실패했어요.',
      successMessage: '방문객을 입장 처리했어요.',
    );
  }

  Future<void> completeVisit(String requestId) async {
    if (!hasIsland) {
      return;
    }
    await _runAction(
      action: () =>
          _repository.completeVisit(islandId: _islandId, requestId: requestId),
      fallbackErrorMessage: '방문 종료 처리에 실패했어요.',
      successMessage: '방문객을 퇴장 처리했어요.',
    );
  }

  Future<void> reportVisitRequester({
    required AirportVisitRequest request,
  }) async {
    if (_uid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 신고할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final normalizedIslandId = request.islandId.trim();
    final normalizedRequestId = request.id.trim();
    final normalizedHostUid = request.hostUid.trim();
    final normalizedRequesterUid = request.requesterUid.trim();
    if (normalizedIslandId.isEmpty ||
        normalizedRequestId.isEmpty ||
        normalizedHostUid.isEmpty ||
        normalizedRequesterUid.isEmpty) {
      state = state.copyWith(errorMessage: '신고할 손님 정보를 찾지 못했어요.');
      throw StateError('invalid_airport_report_payload');
    }
    if (normalizedRequesterUid == _uid) {
      state = state.copyWith(errorMessage: '본인 계정은 신고할 수 없어요.');
      throw StateError('cannot_report_self');
    }

    try {
      await _repository.reportVisitRequester(
        islandId: normalizedIslandId,
        requestId: normalizedRequestId,
        hostUid: normalizedHostUid,
        requesterUid: normalizedRequesterUid,
        reporterUid: _uid,
        sourceType: request.sourceType,
        sourceOfferId: request.sourceOfferId,
      );
      state = state.copyWith(errorMessage: null);
    } catch (error) {
      state = state.copyWith(
        errorMessage: _resolveErrorMessage(error, '손님 신고에 실패했어요.'),
      );
      rethrow;
    }
  }

  Future<void> blockUserForMe({required String blockedUid}) async {
    if (_uid.isEmpty) {
      state = state.copyWith(errorMessage: '로그인 후 유저를 차단할 수 있어요.');
      throw StateError('unauthenticated');
    }

    final normalizedBlockedUid = blockedUid.trim();
    if (normalizedBlockedUid.isEmpty) {
      state = state.copyWith(errorMessage: '차단할 유저 정보를 찾지 못했어요.');
      throw StateError('invalid_blocked_uid');
    }
    if (normalizedBlockedUid == _uid) {
      state = state.copyWith(errorMessage: '본인 계정은 차단할 수 없어요.');
      throw StateError('cannot_block_self');
    }

    final previousBlockedUserIds = _blockedUserIds;
    _blockedUserIds = <String>{..._blockedUserIds, normalizedBlockedUid};
    _applyIncomingRequests();
    _applyMyRequests();

    try {
      await _userBlockRepository.blockUser(
        uid: _uid,
        blockedUid: normalizedBlockedUid,
      );
      state = state.copyWith(errorMessage: null);
    } catch (_) {
      _blockedUserIds = previousBlockedUserIds;
      _applyIncomingRequests();
      _applyMyRequests();
      state = state.copyWith(errorMessage: '유저 차단에 실패했어요.');
      rethrow;
    }
  }

  void consumeMessages() {
    if (state.errorMessage == null && state.infoMessage == null) {
      return;
    }
    state = state.copyWith(errorMessage: null, infoMessage: null);
  }

  Future<bool> _runAction({
    required Future<void> Function() action,
    required String fallbackErrorMessage,
    String? successMessage,
    void Function()? onSuccess,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      infoMessage: null,
    );
    try {
      await action();
      onSuccess?.call();
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
        infoMessage: successMessage,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _resolveErrorMessage(error, fallbackErrorMessage),
      );
      return false;
    }
  }

  void _bindStreams() {
    _myRequestsSubscription = _repository
        .watchMyRequests(_uid)
        .listen(
          (requests) {
            _latestMyRequests = requests;
            _applyMyRequests(markInitialized: true);
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              isInitializing: false,
              errorMessage: '내 방문 요청 현황을 불러오지 못했어요.',
            );
          },
        );

    if (!hasIsland) {
      state = state.copyWith(isInitializing: false);
      return;
    }

    _sessionSubscription = _repository
        .watchSession(_islandId)
        .listen(
          (session) {
            state = state.copyWith(session: session, isInitializing: false);
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              isInitializing: false,
              errorMessage: '비행장 세션 정보를 불러오지 못했어요.',
            );
          },
        );

    _incomingSubscription = _repository
        .watchIncomingRequests(_islandId)
        .listen(
          (requests) {
            _latestIncomingRequests = requests;
            _applyIncomingRequests(markInitialized: true);
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              isInitializing: false,
              errorMessage: '방문 신청 목록을 불러오지 못했어요.',
            );
          },
        );
  }

  void _bindBlockedUsers() {
    if (_uid.isEmpty) {
      _blockedUserIds = const <String>{};
      return;
    }
    _blockedUsersSubscription = _userBlockRepository
        .watchInvisibleUserIds(_uid)
        .listen(
          (blockedUserIds) {
            _blockedUserIds = blockedUserIds;
            _applyIncomingRequests();
            _applyMyRequests();
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(errorMessage: '차단/상호 숨김 목록을 불러오지 못했어요.');
          },
        );
  }

  void _applyIncomingRequests({bool markInitialized = false}) {
    final blocked = _blockedUserIds;
    final filtered = _latestIncomingRequests
        .where((request) {
          final requesterUid = request.requesterUid.trim();
          if (requesterUid.isEmpty || requesterUid == _uid) {
            return true;
          }
          return !blocked.contains(requesterUid);
        })
        .toList(growable: false);

    final selectable = filtered
        .where((request) => request.isPending)
        .map((request) => request.id)
        .toSet();
    final nextSelection = state.selectedRequestIds
        .where(selectable.contains)
        .toSet();

    state = state.copyWith(
      incomingRequests: filtered,
      selectedRequestIds: nextSelection,
      isInitializing: markInitialized ? false : state.isInitializing,
    );
  }

  void _applyMyRequests({bool markInitialized = false}) {
    final blocked = _blockedUserIds;
    final filtered = _latestMyRequests
        .where((request) {
          final hostUid = request.hostUid.trim();
          if (hostUid.isEmpty || hostUid == _uid) {
            return true;
          }
          return !blocked.contains(hostUid);
        })
        .toList(growable: false);
    state = state.copyWith(
      myRequests: filtered,
      isInitializing: markInitialized ? false : state.isInitializing,
    );
  }

  String _resolveErrorMessage(Object error, String fallback) {
    if (error is FormatException) {
      return '도도코드는 영문 대문자+숫자 5자리로 입력해 주세요.';
    }
    if (error is StateError) {
      switch (error.message) {
        case 'already_requested':
          return '이미 해당 섬에 대기 중인 요청이 있어요.';
        case 'cannot_request_own_island':
          return '내 섬에는 방문 신청할 수 없어요.';
        case 'invalid_dodo_code':
          return '도도코드는 영문 대문자+숫자 5자리로 입력해 주세요.';
        case 'duplicate_airport_visit_report':
          return '이미 신고 접수된 손님이에요.';
        case 'invalid_airport_report_payload':
          return '신고할 손님 정보를 찾지 못했어요.';
        case 'blocked_user':
          return '차단된 유저와는 방문 요청을 주고받을 수 없어요.';
        case 'cannot_report_self':
          return '본인 계정은 신고할 수 없어요.';
      }
    }
    return fallback;
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _incomingSubscription?.cancel();
    _myRequestsSubscription?.cancel();
    _blockedUsersSubscription?.cancel();
    super.dispose();
  }
}
