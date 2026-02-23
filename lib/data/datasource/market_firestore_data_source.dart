import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

class MarketFirestoreDataSource {
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
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return offers;
    });
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
    await _firestore.doc(FirestorePaths.marketPost(offerId)).delete();
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
}
