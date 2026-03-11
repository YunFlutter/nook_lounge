import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';

class AirportFirestoreDataSource {
  AirportFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  static const int _defaultAirportCapacity = 8;
  static final RegExp _dodoCodePattern = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$',
  );
  static const String _duplicateVisitReportErrorCode =
      'duplicate_airport_visit_report';
  static const String _tradeLinkedSourceType = 'market_trade';
  static const String _tradeRequestIdPrefix = 'trade_';
  static const String _receiverRuleAgreementMapField = 'receiverRuleAgreements';
  static const String _receiverRuleAgreedUidField = 'receiverRuleAgreedUid';
  static const String _receiverRuleAgreedCodeField = 'receiverRuleAgreedCode';
  static const String _receiverRuleAgreedAtField = 'receiverRuleAgreedAt';
  static const String _receiverRuleAgreementCodeKey = 'code';
  static const String _receiverRuleAgreementAtKey = 'agreedAt';

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
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final request = AirportVisitRequest.fromMap(
              id: doc.id,
              islandId: normalizedIslandId,
              data: data,
            );
            requests.add(request);
          }

          final filtered = await _filterAndCleanupStaleTradeRequests(
            requests: requests,
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
          }
          final filtered = await _filterAndCleanupStaleTradeRequests(
            requests: requests,
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
    final isQueuedTouchingTrade = sourceOfferId.isNotEmpty
        ? await _isQueuedTouchingTrade(sourceOfferId)
        : false;

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
          if (isQueuedTouchingTrade &&
              !_isSameTradeRequester(
                baseRequestData: requestData,
                candidateRequestData: doc.data(),
              )) {
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
      'status': AirportVisitRequestStatus.cancelled.name,
      'cancelByUid': normalizedCancelByUid,
      'inviteCode': FieldValue.delete(),
      'invitedAt': FieldValue.delete(),
      'arrivedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    for (final ref in sameIslandRefs) {
      batch.set(ref, payload, SetOptions(merge: true));
    }
    if (sourceOfferId.isNotEmpty) {
      await _stageMarketTradeCancellationForAirportRequest(
        batch: batch,
        offerId: sourceOfferId,
        requestData: requestData,
      );
    }
    await batch.commit();

    for (final ref in crossIslandRefs) {
      try {
        await ref.set(payload, SetOptions(merge: true));
      } catch (_) {
        // 유지보수 포인트:
        // 거래 연동 방문 취소는 다른 섬 큐에도 문서가 남을 수 있어
        // 현재 섬 요청은 우선 취소하고 교차 섬 정리는 가능 범위에서 이어갑니다.
      }
    }
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

    final normalizedRequestIds = requestIds
        .map((requestId) => requestId.trim())
        .where((requestId) => requestId.isNotEmpty)
        .toSet();
    if (normalizedRequestIds.isEmpty) {
      return;
    }

    final queueSnapshot = await _firestore
        .doc(FirestorePaths.airportQueue(normalizedIslandId))
        .get();
    final queueData = queueSnapshot.data() ?? const <String, dynamic>{};
    final capacity =
        ((queueData['capacity'] as num?)?.toInt() ?? _defaultAirportCapacity)
            .clamp(1, _defaultAirportCapacity);
    final approvedSnapshot = await _firestore
        .collection(FirestorePaths.airportRequests(normalizedIslandId))
        .where(
          'status',
          whereIn: <String>[
            AirportVisitRequestStatus.invited.name,
            AirportVisitRequestStatus.arrived.name,
          ],
        )
        .get();
    final approvedRequestIds = approvedSnapshot.docs
        .map((doc) => doc.id.trim())
        .where((requestId) => requestId.isNotEmpty)
        .toSet();
    final newApprovalCount = normalizedRequestIds
        .where((requestId) => !approvedRequestIds.contains(requestId))
        .length;
    if (approvedRequestIds.length + newApprovalCount > capacity) {
      throw StateError('airport_capacity_full');
    }

    final batch = _firestore.batch();
    for (final normalizedRequestId in normalizedRequestIds) {
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

    final requestRef = _firestore.doc(
      FirestorePaths.airportRequest(normalizedIslandId, normalizedRequestId),
    );
    final requestSnapshot = await requestRef.get();
    final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
    final status = AirportVisitRequestStatus.fromName(
      requestData['status'] as String?,
    );
    if (status == AirportVisitRequestStatus.arrived) {
      return;
    }

    final sourceOfferId = _resolveTradeSourceOfferId(
      requestId: normalizedRequestId,
      sourceType: (requestData['sourceType'] as String?)?.trim() ?? '',
      sourceOfferId: (requestData['sourceOfferId'] as String?)?.trim() ?? '',
    );
    if (sourceOfferId.isNotEmpty &&
        await _isQueuedTouchingTrade(sourceOfferId) &&
        await _hasOtherArrivedTradeRequest(
          offerId: sourceOfferId,
          excludingRequestId: normalizedRequestId,
        )) {
      // 유지보수 포인트:
      // 만지작 줄서기는 동시에 여러 명이 섬에 들어오지 않도록
      // arrived 상태를 한 번에 한 명만 허용합니다.
      throw StateError('touching_visit_already_in_progress');
    }

    await requestRef.set(<String, dynamic>{
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
    final isQueuedTouchingTrade = sourceOfferId.isNotEmpty
        ? await _isQueuedTouchingTrade(sourceOfferId)
        : false;

    final targetRefs = <DocumentReference<Map<String, dynamic>>>[];
    if (sourceOfferId.isNotEmpty && !isQueuedTouchingTrade) {
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

  Future<void> _stageMarketTradeCancellationForAirportRequest({
    required WriteBatch batch,
    required String offerId,
    required Map<String, dynamic> requestData,
  }) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return;
    }

    final offerRef = _firestore.doc(
      FirestorePaths.marketPost(normalizedOfferId),
    );
    final offerSnapshot = await offerRef.get();
    final offerData = offerSnapshot.data();
    if (!offerSnapshot.exists || offerData == null) {
      return;
    }

    final ownerUid = (offerData['ownerUid'] as String?)?.trim() ?? '';
    if (ownerUid.isEmpty) {
      return;
    }

    final moveType = _resolveTradeMoveType(
      offerData: offerData,
      requestData: requestData,
    );
    final proposalUid = _resolveTradeProposalUidForAirportRequest(
      ownerUid: ownerUid,
      hostUid: (requestData['hostUid'] as String?)?.trim() ?? '',
      requesterUid: (requestData['requesterUid'] as String?)?.trim() ?? '',
      moveType: moveType,
    );
    if (proposalUid.isEmpty) {
      return;
    }

    final proposalsRef = _firestore.collection(
      FirestorePaths.marketTradeProposals(normalizedOfferId),
    );
    final proposalsSnapshot = await proposalsRef.get();
    QueryDocumentSnapshot<Map<String, dynamic>>? selectedProposal;
    for (final doc in proposalsSnapshot.docs) {
      if (doc.id.trim() == proposalUid) {
        selectedProposal = doc;
        break;
      }
    }
    if (selectedProposal == null) {
      return;
    }

    final selectedStatus =
        (selectedProposal.data()['status'] as String?)?.trim() ?? '';
    final wasAccepted =
        selectedStatus == MarketTradeProposalStatus.accepted.name;
    final shouldCancelProposal =
        selectedStatus != MarketTradeProposalStatus.cancelled.name &&
        selectedStatus != MarketTradeProposalStatus.rejected.name;

    if (shouldCancelProposal) {
      batch.set(selectedProposal.reference, <String, dynamic>{
        'status': MarketTradeProposalStatus.cancelled.name,
        'acceptedAt': FieldValue.delete(),
        'acceptedAtMillis': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    final isQueuedTouchingTrade =
        (offerData['tradeType'] as String?)?.trim() ==
            MarketTradeType.touching.name &&
        moveType == MarketMoveType.host;
    if (isQueuedTouchingTrade) {
      final codeRef = _firestore.doc(
        FirestorePaths.marketTradeCode(normalizedOfferId),
      );
      final codeSnapshot = await codeRef.get();
      final codeData = codeSnapshot.data() ?? const <String, dynamic>{};
      if (codeSnapshot.exists) {
        final receiverUids = _splitUidCsv(
          (codeData['codeReceiverUid'] as String?)?.trim() ?? '',
        )..remove(proposalUid);
        final payload = <String, dynamic>{
          'codeReceiverUid': receiverUids.isEmpty
              ? FieldValue.delete()
              : _joinUidCsv(receiverUids),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        };
        _applyReceiverRuleAgreementPayload(
          payload,
          agreements: _removeReceiverRuleAgreementsForReceivers(
            _extractReceiverRuleAgreementMap(codeData),
            receiverUids: <String>{proposalUid},
          ),
        );
        batch.set(codeRef, payload, SetOptions(merge: true));
      }

      final hasOtherAcceptedProposal = proposalsSnapshot.docs.any((doc) {
        if (doc.id.trim() == proposalUid) {
          return false;
        }
        final status = (doc.data()['status'] as String?)?.trim() ?? '';
        return status == MarketTradeProposalStatus.accepted.name;
      });
      if (!hasOtherAcceptedProposal) {
        batch.set(offerRef, <String, dynamic>{
          'lifecycle': MarketLifecycleTab.ongoing.name,
          'status': MarketOfferStatus.open.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
          'actionLabel': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
      return;
    }

    if (!wasAccepted) {
      return;
    }

    for (final doc in proposalsSnapshot.docs) {
      if (doc.id.trim() == proposalUid) {
        continue;
      }
      final status = (doc.data()['status'] as String?)?.trim() ?? '';
      if (status != MarketTradeProposalStatus.rejected.name) {
        continue;
      }
      batch.set(doc.reference, <String, dynamic>{
        'status': MarketTradeProposalStatus.pending.name,
        'acceptedAt': FieldValue.delete(),
        'acceptedAtMillis': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    batch.set(offerRef, <String, dynamic>{
      'lifecycle': MarketLifecycleTab.ongoing.name,
      'status': MarketOfferStatus.open.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.delete(
      _firestore.doc(FirestorePaths.marketTradeCode(normalizedOfferId)),
    );
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

  bool _isSameTradeRequester({
    required Map<String, dynamic> baseRequestData,
    required Map<String, dynamic> candidateRequestData,
  }) {
    final baseRequesterUid =
        (baseRequestData['requesterUid'] as String?)?.trim() ?? '';
    final candidateRequesterUid =
        (candidateRequestData['requesterUid'] as String?)?.trim() ?? '';
    if (baseRequesterUid.isEmpty || candidateRequesterUid.isEmpty) {
      return false;
    }
    return baseRequesterUid == candidateRequesterUid;
  }

  MarketMoveType _resolveTradeMoveType({
    required Map<String, dynamic> offerData,
    required Map<String, dynamic> requestData,
  }) {
    final candidates = <String>[
      (offerData['moveType'] as String?)?.trim() ?? '',
      (requestData['sourceMoveType'] as String?)?.trim() ?? '',
    ];
    for (final candidate in candidates) {
      for (final moveType in MarketMoveType.values) {
        if (moveType.name == candidate) {
          return moveType;
        }
      }
    }
    return MarketMoveType.visitor;
  }

  String _resolveTradeProposalUidForAirportRequest({
    required String ownerUid,
    required String hostUid,
    required String requesterUid,
    required MarketMoveType moveType,
  }) {
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedHostUid = hostUid.trim();
    final normalizedRequesterUid = requesterUid.trim();

    if (moveType == MarketMoveType.host) {
      if (normalizedRequesterUid.isNotEmpty &&
          normalizedRequesterUid != normalizedOwnerUid) {
        return normalizedRequesterUid;
      }
      if (normalizedHostUid.isNotEmpty &&
          normalizedHostUid != normalizedOwnerUid) {
        return normalizedHostUid;
      }
      return normalizedRequesterUid;
    }

    if (normalizedHostUid.isNotEmpty &&
        normalizedHostUid != normalizedOwnerUid) {
      return normalizedHostUid;
    }
    if (normalizedRequesterUid.isNotEmpty &&
        normalizedRequesterUid != normalizedOwnerUid) {
      return normalizedRequesterUid;
    }
    return normalizedHostUid;
  }

  Set<String> _splitUidCsv(String raw) {
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  String _joinUidCsv(Iterable<String> uids) {
    final normalized =
        uids
            .map((uid) => uid.trim())
            .where((uid) => uid.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    return normalized.join(',');
  }

  void _applyReceiverRuleAgreementPayload(
    Map<String, dynamic> payload, {
    required Map<String, Map<String, dynamic>> agreements,
  }) {
    payload[_receiverRuleAgreementMapField] = agreements.isEmpty
        ? FieldValue.delete()
        : _serializeReceiverRuleAgreementMap(agreements);
    payload[_receiverRuleAgreedUidField] = FieldValue.delete();
    payload[_receiverRuleAgreedCodeField] = FieldValue.delete();
    payload[_receiverRuleAgreedAtField] = FieldValue.delete();
    payload['receiverRuleAgreedAtMillis'] = FieldValue.delete();
  }

  Map<String, Map<String, dynamic>> _extractReceiverRuleAgreementMap(
    Map<String, dynamic> data,
  ) {
    final agreements = <String, Map<String, dynamic>>{};
    final rawAgreements = data[_receiverRuleAgreementMapField];
    if (rawAgreements is! Map) {
      return agreements;
    }
    for (final entry in rawAgreements.entries) {
      final uid = entry.key.toString().trim();
      final rawAgreement = entry.value;
      if (uid.isEmpty || rawAgreement is! Map) {
        continue;
      }
      final code =
          (rawAgreement[_receiverRuleAgreementCodeKey] as String?)
              ?.trim()
              .toUpperCase() ??
          '';
      if (!_dodoCodePattern.hasMatch(code)) {
        continue;
      }
      agreements[uid] = <String, dynamic>{
        _receiverRuleAgreementCodeKey: code,
        if (rawAgreement[_receiverRuleAgreementAtKey] != null)
          _receiverRuleAgreementAtKey:
              rawAgreement[_receiverRuleAgreementAtKey],
      };
    }
    return agreements;
  }

  Map<String, dynamic> _serializeReceiverRuleAgreementMap(
    Map<String, Map<String, dynamic>> agreements,
  ) {
    final serialized = <String, dynamic>{};
    for (final entry in agreements.entries) {
      final uid = entry.key.trim();
      if (uid.isEmpty) {
        continue;
      }
      final code =
          (entry.value[_receiverRuleAgreementCodeKey] as String?)
              ?.trim()
              .toUpperCase() ??
          '';
      if (!_dodoCodePattern.hasMatch(code)) {
        continue;
      }
      serialized[uid] = <String, dynamic>{
        _receiverRuleAgreementCodeKey: code,
        if (entry.value[_receiverRuleAgreementAtKey] != null)
          _receiverRuleAgreementAtKey: entry.value[_receiverRuleAgreementAtKey],
      };
    }
    return serialized;
  }

  Map<String, Map<String, dynamic>> _removeReceiverRuleAgreementsForReceivers(
    Map<String, Map<String, dynamic>> agreements, {
    required Set<String> receiverUids,
  }) {
    if (agreements.isEmpty || receiverUids.isEmpty) {
      return agreements.isEmpty
          ? const <String, Map<String, dynamic>>{}
          : <String, Map<String, dynamic>>{...agreements};
    }
    final next = <String, Map<String, dynamic>>{};
    for (final entry in agreements.entries) {
      if (receiverUids.contains(entry.key)) {
        continue;
      }
      next[entry.key] = <String, dynamic>{...entry.value};
    }
    return next;
  }

  Future<List<AirportVisitRequest>> _filterAndCleanupStaleTradeRequests({
    required List<AirportVisitRequest> requests,
  }) async {
    if (requests.isEmpty) {
      return requests;
    }

    final staleRequestPaths = await _resolveStaleTradeRequestPaths(requests);
    if (staleRequestPaths.isEmpty) {
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
          if (resolvedOfferId.isEmpty) {
            return true;
          }
          final requestPath = FirestorePaths.airportRequest(
            request.islandId,
            request.id,
          );
          return !staleRequestPaths.contains(requestPath);
        })
        .toList(growable: false);

    // 유지보수 포인트:
    // 거래 취소/거절 반영이 늦더라도 화면에서는 즉시 숨기고,
    // 실제 요청 문서는 백그라운드에서 cancelled로 정리합니다.
    final staleRefs = staleRequestPaths
        .map((path) => _firestore.doc(path))
        .toList(growable: false);
    if (staleRefs.isNotEmpty) {
      unawaited(_cancelTradeRequestRefs(staleRefs));
    }

    return filtered;
  }

  Future<Set<String>> _resolveStaleTradeRequestPaths(
    List<AirportVisitRequest> requests,
  ) async {
    final stalePaths = <String>{};
    final offerCache = <String, Map<String, dynamic>?>{};
    final proposalStatusCache = <String, String>{};

    await Future.wait(
      requests.map((request) async {
        if (!request.isActive) {
          return;
        }

        final offerId = _resolveTradeSourceOfferId(
          requestId: request.id,
          sourceType: request.sourceType?.trim() ?? '',
          sourceOfferId: request.sourceOfferId?.trim() ?? '',
        );
        if (offerId.isEmpty) {
          return;
        }

        final isStale = await _isTradeRequestStale(
          request: request,
          offerId: offerId,
          offerCache: offerCache,
          proposalStatusCache: proposalStatusCache,
        );
        if (!isStale) {
          return;
        }
        stalePaths.add(
          FirestorePaths.airportRequest(request.islandId, request.id),
        );
      }),
    );

    return stalePaths;
  }

  Future<bool> _isTradeRequestStale({
    required AirportVisitRequest request,
    required String offerId,
    required Map<String, Map<String, dynamic>?> offerCache,
    required Map<String, String> proposalStatusCache,
  }) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return false;
    }

    Map<String, dynamic>? offerData;
    if (offerCache.containsKey(normalizedOfferId)) {
      offerData = offerCache[normalizedOfferId];
    } else {
      try {
        final snapshot = await _firestore
            .doc(FirestorePaths.marketPost(normalizedOfferId))
            .get();
        offerData = snapshot.exists ? snapshot.data() : null;
      } catch (_) {
        return false;
      }
      offerCache[normalizedOfferId] = offerData;
    }
    if (offerData == null) {
      return true;
    }

    final lifecycle = (offerData['lifecycle'] as String?)?.trim() ?? '';
    final offerStatus = (offerData['status'] as String?)?.trim() ?? '';
    final isClosedOrCancelled =
        lifecycle == MarketLifecycleTab.cancelled.name ||
        lifecycle == MarketLifecycleTab.completed.name ||
        offerStatus == MarketOfferStatus.offline.name ||
        offerStatus == MarketOfferStatus.closed.name;
    if (isClosedOrCancelled) {
      return true;
    }

    if (request.status == AirportVisitRequestStatus.arrived) {
      // 유지보수 포인트:
      // 방문 확인으로 이미 입장 처리된 손님은 거래가 진행 중인 동안
      // proposal 조회/동기화 지연이 있어도 현재 방문객 명단에서 우선 보여줍니다.
      return false;
    }

    final ownerUid = (offerData['ownerUid'] as String?)?.trim() ?? '';
    if (ownerUid.isEmpty) {
      return true;
    }

    final requestData = <String, dynamic>{
      'hostUid': request.hostUid,
      'requesterUid': request.requesterUid,
      'sourceMoveType': request.sourceMoveType,
    };
    final moveType = _resolveTradeMoveType(
      offerData: offerData,
      requestData: requestData,
    );
    final proposalUid = _resolveTradeProposalUidForAirportRequest(
      ownerUid: ownerUid,
      hostUid: request.hostUid,
      requesterUid: request.requesterUid,
      moveType: moveType,
    );
    if (proposalUid.isEmpty) {
      return true;
    }

    final proposalCacheKey = '$normalizedOfferId:$proposalUid';
    String proposalStatus;
    if (proposalStatusCache.containsKey(proposalCacheKey)) {
      proposalStatus = proposalStatusCache[proposalCacheKey] ?? '';
    } else {
      try {
        final snapshot = await _firestore
            .doc(
              FirestorePaths.marketTradeProposal(
                normalizedOfferId,
                proposalUid,
              ),
            )
            .get();
        proposalStatus = (snapshot.data()?['status'] as String?)?.trim() ?? '';
      } catch (_) {
        return false;
      }
      proposalStatusCache[proposalCacheKey] = proposalStatus;
    }

    if (proposalStatus != MarketTradeProposalStatus.accepted.name) {
      return true;
    }

    return false;
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

    if (docsByPath.isEmpty) {
      try {
        final legacyRequestId = '$_tradeRequestIdPrefix$normalizedOfferId';
        final byLegacyRequestId = await _firestore
            .collectionGroup('requests')
            .where(FieldPath.documentId, isEqualTo: legacyRequestId)
            .limit(10)
            .get();
        for (final doc in byLegacyRequestId.docs) {
          docsByPath[doc.reference.path] = doc;
        }
      } catch (_) {
        // 유지보수 포인트:
        // 일부 SDK 조합에서 collectionGroup + documentId equalTo 파싱 오류가 있어
        // 레거시 fallback 조회 실패는 무시하고 sourceOfferId 기반 문서만 사용합니다.
      }
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

  Future<bool> _isQueuedTouchingTrade(String offerId) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return false;
    }

    try {
      final offerSnapshot = await _firestore
          .doc(FirestorePaths.marketPost(normalizedOfferId))
          .get();
      final offerData = offerSnapshot.data() ?? const <String, dynamic>{};
      if (!offerSnapshot.exists) {
        return false;
      }
      return (offerData['tradeType'] as String?)?.trim() ==
              MarketTradeType.touching.name &&
          (offerData['moveType'] as String?)?.trim() ==
              MarketMoveType.host.name;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasOtherArrivedTradeRequest({
    required String offerId,
    required String excludingRequestId,
  }) async {
    final relatedDocs = await _findTradeLinkedRequestDocsByOfferId(offerId);
    for (final doc in relatedDocs) {
      if (doc.id == excludingRequestId) {
        continue;
      }
      final statusName = (doc.data()['status'] as String?)?.trim() ?? '';
      if (statusName == AirportVisitRequestStatus.arrived.name) {
        return true;
      }
    }
    return false;
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
