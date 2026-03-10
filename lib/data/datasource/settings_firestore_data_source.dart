import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_faq_item.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

class SettingsFirestoreDataSource {
  SettingsFirestoreDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<SettingsNotificationPreferences> watchNotificationPreferences({
    required String uid,
  }) async* {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      yield SettingsNotificationPreferences.defaults;
      return;
    }

    try {
      await for (final snapshot
          in _firestore
              .doc(FirestorePaths.userSetting(normalizedUid, 'notifications'))
              .snapshots()) {
        yield SettingsNotificationPreferences.fromMap(snapshot.data());
      }
    } catch (_) {
      yield SettingsNotificationPreferences.defaults;
    }
  }

  Future<void> updateNotificationPreference({
    required String uid,
    required SettingsNotificationType type,
    required bool enabled,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return;
    }

    final fieldName = SettingsNotificationPreferences.defaults.fieldNameOf(
      type,
    );
    await _firestore
        .doc(FirestorePaths.userSetting(normalizedUid, 'notifications'))
        .set(<String, dynamic>{
          fieldName: enabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<List<SettingsFaqItem>> watchFaqItems() async* {
    try {
      await for (final snapshot
          in _firestore.doc(FirestorePaths.appConfigFaqs()).snapshots()) {
        final items = parseFaqItems(snapshot.data());
        yield items.isEmpty ? SettingsSeedData.faqItems : items;
      }
    } catch (_) {
      yield SettingsSeedData.faqItems;
    }
  }

  Stream<List<SettingsNotice>> watchNotices() async* {
    final collectionPath = await _resolveNoticeCollectionPath();
    try {
      await for (final snapshot
          in _firestore.collection(collectionPath).snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield SettingsSeedData.defaultNotices;
          continue;
        }

        final notices = <SettingsNotice>[];
        for (final doc in snapshot.docs) {
          notices.add(SettingsNotice.fromMap(id: doc.id, data: doc.data()));
        }
        notices.sort(_sortNotices);
        yield notices;
      }
    } catch (_) {
      yield SettingsSeedData.defaultNotices;
    }
  }

  Future<SettingsNotice?> fetchNotice(String noticeId) async {
    final normalizedId = noticeId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final path in <String>[
      FirestorePaths.notice(normalizedId),
      FirestorePaths.appNotice(normalizedId),
    ]) {
      final doc = await _firestore.doc(path).get();
      final data = doc.data();
      if (data != null) {
        return SettingsNotice.fromMap(id: doc.id, data: data);
      }
    }

    for (final notice in SettingsSeedData.defaultNotices) {
      if (notice.id == normalizedId) {
        return notice;
      }
    }

    return null;
  }

  Stream<SettingsDocument> watchDocument(SettingsDocumentType type) async* {
    final documentPath = await _resolveDocumentPath(type);
    try {
      await for (final snapshot in _firestore.doc(documentPath).snapshots()) {
        final data = snapshot.data();
        if (data == null) {
          yield SettingsSeedData.defaultDocuments[type] ??
              SettingsDocument(
                type: type,
                title: type.defaultTitle,
                body: '',
                updatedAt: DateTime.now(),
              );
          continue;
        }
        yield SettingsDocument.fromMap(type: type, data: data);
      }
    } catch (_) {
      yield SettingsSeedData.defaultDocuments[type] ??
          SettingsDocument(
            type: type,
            title: type.defaultTitle,
            body: '',
            updatedAt: DateTime.now(),
          );
    }
  }

  Stream<List<SupportInquiry>> watchInquiries({required String uid}) async* {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      yield const <SupportInquiry>[];
      return;
    }

    try {
      await for (final snapshot
          in _firestore
              .collection(FirestorePaths.supportInquiries())
              .where('uid', isEqualTo: normalizedUid)
              .snapshots()) {
        final inquiries = <SupportInquiry>[];
        for (final doc in snapshot.docs) {
          inquiries.add(SupportInquiry.fromMap(id: doc.id, data: doc.data()));
        }
        inquiries.sort(sortInquiriesByCreatedAtDesc);
        yield inquiries;
      }
    } catch (error, stackTrace) {
      debugPrint('watchInquiries failed: $error\n$stackTrace');
      yield const <SupportInquiry>[];
    }
  }

  Future<void> createInquiry({
    required String uid,
    required String category,
    required String title,
    required String body,
    SupportInquiryType type = SupportInquiryType.general,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw StateError('invalid_uid');
    }

    final ref = _firestore.collection(FirestorePaths.supportInquiries()).doc();

    await ref.set(<String, dynamic>{
      'uid': normalizedUid,
      'category': category.trim(),
      'title': title.trim(),
      'body': body.trim(),
      'type': type.name,
      'status': SupportInquiryStatus.received.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteInquiry({
    required String uid,
    required String inquiryId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedInquiryId = inquiryId.trim();
    if (normalizedUid.isEmpty || normalizedInquiryId.isEmpty) {
      return;
    }

    final ref = _firestore.doc(
      FirestorePaths.supportInquiry(normalizedInquiryId),
    );
    final snapshot = await ref.get();
    final data = snapshot.data();
    if (data == null) {
      return;
    }

    // 유지보수 포인트:
    // 문의가 최상위 컬렉션으로 이동했기 때문에
    // uid 소유권이 일치할 때만 삭제를 진행합니다.
    final ownerUid = (data['uid'] as String?)?.trim() ?? '';
    if (ownerUid != normalizedUid) {
      return;
    }

    await ref.delete();
  }

  Future<SupportInquiry?> fetchInquiry({
    required String uid,
    required String inquiryId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedInquiryId = inquiryId.trim();
    if (normalizedUid.isEmpty || normalizedInquiryId.isEmpty) {
      return null;
    }

    final doc = await _firestore
        .doc(FirestorePaths.supportInquiry(normalizedInquiryId))
        .get();
    final data = doc.data();
    if (data == null) {
      return null;
    }
    final ownerUid = (data['uid'] as String?)?.trim() ?? '';
    if (ownerUid != normalizedUid) {
      return null;
    }

    return SupportInquiry.fromMap(id: doc.id, data: data);
  }

  Future<String> _resolveNoticeCollectionPath() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notices())
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return FirestorePaths.notices();
      }
    } catch (_) {}
    return FirestorePaths.appNotices();
  }

  Future<String> _resolveDocumentPath(SettingsDocumentType type) async {
    final primaryPath = FirestorePaths.legalDoc(type.documentId);
    try {
      final snapshot = await _firestore.doc(primaryPath).get();
      if (snapshot.exists) {
        return primaryPath;
      }
    } catch (_) {}
    return FirestorePaths.appDocument(type.legacyDocumentId);
  }

  int _sortNotices(SettingsNotice a, SettingsNotice b) {
    if (a.pinned != b.pinned) {
      return a.pinned ? -1 : 1;
    }
    return b.publishedAt.compareTo(a.publishedAt);
  }

  @visibleForTesting
  static List<SettingsFaqItem> parseFaqItems(Map<String, dynamic>? data) {
    final rawCategories = data?['categories'];
    if (rawCategories is! List) {
      return const <SettingsFaqItem>[];
    }

    final items = <SettingsFaqItem>[];
    for (
      var categoryIndex = 0;
      categoryIndex < rawCategories.length;
      categoryIndex++
    ) {
      final rawCategory = rawCategories[categoryIndex];
      if (rawCategory is! Map) {
        continue;
      }
      final categoryData = Map<String, dynamic>.from(rawCategory);
      final categoryId =
          (categoryData['id'] as String?)?.trim() ?? 'category_$categoryIndex';
      final categoryName = (categoryData['name'] as String?)?.trim() ?? '';
      final rawItems = categoryData['items'];
      if (categoryName.isEmpty || rawItems is! List) {
        continue;
      }

      for (var itemIndex = 0; itemIndex < rawItems.length; itemIndex++) {
        final rawItem = rawItems[itemIndex];
        if (rawItem is! Map) {
          continue;
        }
        final itemData = Map<String, dynamic>.from(rawItem);
        final question = (itemData['question'] as String?)?.trim() ?? '';
        final answer = (itemData['answer'] as String?)?.trim() ?? '';
        final status = (itemData['status'] as String?)?.trim() ?? 'active';
        if (question.isEmpty ||
            answer.isEmpty ||
            !_isVisibleFaqStatus(status)) {
          continue;
        }

        final itemId =
            (itemData['id'] as String?)?.trim() ??
            '${categoryId}_item_$itemIndex';
        items.add(
          SettingsFaqItem(
            id: itemId,
            category: categoryName,
            question: question,
            answer: answer,
            status: status,
          ),
        );
      }
    }
    return items;
  }

  @visibleForTesting
  static int sortInquiriesByCreatedAtDesc(SupportInquiry a, SupportInquiry b) {
    return b.createdAt.compareTo(a.createdAt);
  }

  static bool _isVisibleFaqStatus(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    switch (normalizedStatus) {
      case 'hidden':
      case 'inactive':
      case 'disabled':
      case 'draft':
      case 'deleted':
        return false;
    }
    return true;
  }
}
