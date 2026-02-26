import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';

class MarketFirestoreDataSource {
  static final RegExp _dodoCodePattern = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{6}$',
  );

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

    final codeRef = _firestore.doc(
      FirestorePaths.marketTradeCode(normalizedOfferId),
    );
    final codeSnapshot = await codeRef.get();
    final codeData = codeSnapshot.data() ?? const <String, dynamic>{};

    var counterpartUid = (codeData['proposerUid'] as String?)?.trim() ?? '';
    if (counterpartUid.isEmpty) {
      final acceptedProposalSnapshot = await _firestore
          .collection(FirestorePaths.marketTradeProposals(normalizedOfferId))
          .where('status', isEqualTo: MarketTradeProposalStatus.accepted.name)
          .limit(1)
          .get();
      if (acceptedProposalSnapshot.docs.isNotEmpty) {
        counterpartUid = acceptedProposalSnapshot.docs.first.id.trim();
      }
    }

    final canComplete =
        normalizedRequesterUid == ownerUid ||
        (counterpartUid.isNotEmpty && normalizedRequesterUid == counterpartUid);
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
    if (normalizedOfferId.isEmpty ||
        normalizedSenderUid.isEmpty ||
        normalizedReceiverUid.isEmpty ||
        normalizedCode.isEmpty) {
      throw StateError('invalid_trade_code_payload');
    }

    if (!_dodoCodePattern.hasMatch(normalizedCode)) {
      throw StateError('invalid_trade_code_format');
    }

    await _firestore
        .doc(FirestorePaths.marketTradeCode(normalizedOfferId))
        .set(<String, dynamic>{
          'code': normalizedCode,
          'codeSenderUid': normalizedSenderUid,
          'codeReceiverUid': normalizedReceiverUid,
          'codeSentAt': FieldValue.serverTimestamp(),
          'codeSentAtMillis': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMillis': FieldValue.delete(),
        }, SetOptions(merge: true));

    final normalizedTitle = offerTitle.trim().isEmpty
        ? '거래글'
        : offerTitle.trim();
    await _sendUserNotification(
      targetUid: normalizedReceiverUid,
      senderUid: normalizedSenderUid,
      type: 'market_trade_code',
      offerId: normalizedOfferId,
      title: '거래 코드가 도착했어요',
      body: '$normalizedTitle 코드: $normalizedCode',
      extra: <String, dynamic>{'tradeCode': normalizedCode},
    );
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
