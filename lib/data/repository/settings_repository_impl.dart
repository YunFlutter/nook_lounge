import 'package:nook_lounge_app/data/datasource/settings_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';
import 'package:nook_lounge_app/domain/repository/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SettingsFirestoreDataSource dataSource})
    : _dataSource = dataSource;

  final SettingsFirestoreDataSource _dataSource;

  @override
  Stream<SettingsNotificationPreferences> watchNotificationPreferences({
    required String uid,
  }) {
    return _dataSource.watchNotificationPreferences(uid: uid);
  }

  @override
  Future<void> updateNotificationPreference({
    required String uid,
    required SettingsNotificationType type,
    required bool enabled,
  }) {
    return _dataSource.updateNotificationPreference(
      uid: uid,
      type: type,
      enabled: enabled,
    );
  }

  @override
  Stream<List<SettingsNotice>> watchNotices() {
    return _dataSource.watchNotices();
  }

  @override
  Future<SettingsNotice?> fetchNotice(String noticeId) {
    return _dataSource.fetchNotice(noticeId);
  }

  @override
  Stream<SettingsDocument> watchDocument(SettingsDocumentType type) {
    return _dataSource.watchDocument(type);
  }

  @override
  Stream<List<SupportInquiry>> watchInquiries({required String uid}) {
    return _dataSource.watchInquiries(uid: uid);
  }

  @override
  Future<void> createInquiry({
    required String uid,
    required String category,
    required String title,
    required String body,
  }) {
    return _dataSource.createInquiry(
      uid: uid,
      category: category,
      title: title,
      body: body,
    );
  }

  @override
  Future<void> deleteInquiry({required String uid, required String inquiryId}) {
    return _dataSource.deleteInquiry(uid: uid, inquiryId: inquiryId);
  }

  @override
  Future<SupportInquiry?> fetchInquiry({
    required String uid,
    required String inquiryId,
  }) {
    return _dataSource.fetchInquiry(uid: uid, inquiryId: inquiryId);
  }
}
