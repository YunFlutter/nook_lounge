import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

abstract class AirportRepository {
  Stream<AirportSession?> watchSession(String islandId);

  Stream<List<AirportVisitRequest>> watchIncomingRequests(String islandId);

  Stream<List<AirportVisitRequest>> watchMyRequests(String uid);

  Stream<List<AirportSession>> watchOpenSessions();

  Future<void> ensureSession({required AirportSession session});

  Future<void> setGateOpen({required String islandId, required bool gateOpen});

  Future<void> updatePurposeAndIntro({
    required String islandId,
    required AirportVisitPurpose purpose,
    required String introMessage,
  });

  Future<void> updateRules({required String islandId, required String rules});

  Future<void> updateDodoCode({
    required String islandId,
    required String dodoCode,
  });

  Future<void> resetDodoCode(String islandId);

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
  });

  Future<void> cancelVisitRequest({
    required String islandId,
    required String requestId,
    required String cancelByUid,
  });

  Future<void> inviteRequests({
    required String islandId,
    required List<String> requestIds,
    required String dodoCode,
  });

  Future<void> markArrived({
    required String islandId,
    required String requestId,
  });

  Future<void> completeVisit({
    required String islandId,
    required String requestId,
  });
}
