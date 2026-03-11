import 'dart:async';

import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/data/datasource/airport_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';

class AirportRepositoryImpl implements AirportRepository {
  AirportRepositoryImpl({
    required AirportFirestoreDataSource dataSource,
    required AppTelemetry telemetry,
  }) : _dataSource = dataSource,
       _telemetry = telemetry;

  final AirportFirestoreDataSource _dataSource;
  final AppTelemetry _telemetry;

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
  Future<void> ensureSession({required AirportSession session}) async {
    try {
      await _dataSource.ensureSession(session: session);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportSessionEnsured,
          parameters: <String, Object>{
            'purpose': session.purpose.name,
            'gate_open': session.gateOpen,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.ensure_session',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> setGateOpen({
    required String islandId,
    required bool gateOpen,
  }) async {
    try {
      await _dataSource.setGateOpen(islandId: islandId, gateOpen: gateOpen);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportGateToggled,
          parameters: <String, Object>{'gate_open': gateOpen},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.set_gate_open',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePurposeAndIntro({
    required String islandId,
    required AirportVisitPurpose purpose,
    required String introMessage,
  }) async {
    try {
      await _dataSource.updatePurposeAndIntro(
        islandId: islandId,
        purpose: purpose,
        introMessage: introMessage,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportPurposeUpdated,
          parameters: <String, Object>{
            'purpose': purpose.name,
            'has_intro': introMessage.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.update_purpose_and_intro',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRules({
    required String islandId,
    required String rules,
  }) async {
    try {
      await _dataSource.updateRules(islandId: islandId, rules: rules);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportRulesUpdated,
          parameters: <String, Object>{'has_rules': rules.trim().isNotEmpty},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.update_rules',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> updateDodoCode({
    required String islandId,
    required String dodoCode,
  }) async {
    try {
      await _dataSource.updateDodoCode(islandId: islandId, dodoCode: dodoCode);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportDodoCodeUpdated,
          parameters: <String, Object>{'has_code': dodoCode.trim().isNotEmpty},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.update_dodo_code',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> resetDodoCode(String islandId) async {
    try {
      await _dataSource.resetDodoCode(islandId);
      unawaited(_telemetry.logEvent(AppTelemetryEvents.airportDodoCodeReset));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.reset_dodo_code',
        ),
      );
      rethrow;
    }
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
    try {
      await _dataSource.submitVisitRequest(
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
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportVisitRequested,
          parameters: <String, Object?>{
            'purpose': purpose.name,
            'source_type': sourceType,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.submit_visit_request',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelVisitRequest({
    required String islandId,
    required String requestId,
    required String cancelByUid,
  }) async {
    try {
      await _dataSource.cancelVisitRequest(
        islandId: islandId,
        requestId: requestId,
        cancelByUid: cancelByUid,
      );
      unawaited(_telemetry.logEvent(AppTelemetryEvents.airportVisitCancelled));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.cancel_visit_request',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> inviteRequests({
    required String islandId,
    required List<String> requestIds,
    required String dodoCode,
  }) async {
    try {
      await _dataSource.inviteRequests(
        islandId: islandId,
        requestIds: requestIds,
        dodoCode: dodoCode,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportInviteSent,
          parameters: <String, Object>{
            'request_count': requestIds.length,
            'has_code': dodoCode.trim().isNotEmpty,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.invite_requests',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> markArrived({
    required String islandId,
    required String requestId,
  }) async {
    try {
      await _dataSource.markArrived(islandId: islandId, requestId: requestId);
      unawaited(_telemetry.logEvent(AppTelemetryEvents.airportVisitArrived));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.mark_arrived',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> completeVisit({
    required String islandId,
    required String requestId,
  }) async {
    try {
      await _dataSource.completeVisit(islandId: islandId, requestId: requestId);
      unawaited(_telemetry.logEvent(AppTelemetryEvents.airportVisitCompleted));
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.complete_visit',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> reportVisitRequester({
    required String islandId,
    required String requestId,
    required String hostUid,
    required String requesterUid,
    required String reporterUid,
    String? sourceType,
    String? sourceOfferId,
  }) async {
    try {
      await _dataSource.reportVisitRequester(
        islandId: islandId,
        requestId: requestId,
        hostUid: hostUid,
        requesterUid: requesterUid,
        reporterUid: reporterUid,
        sourceType: sourceType,
        sourceOfferId: sourceOfferId,
      );
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.airportVisitReported,
          parameters: <String, Object?>{'source_type': sourceType},
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'airport.report_visit_requester',
        ),
      );
      rethrow;
    }
  }
}
