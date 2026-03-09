import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

class AirportFirestoreDataSource {
  AirportFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static final RegExp _dodoCodePattern = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$',
  );
  static const String _duplicateVisitReportErrorCode =
      'duplicate_airport_visit_report';
  static const String _tradeLinkedSourceType = 'market_trade';
  static const String _tradeRequestIdPrefix = 'trade_';

  final FirebaseFirestore _firestore;

  Stream<AirportSession?> watchSession(String islandId) {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return Stream<AirportSession?>.value(null);
    }

    return _firestore
        .doc(FirestorePaths.airportQueue(normalizedIslandId))
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (!doc.exists || data == null) {
            return null;
          }
          return AirportSession.fromMap(islandId: doc.id, data: data);
        });
  }

  Stream<List<AirportVisitRequest>> watchIncomingRequests(String islandId) {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return Stream<List<AirportVisitRequest>>.value(
        const <AirportVisitRequest>[],
      );
    }

    return _firestore
        .collection(FirestorePaths.airportRequests(normalizedIslandId))
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <AirportVisitRequest>[];
          final tradeRequestRefsByOffer =
              <String, List<DocumentReference<Map<String, dynamic>>>>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final request = AirportVisitRequest.fromMap(
              id: doc.id,
              islandId: normalizedIslandId,
              data: data,
            );
            requests.add(request);

            final sourceOfferId = _resolveTradeSourceOfferId(
              requestId: doc.id,
              sourceType: (data['sourceType'] as String?)?.trim() ?? '',
              sourceOfferId: (data['sourceOfferId'] as String?)?.trim() ?? '',
            );
            if (request.isActive && sourceOfferId.isNotEmpty) {
              tradeRequestRefsByOffer
                  .putIfAbsent(
                    sourceOfferId,
                    () => <DocumentReference<Map<String, dynamic>>>[],
                  )
                  .add(doc.reference);
            }
          }

          final filtered = await _filterAndCleanupStaleTradeRequests(
            requests: requests,
            tradeRequestRefsByOffer: tradeRequestRefsByOffer,
          );
          filtered.sort(_sortIncomingRequests);
          return filtered;
        });
  }

  Stream<List<AirportVisitRequest>> watchMyRequests(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<List<AirportVisitRequest>>.value(
        const <AirportVisitRequest>[],
      );
    }
    return _firestore
        .collectionGroup('requests')
        .where('requesterUid', isEqualTo: normalizedUid)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <AirportVisitRequest>[];
          final tradeRequestRefsByOffer =
              <String, List<DocumentReference<Map<String, dynamic>>>>{};
          for (final doc in snapshot.docs) {
            final segments = doc.reference.path.split('/');
            if (segments.length < 4 || segments[0] != 'airportQueues') {
              continue;
            }
            final islandId = segments[1];
            final data = doc.data();
            final request = AirportVisitRequest.fromMap(
              id: doc.id,
              islandId: islandId,
              data: data,
            );
            requests.add(request);

            final sourceOfferId = _resolveTradeSourceOfferId(
              requestId: doc.id,
              sourceType: (data['sourceType'] as String?)?.trim() ?? '',
              sourceOfferId: (data['sourceOfferId'] as String?)?.trim() ?? '',
            );
            if (request.isActive && sourceOfferId.isNotEmpty) {
              tradeRequestRefsByOffer
                  .putIfAbsent(
                    sourceOfferId,
                    () => <DocumentReference<Map<String, dynamic>>>[],
                  )
                  .add(doc.reference);
            }
          }
          final filtered = await _filterAndCleanupStaleTradeRequests(
            requests: requests,
            tradeRequestRefsByOffer: tradeRequestRefsByOffer,
          );
          filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return filtered;
        });
  }

  Stream<List<AirportSession>> watchOpenSessions() {
    return _firestore
        .collection(FirestorePaths.airportQueues())
        .where('gateOpen', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map(
                (doc) =>
                    AirportSession.fromMap(islandId: doc.id, data: doc.data()),
              )
              .toList(growable: false);
          sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return sessions;
        });
  }

  Future<void> ensureSession({required AirportSession session}) async {
    final normalizedIslandId = session.islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    final queueRef = _firestore.doc(
      FirestorePaths.airportQueue(normalizedIslandId),
    );
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(queueRef);
      final payload = <String, dynamic>{
        ...session.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!snapshot.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(queueRef, payload, SetOptions(merge: true));
    });
  }

  Future<void> setGateOpen({
    required String islandId,
    required bool gateOpen,
  }) async {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    await _firestore.doc(FirestorePaths.airportQueue(normalizedIslandId)).set(
      <String, dynamic>{
        'gateOpen': gateOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updatePurposeAndIntro({
    required String islandId,
    required AirportVisitPurpose purpose,
    required String introMessage,
  }) async {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    await _firestore
        .doc(FirestorePaths.airportQueue(normalizedIslandId))
        .set(<String, dynamic>{
          'purpose': purpose.name,
          'introMessage': introMessage.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> updateRules({
    required String islandId,
    required String rules,
  }) async {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    await _firestore.doc(FirestorePaths.airportQueue(normalizedIslandId)).set(
      <String, dynamic>{
        'rules': rules.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateDodoCode({
    required String islandId,
    required String dodoCode,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedCode = dodoCode.trim().toUpperCase();
    if (normalizedIslandId.isEmpty) {
      return;
    }
    if (!_dodoCodePattern.hasMatch(normalizedCode)) {
      throw const FormatException('invalid_dodo_code');
    }

    await _firestore
        .doc(FirestorePaths.airportQueue(normalizedIslandId))
        .set(<String, dynamic>{
          'dodoCode': normalizedCode,
          'dodoCodeUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> resetDodoCode(String islandId) async {
    final normalizedIslandId = islandId.trim();
    if (normalizedIslandId.isEmpty) {
      return;
    }

    await _firestore
        .doc(FirestorePaths.airportQueue(normalizedIslandId))
        .set(<String, dynamic>{
          'dodoCode': '',
          'dodoCodeUpdatedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

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
    final normalizedIslandId = islandId.trim();
    final normalizedHostUid = hostUid.trim();
    final normalizedRequesterUid = requesterUid.trim();
    if (normalizedIslandId.isEmpty ||
        normalizedHostUid.isEmpty ||
        normalizedRequesterUid.isEmpty) {
      throw StateError('invalid_airport_request_payload');
    }
    if (normalizedHostUid == normalizedRequesterUid) {
      throw StateError('cannot_request_own_island');
    }

    final requestCollection = _firestore.collection(
      FirestorePaths.airportRequests(normalizedIslandId),
    );

    // 유지보수 포인트:
    // 같은 섬에 대해 활성 상태(대기/초대/입장) 요청은 1건만 유지합니다.
    final existing = await requestCollection
        .where('requesterUid', isEqualTo: normalizedRequesterUid)
        .get();
    for (final doc in existing.docs) {
      final status = AirportVisitRequestStatus.fromName(
        doc.data()['status'] as String?,
      );
      if (status == AirportVisitRequestStatus.pending ||
          status == AirportVisitRequestStatus.invited ||
          status == AirportVisitRequestStatus.arrived) {
        throw StateError('already_requested');
      }
    }

    final requestDoc = requestCollection.doc();
    await requestDoc.set(<String, dynamic>{
      'islandId': normalizedIslandId,
      'hostUid': normalizedHostUid,
      'hostName': hostName.trim(),
      'hostIslandName': hostIslandName.trim(),
      'hostIslandImageUrl': hostIslandImageUrl.trim(),
      'requesterUid': normalizedRequesterUid,
      'requesterName': requesterName.trim(),
      'requesterAvatarUrl': requesterAvatarUrl.trim(),
      'requesterIslandName': requesterIslandName.trim(),
      'requesterIslandImageUrl': requesterIslandImageUrl.trim(),
      'purpose': purpose.name,
      'message': message.trim(),
      'status': AirportVisitRequestStatus.pending.name,
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'invitedAt': FieldValue.delete(),
      'arrivedAt': FieldValue.delete(),
      'inviteCode': FieldValue.delete(),
      'sourceType': sourceType?.trim(),
      'sourceOfferId': sourceOfferId?.trim(),
      'sourceMoveType': sourceMoveType?.trim(),
    });
  }

  Future<void> cancelVisitRequest({
    required String islandId,
    required String requestId,
    required String cancelByUid,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedRequestId = requestId.trim();
    final normalizedCancelByUid = cancelByUid.trim();
    if (normalizedIslandId.isEmpty ||
        normalizedRequestId.isEmpty ||
        normalizedCancelByUid.isEmpty) {
      return;
    }

    await _firestore
        .doc(
          FirestorePaths.airportRequest(
            normalizedIslandId,
            normalizedRequestId,
          ),
        )
        .set(<String, dynamic>{
          'status': AirportVisitRequestStatus.cancelled.name,
          'cancelByUid': normalizedCancelByUid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> inviteRequests({
    required String islandId,
    required List<String> requestIds,
    required String dodoCode,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedCode = dodoCode.trim().toUpperCase();
    if (normalizedIslandId.isEmpty || requestIds.isEmpty) {
      return;
    }
    if (!_dodoCodePattern.hasMatch(normalizedCode)) {
      throw const FormatException('invalid_dodo_code');
    }

    final batch = _firestore.batch();
    for (final requestId in requestIds) {
      final normalizedRequestId = requestId.trim();
      if (normalizedRequestId.isEmpty) {
        continue;
      }
      batch.set(
        _firestore.doc(
          FirestorePaths.airportRequest(
            normalizedIslandId,
            normalizedRequestId,
          ),
        ),
        <String, dynamic>{
          'status': AirportVisitRequestStatus.invited.name,
          'inviteCode': normalizedCode,
          'invitedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      _firestore.doc(FirestorePaths.airportQueue(normalizedIslandId)),
      <String, dynamic>{
        'dodoCode': normalizedCode,
        'dodoCodeUpdatedAt': FieldValue.serverTimestamp(),
        'gateOpen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> markArrived({
    required String islandId,
    required String requestId,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedRequestId = requestId.trim();
    if (normalizedIslandId.isEmpty || normalizedRequestId.isEmpty) {
      return;
    }

    await _firestore
        .doc(
          FirestorePaths.airportRequest(
            normalizedIslandId,
            normalizedRequestId,
          ),
        )
        .set(<String, dynamic>{
          'status': AirportVisitRequestStatus.arrived.name,
          'arrivedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> completeVisit({
    required String islandId,
    required String requestId,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedRequestId = requestId.trim();
    if (normalizedIslandId.isEmpty || normalizedRequestId.isEmpty) {
      return;
    }

    final requestRef = _firestore.doc(
      FirestorePaths.airportRequest(normalizedIslandId, normalizedRequestId),
    );
    final requestSnapshot = await requestRef.get();
    final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
    final sourceOfferId = _resolveTradeSourceOfferId(
      requestId: normalizedRequestId,
      sourceType: (requestData['sourceType'] as String?)?.trim() ?? '',
      sourceOfferId: (requestData['sourceOfferId'] as String?)?.trim() ?? '',
    );

    final targetRefs = <DocumentReference<Map<String, dynamic>>>[];
    if (sourceOfferId.isNotEmpty) {
      try {
        final relatedDocs = await _findTradeLinkedRequestDocsByOfferId(
          sourceOfferId,
        );
        for (final doc in relatedDocs) {
          final statusName = (doc.data()['status'] as String?)?.trim() ?? '';
          if (!_isActiveRequestStatusName(statusName)) {
            continue;
          }
          targetRefs.add(doc.reference);
        }
      } catch (_) {}
    }
    if (targetRefs.every((ref) => ref.path != requestRef.path)) {
      targetRefs.add(requestRef);
    }

    final sameIslandRefs = <DocumentReference<Map<String, dynamic>>>[];
    final crossIslandRefs = <DocumentReference<Map<String, dynamic>>>[];
    final seenPaths = <String>{};
    for (final ref in targetRefs) {
      if (!seenPaths.add(ref.path)) {
        continue;
      }
      final refIslandId = _extractIslandIdFromRequestRefPath(ref.path);
      if (refIslandId == normalizedIslandId) {
        sameIslandRefs.add(ref);
      } else {
        crossIslandRefs.add(ref);
      }
    }
    if (sameIslandRefs.isEmpty) {
      sameIslandRefs.add(requestRef);
    }

    final payload = <String, dynamic>{
      'status': AirportVisitRequestStatus.completed.name,
      'inviteCode': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    for (final ref in sameIslandRefs) {
      batch.set(ref, payload, SetOptions(merge: true));
    }
    await batch.commit();

    for (final ref in crossIslandRefs) {
      try {
        await ref.set(payload, SetOptions(merge: true));
      } catch (_) {
        // 유지보수 포인트:
        // 교차 섬 요청 동기화는 권한/규칙에 따라 실패할 수 있으므로
        // 현재 섬 방문 종료 처리 자체는 성공으로 유지합니다.
      }
    }
  }

  String _extractIslandIdFromRequestRefPath(String path) {
    final segments = path.split('/');
    if (segments.length < 4) {
      return '';
    }
    if (segments[0] != 'airportQueues' || segments[2] != 'requests') {
      return '';
    }
    return segments[1];
  }

  Future<void> reportVisitRequester({
    required String islandId,
    required String requestId,
    required String hostUid,
    required String requesterUid,
    required String reporterUid,
    String? sourceType,
    String? sourceOfferId,
  }) async {
    final normalizedIslandId = islandId.trim();
    final normalizedRequestId = requestId.trim();
    final normalizedHostUid = hostUid.trim();
    final normalizedRequesterUid = requesterUid.trim();
    final normalizedReporterUid = reporterUid.trim();
    final normalizedSourceType = sourceType?.trim() ?? '';
    final normalizedSourceOfferId = sourceOfferId?.trim() ?? '';
    if (normalizedIslandId.isEmpty ||
        normalizedRequestId.isEmpty ||
        normalizedHostUid.isEmpty ||
        normalizedRequesterUid.isEmpty ||
        normalizedReporterUid.isEmpty) {
      throw StateError('invalid_airport_report_payload');
    }
    if (normalizedReporterUid == normalizedRequesterUid) {
      throw StateError('cannot_report_self');
    }

    final reportRef = _firestore.doc(
      FirestorePaths.report(
        'airport_${normalizedIslandId}_${normalizedRequestId}_$normalizedReporterUid',
      ),
    );
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reportRef);
      if (existing.exists) {
        throw StateError(_duplicateVisitReportErrorCode);
      }
      transaction.set(reportRef, <String, dynamic>{
        'id': reportRef.id,
        'scope': 'airport',
        'targetType': 'visit_request',
        'targetId': normalizedRequestId,
        'islandId': normalizedIslandId,
        'requestHostUid': normalizedHostUid,
        'requestRequesterUid': normalizedRequesterUid,
        'reporterUid': normalizedReporterUid,
        'sourceType': normalizedSourceType,
        'sourceOfferId': normalizedSourceOfferId,
        'reason': 'waiting_guest_report',
        'detail': '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _resolveTradeSourceOfferId({
    required String requestId,
    required String sourceType,
    required String sourceOfferId,
  }) {
    final normalizedSourceOfferId = sourceOfferId.trim();
    if (normalizedSourceOfferId.isNotEmpty) {
      return normalizedSourceOfferId;
    }
    final normalizedSourceType = sourceType.trim();
    if (normalizedSourceType.isNotEmpty &&
        normalizedSourceType != _tradeLinkedSourceType) {
      return '';
    }
    final normalizedRequestId = requestId.trim();
    if (!normalizedRequestId.startsWith(_tradeRequestIdPrefix)) {
      return '';
    }
    return normalizedRequestId.substring(_tradeRequestIdPrefix.length).trim();
  }

  Future<List<AirportVisitRequest>> _filterAndCleanupStaleTradeRequests({
    required List<AirportVisitRequest> requests,
    required Map<String, List<DocumentReference<Map<String, dynamic>>>>
    tradeRequestRefsByOffer,
  }) async {
    if (requests.isEmpty || tradeRequestRefsByOffer.isEmpty) {
      return requests;
    }

    final staleOfferIds = await _findStaleTradeOfferIds(
      tradeRequestRefsByOffer.keys,
    );
    if (staleOfferIds.isEmpty) {
      return requests;
    }

    final filtered = requests
        .where((request) {
          if (!request.isActive) {
            return true;
          }
          final resolvedOfferId = _resolveTradeSourceOfferId(
            requestId: request.id,
            sourceType: request.sourceType?.trim() ?? '',
            sourceOfferId: request.sourceOfferId?.trim() ?? '',
          );
          return resolvedOfferId.isEmpty ||
              !staleOfferIds.contains(resolvedOfferId);
        })
        .toList(growable: false);

    // 유지보수 포인트:
    // 거래 완료/취소 직후에는 화면에서 먼저 숨기고,
    // 실제 요청 문서는 백그라운드에서 cancelled로 정리합니다.
    final staleRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final offerId in staleOfferIds) {
      final refs = tradeRequestRefsByOffer[offerId];
      if (refs == null || refs.isEmpty) {
        continue;
      }
      staleRefs.addAll(refs);
    }
    if (staleRefs.isNotEmpty) {
      unawaited(_cancelTradeRequestRefs(staleRefs));
    }

    return filtered;
  }

  Future<Set<String>> _findStaleTradeOfferIds(Iterable<String> offerIds) async {
    final stale = <String>{};
    final normalizedOfferIds = offerIds
        .map((offerId) => offerId.trim())
        .where((offerId) => offerId.isNotEmpty)
        .toSet();
    if (normalizedOfferIds.isEmpty) {
      return stale;
    }

    await Future.wait(
      normalizedOfferIds.map((offerId) async {
        try {
          final offerSnapshot = await _firestore
              .doc(FirestorePaths.marketPost(offerId))
              .get();
          final offerData = offerSnapshot.data();
          if (!offerSnapshot.exists || offerData == null) {
            stale.add(offerId);
            return;
          }

          final lifecycle = (offerData['lifecycle'] as String?)?.trim() ?? '';
          final status = (offerData['status'] as String?)?.trim() ?? '';
          final isClosedOrCancelled =
              lifecycle == 'cancelled' ||
              lifecycle == 'completed' ||
              status == 'offline' ||
              status == 'closed';
          if (isClosedOrCancelled) {
            stale.add(offerId);
          }
        } catch (_) {}
      }),
    );

    return stale;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _findTradeLinkedRequestDocsByOfferId(String offerId) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final docsByPath = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final bySourceOfferId = await _firestore
        .collectionGroup('requests')
        .where('sourceOfferId', isEqualTo: normalizedOfferId)
        .limit(50)
        .get();
    for (final doc in bySourceOfferId.docs) {
      final sourceType = (doc.data()['sourceType'] as String?)?.trim() ?? '';
      if (sourceType.isNotEmpty && sourceType != _tradeLinkedSourceType) {
        continue;
      }
      docsByPath[doc.reference.path] = doc;
    }

    final legacyRequestId = '$_tradeRequestIdPrefix$normalizedOfferId';
    final byLegacyRequestId = await _firestore
        .collectionGroup('requests')
        .where(FieldPath.documentId, isEqualTo: legacyRequestId)
        .limit(10)
        .get();
    for (final doc in byLegacyRequestId.docs) {
      docsByPath[doc.reference.path] = doc;
    }

    return docsByPath.values.toList(growable: false);
  }

  bool _isActiveRequestStatusName(String statusName) {
    return statusName == AirportVisitRequestStatus.pending.name ||
        statusName == AirportVisitRequestStatus.invited.name ||
        statusName == AirportVisitRequestStatus.arrived.name;
  }

  Future<void> _cancelTradeRequestRefs(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    if (refs.isEmpty) {
      return;
    }

    for (final requestRef in refs) {
      try {
        await requestRef.set(<String, dynamic>{
          'status': AirportVisitRequestStatus.cancelled.name,
          'inviteCode': FieldValue.delete(),
          'invitedAt': FieldValue.delete(),
          'arrivedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  int _sortIncomingRequests(AirportVisitRequest a, AirportVisitRequest b) {
    final rankA = _incomingStatusRank(a.status);
    final rankB = _incomingStatusRank(b.status);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    return a.requestedAt.compareTo(b.requestedAt);
  }

  int _incomingStatusRank(AirportVisitRequestStatus status) {
    switch (status) {
      case AirportVisitRequestStatus.pending:
        return 0;
      case AirportVisitRequestStatus.invited:
        return 1;
      case AirportVisitRequestStatus.arrived:
        return 2;
      case AirportVisitRequestStatus.cancelled:
        return 3;
      case AirportVisitRequestStatus.completed:
        return 4;
    }
  }
}
