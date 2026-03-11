import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/presentation/viewmodel/airport_view_model.dart';

void main() {
  group('AirportViewModel', () {
    late _FakeAirportRepository airportRepository;
    late _FakeUserBlockRepository userBlockRepository;
    late AirportViewModel viewModel;

    setUp(() {
      airportRepository = _FakeAirportRepository();
      userBlockRepository = _FakeUserBlockRepository();
      viewModel = AirportViewModel(
        repository: airportRepository,
        userBlockRepository: userBlockRepository,
        uid: 'me',
        islandId: 'my-island',
      );
    });

    tearDown(() async {
      viewModel.dispose();
      await airportRepository.dispose();
      await userBlockRepository.dispose();
    });

    test('나를 차단한 유저의 방문 요청은 양쪽 목록에서 숨긴다', () async {
      airportRepository.sessionController.add(_buildSession(ownerUid: 'me'));
      airportRepository.incomingRequestsController.add(<AirportVisitRequest>[
        _buildRequest(id: 'visible-incoming', requesterUid: 'guest-a'),
        _buildRequest(id: 'blocked-incoming', requesterUid: 'blocked-user'),
      ]);
      airportRepository.myRequestsController.add(<AirportVisitRequest>[
        _buildRequest(
          id: 'visible-my-request',
          hostUid: 'host-a',
          requesterUid: 'me',
        ),
        _buildRequest(
          id: 'blocked-my-request',
          hostUid: 'blocked-user',
          requesterUid: 'me',
        ),
      ]);
      userBlockRepository.invisibleUserIdsController.add(const <String>{
        'blocked-user',
      });

      await Future<void>.delayed(Duration.zero);

      expect(
        viewModel.state.incomingRequests.map((request) => request.id),
        <String>['visible-incoming'],
      );
      expect(viewModel.state.myRequests.map((request) => request.id), <String>[
        'visible-my-request',
      ]);
    });

    test('차단 관계인 유저의 섬에는 방문 신청하지 않는다', () async {
      userBlockRepository.hasBlockRelationshipResult = true;

      await expectLater(
        viewModel.requestVisit(
          targetSession: _buildSession(ownerUid: 'blocked-user'),
          requesterName: 'me',
          requesterAvatarUrl: '',
          requesterIslandName: 'my island',
          requesterIslandImageUrl: '',
          purpose: AirportVisitPurpose.touching,
          message: 'hello',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'blocked_user',
          ),
        ),
      );
      expect(viewModel.state.errorMessage, '차단된 유저의 섬에는 방문 신청할 수 없어요.');
      expect(airportRepository.submitVisitRequestCallCount, 0);
    });

    test('게이트 토글은 저장 응답 전에도 화면 상태를 먼저 갱신한다', () async {
      airportRepository.sessionController.add(_buildSession(ownerUid: 'me'));
      await Future<void>.delayed(Duration.zero);

      final completer = Completer<void>();
      airportRepository.setGateOpenCompleter = completer;

      final future = viewModel.toggleGateOpen(false);

      expect(viewModel.state.session?.gateOpen, isFalse);

      completer.complete();
      await future;
    });
  });
}

AirportSession _buildSession({required String ownerUid}) {
  return AirportSession(
    islandId: 'target-island',
    ownerUid: ownerUid,
    islandName: '섬',
    hostName: '호스트',
    hostAvatarUrl: '',
    islandImageUrl: '',
    introMessage: '어서오세요',
    rules: '규칙',
    purpose: AirportVisitPurpose.touching,
    gateOpen: true,
    dodoCode: '',
    updatedAt: DateTime(2026, 3, 10, 12),
    capacity: 8,
  );
}

AirportVisitRequest _buildRequest({
  required String id,
  String hostUid = 'host-a',
  String requesterUid = 'guest-a',
}) {
  final now = DateTime(2026, 3, 10, 12);
  return AirportVisitRequest(
    id: id,
    islandId: 'target-island',
    hostUid: hostUid,
    hostName: 'host',
    hostIslandName: 'host island',
    hostIslandImageUrl: '',
    requesterUid: requesterUid,
    requesterName: 'guest',
    requesterAvatarUrl: '',
    requesterIslandName: 'guest island',
    requesterIslandImageUrl: '',
    message: 'message',
    purpose: AirportVisitPurpose.touching,
    status: AirportVisitRequestStatus.pending,
    requestedAt: now,
    updatedAt: now,
  );
}

class _FakeAirportRepository implements AirportRepository {
  final StreamController<AirportSession?> sessionController =
      StreamController<AirportSession?>.broadcast();
  final StreamController<List<AirportVisitRequest>> incomingRequestsController =
      StreamController<List<AirportVisitRequest>>.broadcast();
  final StreamController<List<AirportVisitRequest>> myRequestsController =
      StreamController<List<AirportVisitRequest>>.broadcast();
  int submitVisitRequestCallCount = 0;
  Completer<void>? setGateOpenCompleter;

  Future<void> dispose() async {
    await sessionController.close();
    await incomingRequestsController.close();
    await myRequestsController.close();
  }

  @override
  Stream<AirportSession?> watchSession(String islandId) =>
      sessionController.stream;

  @override
  Stream<List<AirportVisitRequest>> watchIncomingRequests(String islandId) {
    return incomingRequestsController.stream;
  }

  @override
  Stream<List<AirportVisitRequest>> watchMyRequests(String uid) {
    return myRequestsController.stream;
  }

  @override
  Future<void> submitVisitRequest({
    required String islandId,
    required String hostUid,
    required String hostName,
    required String hostIslandName,
    required String hostIslandImageUrl,
    required String requesterUid,
    required String requesterName,
    required String requesterAvatarUrl,
    required String requesterIslandName,
    required String requesterIslandImageUrl,
    required AirportVisitPurpose purpose,
    required String message,
    String? sourceType,
    String? sourceOfferId,
    String? sourceMoveType,
  }) async {
    submitVisitRequestCallCount += 1;
  }

  @override
  Future<void> setGateOpen({required String islandId, required bool gateOpen}) {
    return setGateOpenCompleter?.future ?? Future<void>.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserBlockRepository implements UserBlockRepository {
  final StreamController<Set<String>> invisibleUserIdsController =
      StreamController<Set<String>>.broadcast();
  bool hasBlockRelationshipResult = false;

  Future<void> dispose() async {
    await invisibleUserIdsController.close();
  }

  @override
  Stream<Set<String>> watchInvisibleUserIds(String uid) {
    return invisibleUserIdsController.stream;
  }

  @override
  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  }) async {
    return hasBlockRelationshipResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
