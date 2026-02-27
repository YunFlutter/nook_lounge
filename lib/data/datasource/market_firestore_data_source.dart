import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';

class MarketFirestoreDataSource {
  static final RegExp _dodoCodePattern = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$',
  );
  static const String _tradeAirportSourceType = 'market_trade';
  static const String _tradeAirportRequestIdPrefix = 'trade_';

  MarketFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<MarketOffer>> watchOffers() {
    return _firestore.collection(FirestorePaths.marketPosts()).snapshots().map((
      snapshot,
    ) {
      final offers = <MarketOffer>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _migrateLegacyCreatedAtIfNeeded(doc.id, data);
        offers.add(MarketOffer.fromMap(id: doc.id, data: data));
      }
      offers.sort(_sortOffersForDisplay);
      return offers;
    });
  }

  Future<MarketOffer?> fetchOfferById(String offerId) async {
    final doc = await _firestore.doc(FirestorePaths.marketPost(offerId)).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return MarketOffer.fromMap(id: doc.id, data: data);
  }

  Future<void> createOffer(MarketOffer offer) async {
    final coverImage = offer.coverImageUrl.trim();
    if (_isLocalPath(coverImage)) {
      // 유지보수 포인트:
      // Firestore에는 로컬 경로 저장을 금지합니다.
      // 업로드 URL이 아닌 경로가 들어오면 실패시켜 데이터 오염을 차단합니다.
      throw StateError('coverImageUrl must be a remote URL');
    }
    final payload = <String, dynamic>{
      ...offer.toMap(),
      // 유지보수 포인트:
      // createdAtMillis(int) 레거시 필드는 저장 시 즉시 제거하고
      // createdAt(Timestamp)로만 관리합니다.
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    };
    await _firestore
        .doc(FirestorePaths.marketPost(offer.id))
        .set(payload, SetOptions(merge: true));
  }

  Future<void> updateOffer(MarketOffer offer) async {
    final coverImage = offer.coverImageUrl.trim();
    if (_isLocalPath(coverImage)) {
      throw StateError('coverImageUrl must be a remote URL');
    }
    final payload = <String, dynamic>{
      ...offer.toMap(),
      'createdAtMillis': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    };
    await _firestore
        .doc(FirestorePaths.marketPost(offer.id))
        .set(payload, SetOptions(merge: true));
  }

  Future<void> updateOfferLifecycle({
    required String offerId,
    required MarketLifecycleTab lifecycle,
    MarketOfferStatus? status,
  }) async {
    final payload = <String, dynamic>{
      'lifecycle': lifecycle.name,
      'createdAtMillis': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    };
    if (status != null) {
      payload['status'] = status.name;
    }
    await _firestore
        .doc(FirestorePaths.marketPost(offerId))
        .set(payload, SetOptions(merge: true));
  }

  Future<void> completeTrade({
    required String offerId,
    required String requesterUid,
    required String offerTitle,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedRequesterUid = requesterUid.trim();
    if (normalizedOfferId.isEmpty || normalizedRequesterUid.isEmpty) {
      throw StateError('invalid_trade_complete_payload');
    }

    final offerRef = _firestore.doc(
      FirestorePaths.marketPost(normalizedOfferId),
    );
    final offerSnapshot = await offerRef.get();
    final offerData = offerSnapshot.data();
    if (!offerSnapshot.exists || offerData == null) {
      throw StateError('trade_offer_not_found');
    }

    final ownerUid = (offerData['ownerUid'] as String?)?.trim() ?? '';
    if (ownerUid.isEmpty) {
      throw StateError('invalid_trade_owner');
    }
    final lifecycle = (offerData['lifecycle'] as String?)?.trim() ?? '';
    final status = (offerData['status'] as String?)?.trim() ?? '';
    final bool isAlreadyClosed =
        lifecycle == MarketLifecycleTab.cancelled.name ||
        lifecycle == MarketLifecycleTab.completed.name ||
        status == MarketOfferStatus.offline.name ||
        status == MarketOfferStatus.closed.name;
    if (isAlreadyClosed) {
      throw StateError('trade_complete_unavailable');
    }

    final codeRef = _firestore.doc(
      FirestorePaths.marketTradeCode(normalizedOfferId),
    );
    final codeSnapshot = await codeRef.get();
    final acceptedProposalSnapshot = await _firestore
        .collection(FirestorePaths.marketTradeProposals(normalizedOfferId))
        .where('status', isEqualTo: MarketTradeProposalStatus.accepted.name)
        .limit(1)
        .get();
    if (acceptedProposalSnapshot.docs.isEmpty) {
      // 유지보수 포인트:
      // 승낙된 상대가 없는 상태(취소 포함)에서는 거래 완료를 허용하지 않습니다.
      throw StateError('trade_complete_no_active_proposal');
    }
    final counterpartUid = acceptedProposalSnapshot.docs.first.id.trim();
    if (counterpartUid.isEmpty) {
      throw StateError('trade_complete_no_active_proposal');
    }

    final canComplete =
        normalizedRequesterUid == ownerUid ||
        normalizedRequesterUid == counterpartUid;
    if (!canComplete) {
      throw StateError('trade_complete_permission_denied');
    }

    final proposalsSnapshot = await _firestore
        .collection(FirestorePaths.marketTradeProposals(normalizedOfferId))
        .get();

    final batch = _firestore.batch();
    batch.set(offerRef, <String, dynamic>{
      'lifecycle': MarketLifecycleTab.completed.name,
      'status': MarketOfferStatus.closed.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    }, SetOptions(merge: true));

    for (final doc in proposalsSnapshot.docs) {
      final status = (doc.data()['status'] as String?) ?? '';
      final isCurrentCounterpart =
          counterpartUid.isNotEmpty && doc.id == counterpartUid;
      if (isCurrentCounterpart) {
        batch.set(doc.reference, <String, dynamic>{
          'status': MarketTradeProposalStatus.accepted.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));
        continue;
      }
      if (status == MarketTradeProposalStatus.pending.name ||
          status == MarketTradeProposalStatus.accepted.name) {
        batch.set(doc.reference, <String, dynamic>{
          'status': MarketTradeProposalStatus.rejected.name,
          'acceptedAt': FieldValue.delete(),
          'acceptedAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
    }

    if (codeSnapshot.exists) {
      batch.set(codeRef, <String, dynamic>{
        'completedAt': FieldValue.serverTimestamp(),
        'completedByUid': normalizedRequesterUid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    try {
      await _syncAirportRequestStatusByOffer(
        offerId: normalizedOfferId,
        status: AirportVisitRequestStatus.completed,
      );
    } catch (_) {}

    if (counterpartUid.isNotEmpty && counterpartUid != normalizedRequesterUid) {
      final normalizedTitle = offerTitle.trim().isEmpty
          ? '거래글'
          : offerTitle.trim();
      await _sendUserNotification(
        targetUid: counterpartUid,
        senderUid: normalizedRequesterUid,
        type: 'market_trade_complete',
        offerId: normalizedOfferId,
        title: '거래가 완료되었어요',
        body: '$normalizedTitle 거래가 완료 처리되었어요.',
      );
    }
  }

  Future<void> updateOfferBasicInfo({
    required String offerId,
    required String title,
    required String description,
  }) async {
    await _firestore
        .doc(FirestorePaths.marketPost(offerId))
        .set(<String, dynamic>{
          'title': title,
          'description': description,
          'createdAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
          'actionLabel': FieldValue.delete(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteOffer(String offerId) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return;
    }

    // 유지보수 포인트:
    // 거래글 삭제 시 하위 대기열(proposals) 문서가 남지 않도록
    // 선삭제 후 부모 문서를 제거합니다.
    await _deleteCollectionInBatches(
      FirestorePaths.marketTradeProposals(normalizedOfferId),
    );

    final batch = _firestore.batch();
    batch.delete(
      _firestore.doc(FirestorePaths.marketTradeCode(normalizedOfferId)),
    );
    batch.delete(_firestore.doc(FirestorePaths.marketPost(normalizedOfferId)));
    await batch.commit();
    try {
      // 유지보수 포인트:
      // 거래글 삭제 시에도 거래 연동 비행장 요청이 active로 남지 않도록
      // 취소 상태로 정리합니다.
      await _syncAirportRequestStatusByOffer(
        offerId: normalizedOfferId,
        status: AirportVisitRequestStatus.cancelled,
      );
    } catch (_) {}
  }

  Stream<List<MarketTradeProposal>> watchTradeProposals(String offerId) {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return const Stream<List<MarketTradeProposal>>.empty();
    }
    return _firestore
        .collection(FirestorePaths.marketTradeProposals(normalizedOfferId))
        .snapshots()
        .map((snapshot) {
          final proposals = snapshot.docs
              .map(
                (doc) => MarketTradeProposal.fromMap(
                  id: doc.id,
                  offerId: normalizedOfferId,
                  data: doc.data(),
                ),
              )
              .toList(growable: false);
          proposals.sort((a, b) {
            final statusRankA = _proposalStatusRank(a.status);
            final statusRankB = _proposalStatusRank(b.status);
            if (statusRankA != statusRankB) {
              return statusRankA.compareTo(statusRankB);
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });
          return proposals;
        });
  }

  Stream<MarketTradeProposal?> watchMyTradeProposal({
    required String offerId,
    required String proposerUid,
  }) {
    final normalizedOfferId = offerId.trim();
    final normalizedProposerUid = proposerUid.trim();
    if (normalizedOfferId.isEmpty || normalizedProposerUid.isEmpty) {
      return const Stream<MarketTradeProposal?>.empty();
    }
    return _firestore
        .doc(
          FirestorePaths.marketTradeProposal(
            normalizedOfferId,
            normalizedProposerUid,
          ),
        )
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) {
            return null;
          }
          return MarketTradeProposal.fromMap(
            id: snapshot.id,
            offerId: normalizedOfferId,
            data: data,
          );
        });
  }

  Future<void> sendTradeProposalNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) async {
    final trimmedOwnerUid = ownerUid.trim();
    final trimmedProposerUid = proposerUid.trim();
    if (trimmedOwnerUid.isEmpty || trimmedProposerUid.isEmpty) {
      return;
    }
    if (trimmedOwnerUid == trimmedProposerUid) {
      return;
    }

    final proposerRef = _firestore.doc(FirestorePaths.user(trimmedProposerUid));
    final proposerSnapshot = await proposerRef.get();
    final proposerData = proposerSnapshot.data() ?? const <String, dynamic>{};
    final proposerProfile = await _resolveProposerIdentity(
      proposerUid: trimmedProposerUid,
      proposerUserData: proposerData,
    );

    final proposalRef = _firestore.doc(
      FirestorePaths.marketTradeProposal(offerId, trimmedProposerUid),
    );
    final existingProposal = await proposalRef.get();
    final existingData = existingProposal.data();
    final existingStatus = (existingData?['status'] as String?)?.trim() ?? '';
    if (existingStatus == MarketTradeProposalStatus.pending.name ||
        existingStatus == MarketTradeProposalStatus.accepted.name) {
      throw StateError('trade_proposal_already_exists');
    }
    if (existingStatus == MarketTradeProposalStatus.rejected.name ||
        existingStatus == MarketTradeProposalStatus.cancelled.name) {
      // 유지보수 포인트:
      // 정책상 "다시 제안하기"를 지원하지 않으므로
      // 거절/취소된 제안은 재등록하지 않습니다.
      throw StateError('trade_reproposal_not_allowed');
    }

    await proposalRef.set(<String, dynamic>{
      'offerId': offerId,
      'ownerUid': trimmedOwnerUid,
      'proposerUid': trimmedProposerUid,
      'proposerName': proposerProfile.$1,
      'proposerAvatarUrl': proposerProfile.$2,
      'status': MarketTradeProposalStatus.pending.name,
      'createdAt': existingData != null && existingData['createdAt'] != null
          ? existingData['createdAt']
          : FieldValue.serverTimestamp(),
      'createdAtMillis': FieldValue.delete(),
      'acceptedAt': FieldValue.delete(),
      'acceptedAtMillis': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
    }, SetOptions(merge: true));

    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    final messageTitle = '새 거래 제안이 도착했어요';
    final messageBody = '$normalizedTitle 글에 거래 요청이 왔어요.';
    await _sendUserNotification(
      targetUid: trimmedOwnerUid,
      senderUid: trimmedProposerUid,
      type: 'market_trade_proposal',
      offerId: offerId,
      title: messageTitle,
      body: messageBody,
    );
  }

  Future<MarketTradeCodeSession> acceptTradeProposal({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedProposerUid = proposerUid.trim();
    if (normalizedOfferId.isEmpty ||
        normalizedOwnerUid.isEmpty ||
        normalizedProposerUid.isEmpty) {
      throw StateError('invalid_trade_proposal_accept_args');
    }
    if (normalizedOwnerUid == normalizedProposerUid) {
      throw StateError('cannot_accept_own_proposal');
    }

    final proposalsRef = _firestore.collection(
      FirestorePaths.marketTradeProposals(normalizedOfferId),
    );
    final existingProposals = await proposalsRef.get();
    final selectedRef = _firestore.doc(
      FirestorePaths.marketTradeProposal(
        normalizedOfferId,
        normalizedProposerUid,
      ),
    );

    final selectedSnapshot = await selectedRef.get();
    final selectedData = selectedSnapshot.data();
    String proposerName = '';
    String proposerAvatarUrl = '';
    final proposerRef = _firestore.doc(
      FirestorePaths.user(normalizedProposerUid),
    );
    final proposerProfileSnapshot = await proposerRef.get();
    final proposerProfileData =
        proposerProfileSnapshot.data() ?? const <String, dynamic>{};
    final resolvedProposerIdentity = await _resolveProposerIdentity(
      proposerUid: normalizedProposerUid,
      proposerUserData: proposerProfileData,
    );
    if (selectedData != null) {
      proposerName = (selectedData['proposerName'] as String?) ?? '';
      proposerAvatarUrl = (selectedData['proposerAvatarUrl'] as String?) ?? '';
      if (proposerName.trim().isEmpty) {
        proposerName = resolvedProposerIdentity.$1;
      }
      if (proposerAvatarUrl.trim().isEmpty) {
        proposerAvatarUrl = resolvedProposerIdentity.$2;
      }
    } else {
      proposerName = resolvedProposerIdentity.$1;
      proposerAvatarUrl = resolvedProposerIdentity.$2;
    }

    final batch = _firestore.batch();
    for (final proposalDoc in existingProposals.docs) {
      final proposalId = proposalDoc.id;
      if (proposalId == normalizedProposerUid) {
        batch.set(proposalDoc.reference, <String, dynamic>{
          'status': MarketTradeProposalStatus.accepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
          'acceptedAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));
        continue;
      }

      final status = (proposalDoc.data()['status'] as String?) ?? '';
      if (status == MarketTradeProposalStatus.pending.name ||
          status == MarketTradeProposalStatus.accepted.name) {
        batch.set(proposalDoc.reference, <String, dynamic>{
          'status': MarketTradeProposalStatus.rejected.name,
          'acceptedAt': FieldValue.delete(),
          'acceptedAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
    }

    if (!selectedSnapshot.exists) {
      batch.set(selectedRef, <String, dynamic>{
        'offerId': normalizedOfferId,
        'ownerUid': normalizedOwnerUid,
        'proposerUid': normalizedProposerUid,
        'proposerName': proposerName,
        'proposerAvatarUrl': proposerAvatarUrl,
        'status': MarketTradeProposalStatus.accepted.name,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMillis': FieldValue.delete(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedAtMillis': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    final offerRef = _firestore.doc(
      FirestorePaths.marketPost(normalizedOfferId),
    );
    batch.set(offerRef, <String, dynamic>{
      'status': MarketOfferStatus.waiting.name,
      'lifecycle': MarketLifecycleTab.ongoing.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
      'actionLabel': FieldValue.delete(),
    }, SetOptions(merge: true));

    await batch.commit();

    final session = await prepareTradeCodeSession(
      offerId: normalizedOfferId,
      ownerUid: normalizedOwnerUid,
      proposerUid: normalizedProposerUid,
      moveType: moveType,
    );

    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    try {
      await _syncAirportRequestForAcceptedTrade(
        offerId: normalizedOfferId,
        ownerUid: normalizedOwnerUid,
        proposerUid: normalizedProposerUid,
        moveType: moveType,
        offerTitle: normalizedTitle,
      );
    } catch (_) {
      // 유지보수 포인트:
      // 거래 승낙 자체는 실패시키지 않고 비행장 동기화는 재시도 가능한 보조 동작으로 둡니다.
    }
    await _sendUserNotification(
      targetUid: normalizedProposerUid,
      senderUid: normalizedOwnerUid,
      type: 'market_trade_accept',
      offerId: normalizedOfferId,
      title: '거래 승낙 알림',
      body: '$normalizedTitle 거래가 승낙되었어요. 코드를 확인해 주세요.',
    );
    return session;
  }

  Future<MarketTradeCodeSession> prepareTradeCodeSession({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedProposerUid = proposerUid.trim();
    if (normalizedOfferId.isEmpty ||
        normalizedOwnerUid.isEmpty ||
        normalizedProposerUid.isEmpty) {
      throw StateError('invalid_trade_code_session_args');
    }

    final codeSenderUid = moveType == MarketMoveType.visitor
        ? normalizedProposerUid
        : normalizedOwnerUid;
    final codeReceiverUid = codeSenderUid == normalizedOwnerUid
        ? normalizedProposerUid
        : normalizedOwnerUid;
    final docRef = _firestore.doc(FirestorePaths.marketTradeCode(offerId));

    await docRef.set(<String, dynamic>{
      'offerId': normalizedOfferId,
      'ownerUid': normalizedOwnerUid,
      'proposerUid': normalizedProposerUid,
      'moveType': moveType.name,
      'code': '',
      'codeSenderUid': codeSenderUid,
      'codeReceiverUid': codeReceiverUid,
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedAtMillis': FieldValue.delete(),
      'codeSentAt': FieldValue.delete(),
      'codeSentAtMillis': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtMillis': FieldValue.delete(),
    }, SetOptions(merge: true));

    final snap = await docRef.get();
    final data = snap.data();
    if (data == null) {
      final now = DateTime.now();
      return MarketTradeCodeSession(
        offerId: normalizedOfferId,
        ownerUid: normalizedOwnerUid,
        proposerUid: normalizedProposerUid,
        moveType: moveType,
        code: '',
        codeSenderUid: codeSenderUid,
        codeReceiverUid: codeReceiverUid,
        acceptedAt: now,
        updatedAt: now,
      );
    }
    return MarketTradeCodeSession.fromMap(
      offerId: normalizedOfferId,
      data: data,
    );
  }

  Stream<MarketTradeCodeSession?> watchTradeCodeSession(String offerId) {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return const Stream<MarketTradeCodeSession?>.empty();
    }
    return _firestore
        .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null) {
            return null;
          }
          return MarketTradeCodeSession.fromMap(
            offerId: normalizedOfferId,
            data: data,
          );
        });
  }

  Future<MarketTradeCodeSession?> fetchTradeCodeSession(String offerId) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return null;
    }
    final snapshot = await _firestore
        .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
        .get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return MarketTradeCodeSession.fromMap(
      offerId: normalizedOfferId,
      data: data,
    );
  }

  Future<String?> fetchPreferredTradeDodoCode({
    required String offerId,
    required String senderUid,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedSenderUid = senderUid.trim();
    if (normalizedOfferId.isEmpty || normalizedSenderUid.isEmpty) {
      return null;
    }

    try {
      final sessionSnapshot = await _firestore
          .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
          .get();
      final sessionData = sessionSnapshot.data() ?? const <String, dynamic>{};
      final codeSenderUid =
          (sessionData['codeSenderUid'] as String?)?.trim() ?? '';
      if (codeSenderUid.isNotEmpty && codeSenderUid != normalizedSenderUid) {
        return null;
      }

      final senderProfile = await _loadPrimaryIslandProfile(
        normalizedSenderUid,
      );
      if (senderProfile == null) {
        return null;
      }

      final queueSnapshot = await _firestore
          .doc(FirestorePaths.airportQueue(senderProfile.islandId))
          .get();
      final queueData = queueSnapshot.data() ?? const <String, dynamic>{};
      final presetCode =
          (queueData['dodoCode'] as String?)?.trim().toUpperCase() ?? '';
      if (!_dodoCodePattern.hasMatch(presetCode)) {
        return null;
      }
      return presetCode;
    } catch (_) {
      return null;
    }
  }

  Future<void> sendTradeAcceptNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) async {
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedProposerUid = proposerUid.trim();
    if (normalizedOwnerUid.isEmpty || normalizedProposerUid.isEmpty) {
      return;
    }
    if (normalizedOwnerUid == normalizedProposerUid) {
      return;
    }
    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    await _sendUserNotification(
      targetUid: normalizedProposerUid,
      senderUid: normalizedOwnerUid,
      type: 'market_trade_accept',
      offerId: offerId,
      title: '거래 승낙 알림',
      body: '$normalizedTitle 거래가 승낙되었어요. 코드를 확인해 주세요.',
    );
  }

  Future<void> sendTradeCode({
    required String offerId,
    required String senderUid,
    required String receiverUid,
    required String code,
    required String offerTitle,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedSenderUid = senderUid.trim();
    final normalizedReceiverUid = receiverUid.trim();
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedOfferId.isEmpty || normalizedSenderUid.isEmpty) {
      throw StateError('invalid_trade_code_payload');
    }
    if (!_dodoCodePattern.hasMatch(normalizedCode)) {
      throw StateError('invalid_trade_code_format');
    }

    var effectiveCode = normalizedCode;
    try {
      // 유지보수 포인트:
      // 비행장 조회/동기화가 실패해도 거래 코드 저장은 진행되어야 합니다.
      effectiveCode = await _resolveEffectiveTradeInviteCode(
        offerId: normalizedOfferId,
        senderUid: normalizedSenderUid,
        fallbackCode: normalizedCode,
      );
    } on StateError catch (error) {
      if (error.message == 'invalid_trade_code_format') {
        rethrow;
      }
      effectiveCode = normalizedCode;
    } catch (_) {
      effectiveCode = normalizedCode;
    }

    await _firestore
        .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
        .set(<String, dynamic>{
          'code': effectiveCode,
          'codeSentAt': FieldValue.serverTimestamp(),
          'codeSentAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));
    try {
      await _syncAirportInviteForTradeCode(
        offerId: normalizedOfferId,
        senderUid: normalizedSenderUid,
        inviteCode: effectiveCode,
        offerTitle: offerTitle,
      );
    } catch (_) {}

    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    if (normalizedReceiverUid.isNotEmpty) {
      try {
        // 유지보수 포인트:
        // 코드 저장(핵심 거래 동작)과 알림 전송(부가 동작)을 분리합니다.
        // 알림 권한/네트워크 이슈가 있어도 코드 전송 자체는 성공해야 합니다.
        await _sendUserNotification(
          targetUid: normalizedReceiverUid,
          senderUid: normalizedSenderUid,
          type: 'market_trade_code',
          offerId: normalizedOfferId,
          title: '거래 코드가 도착했어요',
          body: '$normalizedTitle 코드: $effectiveCode',
          extra: <String, dynamic>{'tradeCode': effectiveCode},
        );
      } catch (_) {}
    }
  }

  Future<String> _resolveEffectiveTradeInviteCode({
    required String offerId,
    required String senderUid,
    required String fallbackCode,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedSenderUid = senderUid.trim();
    final normalizedFallbackCode = fallbackCode.trim().toUpperCase();
    if (normalizedOfferId.isEmpty || normalizedSenderUid.isEmpty) {
      throw StateError('invalid_trade_code_payload');
    }

    DocumentReference<Map<String, dynamic>>? queueRef;
    Map<String, dynamic> queueData = const <String, dynamic>{};
    Map<String, dynamic> requestData = const <String, dynamic>{};

    final requestRef = await _findAirportTradeRequestRef(normalizedOfferId);
    if (requestRef != null) {
      final requestSnapshot = await requestRef.get();
      requestData = requestSnapshot.data() ?? const <String, dynamic>{};
      final hostUid = (requestData['hostUid'] as String?)?.trim() ?? '';
      if (hostUid == normalizedSenderUid) {
        final segments = requestRef.path.split('/');
        if (segments.length >= 2 && segments[0] == 'airportQueues') {
          queueRef = _firestore.doc(FirestorePaths.airportQueue(segments[1]));
          final queueSnapshot = await queueRef.get();
          queueData = queueSnapshot.data() ?? const <String, dynamic>{};
        }
      }
    }

    final hostProfile = await _loadPrimaryIslandProfile(normalizedSenderUid);
    if (queueRef == null && hostProfile != null) {
      queueRef = _firestore.doc(
        FirestorePaths.airportQueue(hostProfile.islandId),
      );
      final queueSnapshot = await queueRef.get();
      queueData = queueSnapshot.data() ?? const <String, dynamic>{};
    }

    final presetCode =
        (queueData['dodoCode'] as String?)?.trim().toUpperCase() ?? '';
    final hasPresetCode = _dodoCodePattern.hasMatch(presetCode);
    final effectiveCode = hasPresetCode ? presetCode : normalizedFallbackCode;
    if (!_dodoCodePattern.hasMatch(effectiveCode)) {
      throw StateError('invalid_trade_code_format');
    }

    if (queueRef != null) {
      // 유지보수 포인트:
      // 거래에서 코드를 보내는 시점에 비행장을 자동으로 열고,
      // 기존 코드가 있으면 그 코드를 우선 사용합니다.
      // 단, 비행장 동기화 실패가 코드 전송 실패로 이어지지 않도록 보호합니다.
      try {
        final payload = <String, dynamic>{
          'ownerUid': normalizedSenderUid,
          'gateOpen': true,
          'dodoCode': effectiveCode,
          'dodoCodeUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final islandName = _pickFirstNonEmpty(<Object?>[
          hostProfile?.islandName,
          queueData['islandName'],
          requestData['hostIslandName'],
        ]);
        if (islandName.isNotEmpty) {
          payload['islandName'] = islandName;
        }

        final hostName = _pickFirstNonEmpty(<Object?>[
          hostProfile?.representativeName,
          queueData['hostName'],
          requestData['hostName'],
        ]);
        if (hostName.isNotEmpty) {
          payload['hostName'] = hostName;
        }

        final hostAvatarUrl = _pickFirstNonEmpty(<Object?>[
          hostProfile?.imageUrl,
          queueData['hostAvatarUrl'],
          requestData['hostIslandImageUrl'],
        ]);
        if (hostAvatarUrl.isNotEmpty) {
          payload['hostAvatarUrl'] = hostAvatarUrl;
        }

        final islandImageUrl = _pickFirstNonEmpty(<Object?>[
          hostProfile?.imageUrl,
          queueData['islandImageUrl'],
          requestData['hostIslandImageUrl'],
        ]);
        if (islandImageUrl.isNotEmpty) {
          payload['islandImageUrl'] = islandImageUrl;
        }

        await queueRef.set(payload, SetOptions(merge: true));
      } catch (_) {}
    }

    return effectiveCode;
  }

  Future<void> cancelTrade({
    required String offerId,
    required String ownerUid,
    required String requesterUid,
    required String offerTitle,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedRequesterUid = requesterUid.trim();
    if (normalizedOfferId.isEmpty ||
        normalizedOwnerUid.isEmpty ||
        normalizedRequesterUid.isEmpty) {
      throw StateError('invalid_trade_cancel_payload');
    }

    final bool requesterIsOwner = normalizedRequesterUid == normalizedOwnerUid;
    final offerRef = _firestore.doc(
      FirestorePaths.marketPost(normalizedOfferId),
    );
    final proposalsRef = _firestore.collection(
      FirestorePaths.marketTradeProposals(normalizedOfferId),
    );
    final proposalsSnapshot = await proposalsRef.get();

    final WriteBatch batch = _firestore.batch();
    String counterpartUid = '';
    bool shouldReopenOffer = false;
    bool shouldCancelOffer = false;
    bool shouldDeleteCodeSession = false;

    if (requesterIsOwner) {
      QueryDocumentSnapshot<Map<String, dynamic>>? acceptedProposal;
      for (final doc in proposalsSnapshot.docs) {
        final status = (doc.data()['status'] as String?) ?? '';
        if (status == MarketTradeProposalStatus.accepted.name) {
          acceptedProposal = doc;
          break;
        }
      }

      if (acceptedProposal != null) {
        counterpartUid = acceptedProposal.id;
        shouldReopenOffer = true;
        shouldDeleteCodeSession = true;
        // 유지보수 포인트:
        // 승낙된 거래를 취소하면 대기열에서 "다시 선택" 가능해야 하므로
        // accepted/rejected 상태를 pending으로 되돌립니다.
        // 단, 사용자가 직접 취소한 cancelled 제안은 복구하지 않습니다.
        for (final doc in proposalsSnapshot.docs) {
          final status = (doc.data()['status'] as String?) ?? '';
          if (status == MarketTradeProposalStatus.accepted.name ||
              status == MarketTradeProposalStatus.rejected.name) {
            batch.set(doc.reference, <String, dynamic>{
              'status': MarketTradeProposalStatus.pending.name,
              'acceptedAt': FieldValue.delete(),
              'acceptedAtMillis': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedAtMillis': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
        }
      } else {
        // 유지보수 포인트:
        // 작성자가 거래를 취소하면 게시글 자체를 취소 상태로 돌리고
        // 남아있는 대기 제안도 모두 취소 처리합니다.
        shouldCancelOffer = true;
        shouldDeleteCodeSession = true;
        for (final doc in proposalsSnapshot.docs) {
          final status = (doc.data()['status'] as String?) ?? '';
          if (status == MarketTradeProposalStatus.pending.name ||
              status == MarketTradeProposalStatus.accepted.name) {
            batch.set(doc.reference, <String, dynamic>{
              'status': MarketTradeProposalStatus.cancelled.name,
              'acceptedAt': FieldValue.delete(),
              'acceptedAtMillis': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedAtMillis': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
        }
      }
    } else {
      final myProposalRef = _firestore.doc(
        FirestorePaths.marketTradeProposal(
          normalizedOfferId,
          normalizedRequesterUid,
        ),
      );
      final myProposalSnapshot = await myProposalRef.get();
      final myProposalData = myProposalSnapshot.data();
      if (!myProposalSnapshot.exists || myProposalData == null) {
        throw StateError('trade_proposal_not_found');
      }

      final proposalOwnerUid =
          (myProposalData['ownerUid'] as String?)?.trim() ?? '';
      if (proposalOwnerUid != normalizedOwnerUid) {
        throw StateError('trade_cancel_permission_denied');
      }

      final status =
          (myProposalData['status'] as String?) ??
          MarketTradeProposalStatus.pending.name;
      if (status == MarketTradeProposalStatus.cancelled.name ||
          status == MarketTradeProposalStatus.rejected.name) {
        return;
      }

      counterpartUid = normalizedOwnerUid;
      shouldDeleteCodeSession =
          status == MarketTradeProposalStatus.accepted.name;
      shouldReopenOffer = status == MarketTradeProposalStatus.accepted.name;
      batch.set(myProposalRef, <String, dynamic>{
        'status': MarketTradeProposalStatus.cancelled.name,
        'acceptedAt': FieldValue.delete(),
        'acceptedAtMillis': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
      }, SetOptions(merge: true));

      if (shouldReopenOffer) {
        // 유지보수 포인트:
        // 승낙된 제안자가 취소하면 다른 rejected 제안들을 pending으로 복구해
        // 작성자가 대기열에서 다시 승낙할 수 있게 합니다.
        for (final doc in proposalsSnapshot.docs) {
          if (doc.id == normalizedRequesterUid) {
            continue;
          }
          final otherStatus = (doc.data()['status'] as String?) ?? '';
          if (otherStatus == MarketTradeProposalStatus.rejected.name) {
            batch.set(doc.reference, <String, dynamic>{
              'status': MarketTradeProposalStatus.pending.name,
              'acceptedAt': FieldValue.delete(),
              'acceptedAtMillis': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedAtMillis': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
        }
      }
    }

    if (shouldReopenOffer) {
      batch.set(offerRef, <String, dynamic>{
        'lifecycle': MarketLifecycleTab.ongoing.name,
        'status': MarketOfferStatus.open.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
        'actionLabel': FieldValue.delete(),
      }, SetOptions(merge: true));
    } else if (shouldCancelOffer) {
      batch.set(offerRef, <String, dynamic>{
        'lifecycle': MarketLifecycleTab.cancelled.name,
        'status': MarketOfferStatus.offline.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
        'actionLabel': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    if (shouldDeleteCodeSession) {
      batch.delete(
        _firestore.doc(FirestorePaths.marketTradeCode(normalizedOfferId)),
      );
    }

    await batch.commit();
    try {
      await _syncAirportRequestStatusByOffer(
        offerId: normalizedOfferId,
        status: AirportVisitRequestStatus.cancelled,
      );
    } catch (_) {}

    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    if (counterpartUid.isNotEmpty && counterpartUid != normalizedRequesterUid) {
      await _sendUserNotification(
        targetUid: counterpartUid,
        senderUid: normalizedRequesterUid,
        type: 'market_trade_cancel',
        offerId: normalizedOfferId,
        title: '거래가 취소되었어요',
        body: '$normalizedTitle 거래가 취소되어 대기 상태로 변경되었어요.',
      );
    }
  }

  Future<void> reportTradeOffer({
    required String offerId,
    required String ownerUid,
    required String reporterUid,
    required String reason,
    required String detail,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedReporterUid = reporterUid.trim();
    final normalizedReason = reason.trim();
    final normalizedDetail = detail.trim();

    if (normalizedOfferId.isEmpty ||
        normalizedOwnerUid.isEmpty ||
        normalizedReporterUid.isEmpty ||
        normalizedReason.isEmpty) {
      throw StateError('invalid_trade_report_payload');
    }
    if (normalizedOwnerUid == normalizedReporterUid) {
      throw StateError('cannot_report_own_offer');
    }

    final reporterRef = _firestore.doc(
      FirestorePaths.user(normalizedReporterUid),
    );
    final reporterSnapshot = await reporterRef.get();
    final reporterData = reporterSnapshot.data() ?? const <String, dynamic>{};
    final (reporterName, reporterAvatarUrl) = await _resolveProposerIdentity(
      proposerUid: normalizedReporterUid,
      proposerUserData: reporterData,
    );

    final reportRef = _firestore.doc(
      FirestorePaths.report(
        'market_${normalizedOfferId}_${normalizedReporterUid}_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    await reportRef.set(<String, dynamic>{
      'id': reportRef.id,
      'scope': 'market',
      'targetType': 'offer',
      'targetId': normalizedOfferId,
      'offerOwnerUid': normalizedOwnerUid,
      'reporterUid': normalizedReporterUid,
      'reporterName': reporterName,
      'reporterAvatarUrl': reporterAvatarUrl,
      'reason': normalizedReason,
      'detail': normalizedDetail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Set<String>> watchHiddenOfferIds(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream<Set<String>>.value(const <String>{});
    }
    return _firestore
        .collection(FirestorePaths.hiddenMarketOffers(normalizedUid))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> hideOfferForUser({
    required String uid,
    required String offerId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedOfferId = offerId.trim();
    if (normalizedUid.isEmpty || normalizedOfferId.isEmpty) {
      throw StateError('invalid_hide_offer_payload');
    }
    await _firestore
        .doc(FirestorePaths.hiddenMarketOffer(normalizedUid, normalizedOfferId))
        .set(<String, dynamic>{
          'offerId': normalizedOfferId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<List<MarketUserNotification>> watchUserNotifications(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const Stream<List<MarketUserNotification>>.empty();
    }
    return _firestore
        .collection(FirestorePaths.userNotifications(normalizedUid))
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map(
                (doc) => MarketUserNotification.fromMap(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(growable: false);
          notifications.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return notifications;
        });
  }

  Future<void> markUserNotificationRead({
    required String uid,
    required String notificationId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedId = notificationId.trim();
    if (normalizedUid.isEmpty || normalizedId.isEmpty) {
      return;
    }
    await _firestore
        .doc('${FirestorePaths.userNotifications(normalizedUid)}/$normalizedId')
        .set(<String, dynamic>{
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _syncAirportRequestForAcceptedTrade({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  }) async {
    final participants = _resolveTradeHostAndVisitorUids(
      ownerUid: ownerUid,
      proposerUid: proposerUid,
      moveType: moveType,
    );
    final hostProfile = await _loadPrimaryIslandProfile(participants.hostUid);
    final visitorProfile = await _loadPrimaryIslandProfile(
      participants.visitorUid,
    );
    if (hostProfile == null || visitorProfile == null) {
      return;
    }

    final queueRef = _firestore.doc(
      FirestorePaths.airportQueue(hostProfile.islandId),
    );
    final requestRef = _firestore.doc(
      FirestorePaths.airportRequest(
        hostProfile.islandId,
        _tradeAirportRequestId(offerId),
      ),
    );
    final existingSnapshot = await requestRef.get();
    final existingData = existingSnapshot.data();
    final purpose = _resolveAirportPurposeFromTradeTitle(offerTitle);
    final message = offerTitle.trim().isEmpty ? '거래 약속 요청이에요.' : offerTitle;

    final batch = _firestore.batch();
    batch.set(queueRef, <String, dynamic>{
      'ownerUid': participants.hostUid,
      'islandName': hostProfile.islandName,
      'hostName': hostProfile.representativeName,
      'hostAvatarUrl': hostProfile.imageUrl,
      'islandImageUrl': hostProfile.imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(requestRef, <String, dynamic>{
      'islandId': hostProfile.islandId,
      'hostUid': participants.hostUid,
      'hostName': hostProfile.representativeName,
      'hostIslandName': hostProfile.islandName,
      'hostIslandImageUrl': hostProfile.imageUrl,
      'requesterUid': participants.visitorUid,
      'requesterName': visitorProfile.representativeName,
      'requesterAvatarUrl': visitorProfile.imageUrl,
      'requesterIslandName': visitorProfile.islandName,
      'requesterIslandImageUrl': visitorProfile.imageUrl,
      'purpose': purpose.name,
      'message': message,
      'status': AirportVisitRequestStatus.pending.name,
      'requestedAt': existingData != null && existingData['requestedAt'] != null
          ? existingData['requestedAt']
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'invitedAt': FieldValue.delete(),
      'arrivedAt': FieldValue.delete(),
      'inviteCode': FieldValue.delete(),
      'sourceType': _tradeAirportSourceType,
      'sourceOfferId': offerId,
      'sourceMoveType': moveType.name,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _syncAirportInviteForTradeCode({
    required String offerId,
    required String senderUid,
    required String inviteCode,
    required String offerTitle,
  }) async {
    final normalizedOfferId = offerId.trim();
    final normalizedSenderUid = senderUid.trim();
    final normalizedInviteCode = inviteCode.trim().toUpperCase();
    if (normalizedOfferId.isEmpty ||
        normalizedSenderUid.isEmpty ||
        !_dodoCodePattern.hasMatch(normalizedInviteCode)) {
      return;
    }

    final codeSnapshot = await _firestore
        .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
        .get();
    final codeData = codeSnapshot.data() ?? const <String, dynamic>{};
    final ownerUid = (codeData['ownerUid'] as String?)?.trim() ?? '';
    final proposerUid = (codeData['proposerUid'] as String?)?.trim() ?? '';
    final moveTypeName = (codeData['moveType'] as String?)?.trim() ?? '';
    var moveType = MarketMoveType.visitor;
    for (final item in MarketMoveType.values) {
      if (item.name == moveTypeName) {
        moveType = item;
        break;
      }
    }

    String resolvedHostUid = '';
    String resolvedVisitorUid = '';
    if (ownerUid.isNotEmpty && proposerUid.isNotEmpty) {
      final participants = _resolveTradeHostAndVisitorUids(
        ownerUid: ownerUid,
        proposerUid: proposerUid,
        moveType: moveType,
      );
      resolvedHostUid = participants.hostUid;
      resolvedVisitorUid = participants.visitorUid;
    }

    final hostProfile = await _loadPrimaryIslandProfile(normalizedSenderUid);
    final visitorProfile = resolvedVisitorUid.isEmpty
        ? null
        : await _loadPrimaryIslandProfile(resolvedVisitorUid);

    DocumentReference<Map<String, dynamic>>? requestRef;
    try {
      requestRef = await _findAirportTradeRequestRef(normalizedOfferId);
    } catch (_) {
      requestRef = null;
    }

    if (requestRef == null && hostProfile != null) {
      requestRef = _firestore.doc(
        FirestorePaths.airportRequest(
          hostProfile.islandId,
          _tradeAirportRequestId(normalizedOfferId),
        ),
      );
    }
    if (requestRef == null) {
      return;
    }

    final requestSnapshot = await requestRef.get();
    final requestData = requestSnapshot.data() ?? const <String, dynamic>{};
    final segments = requestRef.path.split('/');
    final islandId = segments.length >= 2 && segments[0] == 'airportQueues'
        ? segments[1]
        : (hostProfile?.islandId ?? '');
    if (islandId.isEmpty) {
      return;
    }
    final queueRef = _firestore.doc(FirestorePaths.airportQueue(islandId));

    final requestPayload = <String, dynamic>{
      'islandId': islandId,
      'hostUid': _pickFirstNonEmpty(<Object?>[
        normalizedSenderUid,
        requestData['hostUid'],
        resolvedHostUid,
      ]),
      'hostName': _pickFirstNonEmpty(<Object?>[
        requestData['hostName'],
        hostProfile?.representativeName,
        '호스트',
      ]),
      'hostIslandName': _pickFirstNonEmpty(<Object?>[
        requestData['hostIslandName'],
        hostProfile?.islandName,
        '이름 없는 섬',
      ]),
      'hostIslandImageUrl': _pickFirstNonEmpty(<Object?>[
        requestData['hostIslandImageUrl'],
        hostProfile?.imageUrl,
      ]),
      'requesterUid': _pickFirstNonEmpty(<Object?>[
        requestData['requesterUid'],
        resolvedVisitorUid,
      ]),
      'requesterName': _pickFirstNonEmpty(<Object?>[
        requestData['requesterName'],
        visitorProfile?.representativeName,
        '방문객',
      ]),
      'requesterAvatarUrl': _pickFirstNonEmpty(<Object?>[
        requestData['requesterAvatarUrl'],
        visitorProfile?.imageUrl,
      ]),
      'requesterIslandName': _pickFirstNonEmpty(<Object?>[
        requestData['requesterIslandName'],
        visitorProfile?.islandName,
        '이름 없는 섬',
      ]),
      'requesterIslandImageUrl': _pickFirstNonEmpty(<Object?>[
        requestData['requesterIslandImageUrl'],
        visitorProfile?.imageUrl,
      ]),
      'purpose': _pickFirstNonEmpty(<Object?>[
        requestData['purpose'],
        _resolveAirportPurposeFromTradeTitle(offerTitle).name,
      ]),
      'message': _pickFirstNonEmpty(<Object?>[
        requestData['message'],
        offerTitle.trim(),
        '거래 약속 요청이에요.',
      ]),
      'status': AirportVisitRequestStatus.invited.name,
      'inviteCode': normalizedInviteCode,
      'invitedAt': FieldValue.serverTimestamp(),
      'arrivedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'requestedAt': requestData['requestedAt'] ?? FieldValue.serverTimestamp(),
      'sourceType': _tradeAirportSourceType,
      'sourceOfferId': normalizedOfferId,
      'sourceMoveType': moveType.name,
    };
    await requestRef.set(requestPayload, SetOptions(merge: true));

    try {
      await queueRef.set(<String, dynamic>{
        'ownerUid': normalizedSenderUid,
        'islandName': _pickFirstNonEmpty(<Object?>[
          hostProfile?.islandName,
          requestData['hostIslandName'],
        ]),
        'hostName': _pickFirstNonEmpty(<Object?>[
          hostProfile?.representativeName,
          requestData['hostName'],
        ]),
        'hostAvatarUrl': _pickFirstNonEmpty(<Object?>[
          hostProfile?.imageUrl,
          requestData['hostIslandImageUrl'],
        ]),
        'islandImageUrl': _pickFirstNonEmpty(<Object?>[
          hostProfile?.imageUrl,
          requestData['hostIslandImageUrl'],
        ]),
        'dodoCode': normalizedInviteCode,
        'dodoCodeUpdatedAt': FieldValue.serverTimestamp(),
        'gateOpen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _syncAirportRequestStatusByOffer({
    required String offerId,
    required AirportVisitRequestStatus status,
  }) async {
    final requestRefs = await _findAirportTradeRequestRefs(offerId);
    if (requestRefs.isEmpty) {
      return;
    }
    final payload = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == AirportVisitRequestStatus.cancelled ||
        status == AirportVisitRequestStatus.completed) {
      payload['inviteCode'] = FieldValue.delete();
    }
    if (status == AirportVisitRequestStatus.cancelled) {
      payload['invitedAt'] = FieldValue.delete();
      payload['arrivedAt'] = FieldValue.delete();
    } else if (status == AirportVisitRequestStatus.completed) {
      payload['arrivedAt'] = FieldValue.serverTimestamp();
    }

    final batch = _firestore.batch();
    for (final ref in requestRefs) {
      batch.set(ref, payload, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findAirportTradeRequestRef(
    String offerId,
  ) async {
    final refs = await _findAirportTradeRequestRefs(offerId);
    if (refs.isEmpty) {
      return null;
    }
    return refs.first;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>>
  _findAirportTradeRequestRefs(String offerId) async {
    final normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      return const <DocumentReference<Map<String, dynamic>>>[];
    }
    final snapshot = await _firestore
        .collectionGroup('requests')
        .where('sourceOfferId', isEqualTo: normalizedOfferId)
        .limit(50)
        .get();
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final doc in snapshot.docs) {
      final sourceType = (doc.data()['sourceType'] as String?)?.trim() ?? '';
      if (sourceType != _tradeAirportSourceType) {
        continue;
      }
      refs.add(doc.reference);
    }
    return refs;
  }

  ({String hostUid, String visitorUid}) _resolveTradeHostAndVisitorUids({
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
  }) {
    if (moveType == MarketMoveType.host) {
      return (hostUid: ownerUid, visitorUid: proposerUid);
    }
    return (hostUid: proposerUid, visitorUid: ownerUid);
  }

  Future<
    ({
      String islandId,
      String islandName,
      String representativeName,
      String imageUrl,
    })?
  >
  _loadPrimaryIslandProfile(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return null;
    }

    final userSnapshot = await _firestore
        .doc(FirestorePaths.user(normalizedUid))
        .get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    var resolvedIslandId = _pickFirstNonEmpty(<Object?>[
      userData['primaryIslandId'],
    ]);
    if (resolvedIslandId.isEmpty) {
      // 유지보수 포인트:
      // primaryIslandId가 비어있는 계정에서도 거래-비행장 연동이 동작하도록
      // 사용자의 첫 섬 문서를 폴백으로 사용합니다.
      try {
        final islandsSnapshot = await _firestore
            .collection(FirestorePaths.islands(normalizedUid))
            .limit(1)
            .get();
        if (islandsSnapshot.docs.isNotEmpty) {
          resolvedIslandId = islandsSnapshot.docs.first.id;
        }
      } catch (_) {}
    }
    if (resolvedIslandId.isEmpty) {
      return null;
    }

    final islandSnapshot = await _firestore
        .doc(FirestorePaths.island(normalizedUid, resolvedIslandId))
        .get();
    final islandData = islandSnapshot.data() ?? const <String, dynamic>{};

    final islandName = _pickFirstNonEmpty(<Object?>[
      islandData['islandName'],
      userData['islandName'],
      '이름 없는 섬',
    ]);
    final representativeName = _pickFirstNonEmpty(<Object?>[
      islandData['representativeName'],
      userData['displayName'],
      userData['nickname'],
      '호스트',
    ]);
    final imageUrl = _pickFirstNonEmpty(<Object?>[
      islandData['imageUrl'],
      userData['photoUrl'],
      userData['avatarUrl'],
    ]);

    return (
      islandId: resolvedIslandId,
      islandName: islandName,
      representativeName: representativeName,
      imageUrl: imageUrl,
    );
  }

  String _tradeAirportRequestId(String offerId) {
    return '$_tradeAirportRequestIdPrefix${offerId.trim()}';
  }

  AirportVisitPurpose _resolveAirportPurposeFromTradeTitle(String offerTitle) {
    final normalized = offerTitle.replaceAll(' ', '');
    if (normalized.contains('무주식')) {
      return AirportVisitPurpose.turnip;
    }
    return AirportVisitPurpose.touching;
  }

  bool _isLocalPath(String value) {
    if (value.isEmpty) {
      return false;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    return value.startsWith('/') || value.startsWith('file://');
  }

  void _migrateLegacyCreatedAtIfNeeded(
    String docId,
    Map<String, dynamic> data,
  ) {
    final Object? legacy = data['createdAtMillis'];
    if (legacy == null) {
      return;
    }
    final int? millis = _toInt(legacy);
    if (millis == null || millis <= 0) {
      return;
    }

    // 유지보수 포인트:
    // 과거 문서에 남은 createdAtMillis를 읽는 즉시 createdAt(Timestamp)로
    // 승격하고, 레거시 필드를 삭제해 스키마를 단일화합니다.
    unawaited(
      _firestore.doc(FirestorePaths.marketPost(docId)).set(<String, dynamic>{
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(millis),
        'createdAtMillis': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedAtMillis': FieldValue.delete(),
        'actionLabel': FieldValue.delete(),
      }, SetOptions(merge: true)),
    );
  }

  int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  int _proposalStatusRank(MarketTradeProposalStatus status) {
    switch (status) {
      case MarketTradeProposalStatus.pending:
        return 0;
      case MarketTradeProposalStatus.accepted:
        return 1;
      case MarketTradeProposalStatus.rejected:
        return 2;
      case MarketTradeProposalStatus.cancelled:
        return 3;
    }
  }

  int _sortOffersForDisplay(MarketOffer a, MarketOffer b) {
    final rankA = _offerDisplayRank(a);
    final rankB = _offerDisplayRank(b);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  int _offerDisplayRank(MarketOffer offer) {
    if (offer.lifecycle == MarketLifecycleTab.completed ||
        offer.status == MarketOfferStatus.closed) {
      return 1;
    }
    return 0;
  }

  String _pickFirstNonEmpty(List<Object?> candidates) {
    for (final candidate in candidates) {
      final normalized = candidate?.toString().trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  Future<(String, String)> _resolveProposerIdentity({
    required String proposerUid,
    required Map<String, dynamic> proposerUserData,
  }) async {
    final normalizedUid = proposerUid.trim();
    if (normalizedUid.isEmpty) {
      return ('', '');
    }

    final primaryIslandId = _pickFirstNonEmpty(<Object?>[
      proposerUserData['primaryIslandId'],
    ]);

    Map<String, dynamic> islandData = const <String, dynamic>{};
    if (primaryIslandId.isNotEmpty) {
      final islandSnapshot = await _firestore
          .doc(FirestorePaths.island(normalizedUid, primaryIslandId))
          .get();
      islandData = islandSnapshot.data() ?? const <String, dynamic>{};
    }

    final proposerName = _pickFirstNonEmpty(<Object?>[
      islandData['representativeName'],
      proposerUserData['nickname'],
      proposerUserData['displayName'],
      proposerUserData['name'],
      proposerUserData['userName'],
    ]);
    final proposerAvatarUrl = _pickFirstNonEmpty(<Object?>[
      islandData['imageUrl'],
      proposerUserData['avatarUrl'],
      proposerUserData['photoUrl'],
      proposerUserData['profileImageUrl'],
      proposerUserData['imageUrl'],
    ]);

    return (proposerName, proposerAvatarUrl);
  }

  Future<void> _sendUserNotification({
    required String targetUid,
    required String senderUid,
    required String type,
    required String offerId,
    required String title,
    required String body,
    Map<String, dynamic>? extra,
  }) async {
    final notificationRef = _firestore
        .collection(FirestorePaths.userNotifications(targetUid))
        .doc();

    await notificationRef.set(<String, dynamic>{
      'id': notificationRef.id,
      'type': type,
      'offerId': offerId,
      'senderUid': senderUid,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extra,
    });

    // 유지보수 포인트:
    // 푸시 발송 함수가 없는 개발 환경에서도 기능 테스트가 가능하도록
    // Firestore 알림 저장 성공을 우선시하고 Callable 실패는 무시합니다.
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendTradeProposalPush',
      );
      await callable.call(<String, dynamic>{
        'targetUid': targetUid,
        'senderUid': senderUid,
        'offerId': offerId,
        'type': type,
        'title': title,
        'body': body,
      });
    } on FirebaseFunctionsException catch (_) {
      // no-op
    } catch (_) {
      // no-op
    }
  }

  Future<void> _deleteCollectionInBatches(String collectionPath) async {
    const pageSize = 450;
    while (true) {
      final snapshot = await _firestore
          .collection(collectionPath)
          .limit(pageSize)
          .get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < pageSize) {
        return;
      }
    }
  }
}
