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
        .map((snapshot) {
          final requests = snapshot.docs
              .map(
                (doc) => AirportVisitRequest.fromMap(
                  id: doc.id,
                  islandId: normalizedIslandId,
                  data: doc.data(),
                ),
              )
              .toList(growable: false);
          requests.sort(_sortIncomingRequests);
          return requests;
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
        .map((snapshot) {
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

            final sourceType = (data['sourceType'] as String?)?.trim() ?? '';
            final sourceOfferId =
                (data['sourceOfferId'] as String?)?.trim() ?? '';
            if (request.isActive &&
                sourceType == 'market_trade' &&
                sourceOfferId.isNotEmpty) {
              tradeRequestRefsByOffer
                  .putIfAbsent(
                    sourceOfferId,
                    () => <DocumentReference<Map<String, dynamic>>>[],
                  )
                  .add(doc.reference);
            }
          }
          if (tradeRequestRefsByOffer.isNotEmpty) {
            // 유지보수 포인트:
            // "내가 대기 중인 섬 현황" 노출은 즉시 반영하고
            // 삭제/종료 거래 정리는 백그라운드로 수행해 실시간 체감 지연을 줄입니다.
            unawaited(_cleanupStaleTradeRequests(tradeRequestRefsByOffer));
          }

          requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return requests;
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

    await _firestore
        .doc(
          FirestorePaths.airportRequest(
            normalizedIslandId,
            normalizedRequestId,
          ),
        )
        .set(<String, dynamic>{
          'status': AirportVisitRequestStatus.completed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _cleanupStaleTradeRequests(
    Map<String, List<DocumentReference<Map<String, dynamic>>>>
    requestRefsByOfferId,
  ) async {
    if (requestRefsByOfferId.isEmpty) {
      return;
    }
    final staleOfferIds = await _findStaleTradeOfferIds(
      requestRefsByOfferId.keys,
    );
    if (staleOfferIds.isEmpty) {
      return;
    }

    final staleRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final offerId in staleOfferIds) {
      final refs = requestRefsByOfferId[offerId];
      if (refs == null || refs.isEmpty) {
        continue;
      }
      staleRefs.addAll(refs);
    }
    await _cancelTradeRequestRefs(staleRefs);
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
