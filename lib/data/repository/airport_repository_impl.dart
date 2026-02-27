import 'package:nook_lounge_app/data/datasource/airport_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';

class AirportRepositoryImpl implements AirportRepository {
  AirportRepositoryImpl({required AirportFirestoreDataSource dataSource})
    : _dataSource = dataSource;

  final AirportFirestoreDataSource _dataSource;

  @override
  Stream<AirportSession?> watchSession(String islandId) {
    return _dataSource.watchSession(islandId);
  }

  @override
  Stream<List<AirportVisitRequest>> watchIncomingRequests(String islandId) {
    return _dataSource.watchIncomingRequests(islandId);
  }

  @override
  Stream<List<AirportVisitRequest>> watchMyRequests(String uid) {
    return _dataSource.watchMyRequests(uid);
  }

  @override
  Stream<List<AirportSession>> watchOpenSessions() {
    return _dataSource.watchOpenSessions();
  }

  @override
  Future<void> ensureSession({required AirportSession session}) {
    return _dataSource.ensureSession(session: session);
  }

  @override
  Future<void> setGateOpen({required String islandId, required bool gateOpen}) {
    return _dataSource.setGateOpen(islandId: islandId, gateOpen: gateOpen);
  }

  @override
  Future<void> updatePurposeAndIntro({
    required String islandId,
    required AirportVisitPurpose purpose,
    required String introMessage,
  }) {
    return _dataSource.updatePurposeAndIntro(
      islandId: islandId,
      purpose: purpose,
      introMessage: introMessage,
    );
  }

  @override
  Future<void> updateRules({required String islandId, required String rules}) {
    return _dataSource.updateRules(islandId: islandId, rules: rules);
  }

  @override
  Future<void> updateDodoCode({
    required String islandId,
    required String dodoCode,
  }) {
    return _dataSource.updateDodoCode(islandId: islandId, dodoCode: dodoCode);
  }

  @override
  Future<void> resetDodoCode(String islandId) {
    return _dataSource.resetDodoCode(islandId);
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
  }) {
    return _dataSource.submitVisitRequest(
      islandId: islandId,
      hostUid: hostUid,
      hostName: hostName,
      hostIslandName: hostIslandName,
      hostIslandImageUrl: hostIslandImageUrl,
      requesterUid: requesterUid,
      requesterName: requesterName,
      requesterAvatarUrl: requesterAvatarUrl,
      requesterIslandName: requesterIslandName,
      requesterIslandImageUrl: requesterIslandImageUrl,
      purpose: purpose,
      message: message,
      sourceType: sourceType,
      sourceOfferId: sourceOfferId,
      sourceMoveType: sourceMoveType,
    );
  }

  @override
  Future<void> cancelVisitRequest({
    required String islandId,
    required String requestId,
    required String cancelByUid,
  }) {
    return _dataSource.cancelVisitRequest(
      islandId: islandId,
      requestId: requestId,
      cancelByUid: cancelByUid,
    );
  }

  @override
  Future<void> inviteRequests({
    required String islandId,
    required List<String> requestIds,
    required String dodoCode,
  }) {
    return _dataSource.inviteRequests(
      islandId: islandId,
      requestIds: requestIds,
      dodoCode: dodoCode,
    );
  }

  @override
  Future<void> markArrived({
    required String islandId,
    required String requestId,
  }) {
    return _dataSource.markArrived(islandId: islandId, requestId: requestId);
  }

  @override
  Future<void> completeVisit({
    required String islandId,
    required String requestId,
  }) {
    return _dataSource.completeVisit(islandId: islandId, requestId: requestId);
  }
}
