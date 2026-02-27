import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

abstract class SettingsRepository {
  Stream<SettingsNotificationPreferences> watchNotificationPreferences({
    required String uid,
  });

  Future<void> updateNotificationPreference({
    required String uid,
    required SettingsNotificationType type,
    required bool enabled,
  });

  Stream<List<SettingsNotice>> watchNotices();

  Future<SettingsNotice?> fetchNotice(String noticeId);

  Stream<SettingsDocument> watchDocument(SettingsDocumentType type);

  Stream<List<SupportInquiry>> watchInquiries({required String uid});

  Future<void> createInquiry({
    required String uid,
    required String category,
    required String title,
    required String body,
  });

  Future<void> deleteInquiry({required String uid, required String inquiryId});

  Future<SupportInquiry?> fetchInquiry({
    required String uid,
    required String inquiryId,
  });
}
