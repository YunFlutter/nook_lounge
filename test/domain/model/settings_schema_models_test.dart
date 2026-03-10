import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

void main() {
  group('SettingsDocument.fromMap', () {
    test('legal_docs content 필드를 body 로 읽는다', () {
      final document = SettingsDocument.fromMap(
        type: SettingsDocumentType.privacyPolicy,
        data: <String, dynamic>{
          'content': '개인정보 처리방침 전문',
          'updatedAt': DateTime(2026, 3, 10),
        },
      );

      expect(document.body, '개인정보 처리방침 전문');
    });
  });

  group('SettingsNotice.fromMap', () {
    test('createdAt 과 pinned 필드를 읽는다', () {
      final notice = SettingsNotice.fromMap(
        id: 'notice_1',
        data: <String, dynamic>{
          'title': '점검 안내',
          'body': '서비스 점검이 진행됩니다.',
          'createdAt': DateTime(2026, 3, 10, 9),
          'pinned': true,
        },
      );

      expect(notice.pinned, isTrue);
      expect(notice.publishedAt, DateTime(2026, 3, 10, 9));
    });
  });

  group('SupportInquiry.fromMap', () {
    test('answeredAt 과 type 을 읽는다', () {
      final inquiry = SupportInquiry.fromMap(
        id: 'inquiry_1',
        data: <String, dynamic>{
          'uid': 'user_1',
          'category': '계정/로그인',
          'title': '문의 제목',
          'body': '문의 내용',
          'type': 'appeal',
          'status': 'completed',
          'createdAt': DateTime(2026, 3, 9, 10),
          'adminReply': '답변 완료',
          'answeredAt': DateTime(2026, 3, 10, 12),
        },
      );

      expect(inquiry.answeredAt, DateTime(2026, 3, 10, 12));
      expect(inquiry.adminReply, '답변 완료');
      expect(inquiry.type, SupportInquiryType.appeal);
      expect(inquiry.isAppeal, isTrue);
    });
  });
}
