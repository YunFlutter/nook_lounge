import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/data/datasource/settings_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';

void main() {
  group('SettingsFirestoreDataSource.parseFaqItems', () {
    test('categories 구조를 평탄화하고 title 기반 FAQ만 노출한다', () {
      final items = SettingsFirestoreDataSource.parseFaqItems(<String, dynamic>{
        'categories': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'account',
            'title': '계정/로그인',
            'status': 'active',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'faq_login',
                'question': '로그인이 안 돼요?',
                'answer': '다시 시도해 주세요.',
                'status': 'active',
              },
              <String, dynamic>{
                'id': 'faq_hidden',
                'question': '숨김 처리된 항목',
                'answer': '보이면 안 됩니다.',
                'status': 'hidden',
              },
            ],
          },
          <String, dynamic>{
            'id': 'hidden_category',
            'title': '숨김 카테고리',
            'status': 'hidden',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'faq_blocked',
                'question': '노출되면 안 되는 질문',
                'answer': '노출되면 안 되는 답변',
                'status': 'active',
              },
            ],
          },
          <String, dynamic>{
            'id': 'market',
            'name': '너굴마켓',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'question': '거래는 어떻게 하나요?',
                'answer': '게시글을 등록하면 됩니다.',
              },
            ],
          },
        ],
      });

      expect(items, hasLength(2));
      expect(items[0].id, 'faq_login');
      expect(items[0].category, '계정/로그인');
      expect(items[1].id, 'market_item_0');
      expect(items[1].category, '너굴마켓');
    });

    test('categories 가 없으면 빈 목록을 반환한다', () {
      final items = SettingsFirestoreDataSource.parseFaqItems(<String, dynamic>{
        'items': <Object>[],
      });

      expect(items, isEmpty);
    });
  });

  group('SettingsFirestoreDataSource.sortInquiriesByCreatedAtDesc', () {
    test('최신 문의가 먼저 오도록 정렬한다', () {
      final olderInquiry = SupportInquiry(
        id: 'older',
        uid: 'user_1',
        category: '정책 관련',
        title: '이전 문의',
        body: '내용',
        type: SupportInquiryType.appeal,
        status: SupportInquiryStatus.received,
        createdAt: DateTime(2026, 3, 10, 9),
      );
      final newerInquiry = SupportInquiry(
        id: 'newer',
        uid: 'user_1',
        category: '정책 관련',
        title: '최근 문의',
        body: '내용',
        type: SupportInquiryType.appeal,
        status: SupportInquiryStatus.processing,
        createdAt: DateTime(2026, 3, 10, 12),
      );

      final inquiries = <SupportInquiry>[olderInquiry, newerInquiry]
        ..sort(SettingsFirestoreDataSource.sortInquiriesByCreatedAtDesc);

      expect(inquiries.first.id, 'newer');
      expect(inquiries.last.id, 'older');
    });
  });
}
