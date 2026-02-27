import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/core/constants/firestore_paths.dart';
import 'package:nook_lounge_app/core/constants/settings_seed_data.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
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

  Stream<List<SettingsNotice>> watchNotices() async* {
    try {
      await for (final snapshot
          in _firestore
              .collection(FirestorePaths.appNotices())
              .orderBy('publishedAt', descending: true)
              .snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield SettingsSeedData.defaultNotices;
          continue;
        }

        final notices = <SettingsNotice>[];
        for (final doc in snapshot.docs) {
          notices.add(SettingsNotice.fromMap(id: doc.id, data: doc.data()));
        }
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

    final doc = await _firestore
        .doc(FirestorePaths.appNotice(normalizedId))
        .get();
    final data = doc.data();
    if (data != null) {
      return SettingsNotice.fromMap(id: doc.id, data: data);
    }

    for (final notice in SettingsSeedData.defaultNotices) {
      if (notice.id == normalizedId) {
        return notice;
      }
    }

    return null;
  }

  Stream<SettingsDocument> watchDocument(SettingsDocumentType type) async* {
    try {
      await for (final snapshot
          in _firestore
              .doc(FirestorePaths.appDocument(type.documentId))
              .snapshots()) {
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
              .collection(FirestorePaths.userSupportInquiries(normalizedUid))
              .orderBy('createdAt', descending: true)
              .snapshots()) {
        final inquiries = <SupportInquiry>[];
        for (final doc in snapshot.docs) {
          inquiries.add(SupportInquiry.fromMap(id: doc.id, data: doc.data()));
        }
        yield inquiries;
      }
    } catch (_) {
      yield const <SupportInquiry>[];
    }
  }

  Future<void> createInquiry({
    required String uid,
    required String category,
    required String title,
    required String body,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw StateError('invalid_uid');
    }

    final ref = _firestore
        .collection(FirestorePaths.userSupportInquiries(normalizedUid))
        .doc();

    await ref.set(<String, dynamic>{
      'uid': normalizedUid,
      'category': category.trim(),
      'title': title.trim(),
      'body': body.trim(),
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

    await _firestore
        .doc(
          FirestorePaths.userSupportInquiry(normalizedUid, normalizedInquiryId),
        )
        .delete();
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
        .doc(
          FirestorePaths.userSupportInquiry(normalizedUid, normalizedInquiryId),
        )
        .get();
    final data = doc.data();
    if (data == null) {
      return null;
    }

    return SupportInquiry.fromMap(id: doc.id, data: data);
  }
}
