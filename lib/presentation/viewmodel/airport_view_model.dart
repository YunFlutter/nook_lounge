import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';
import 'package:nook_lounge_app/presentation/state/airport_view_state.dart';

class AirportViewModel extends StateNotifier<AirportViewState> {
  AirportViewModel({
    required AirportRepository repository,
    required String uid,
    required String islandId,
  }) : _repository = repository,
       _uid = uid.trim(),
       _islandId = islandId.trim(),
       super(const AirportViewState()) {
    _bindStreams();
  }

  final AirportRepository _repository;
  final String _uid;
  final String _islandId;

  StreamSubscription<AirportSession?>? _sessionSubscription;
  StreamSubscription<List<AirportVisitRequest>>? _incomingSubscription;
  StreamSubscription<List<AirportVisitRequest>>? _myRequestsSubscription;

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
    await _runAction(
      action: () =>
          _repository.setGateOpen(islandId: _islandId, gateOpen: gateOpen),
      fallbackErrorMessage: '게이트 상태 변경에 실패했어요.',
    );
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

    await _runAction(
      action: () => _repository.submitVisitRequest(
        islandId: targetSession.islandId,
        hostUid: targetSession.ownerUid,
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
            state = state.copyWith(myRequests: requests, isInitializing: false);
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('$error');
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
            final selectable = requests
                .where((request) => request.isPending)
                .map((request) => request.id)
                .toSet();
            final nextSelection = state.selectedRequestIds
                .where(selectable.contains)
                .toSet();
            state = state.copyWith(
              incomingRequests: requests,
              selectedRequestIds: nextSelection,
              isInitializing: false,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(
              isInitializing: false,
              errorMessage: '방문 신청 목록을 불러오지 못했어요.',
            );
          },
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
      }
    }
    return fallback;
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _incomingSubscription?.cancel();
    _myRequestsSubscription?.cancel();
    super.dispose();
  }
}
