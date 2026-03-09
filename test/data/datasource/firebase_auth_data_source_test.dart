import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/domain/model/user_service_block.dart';

void main() {
  group('FirebaseAuthDataSource.parseActiveServiceBlock', () {
    final now = DateTime(2026, 3, 9, 12);

    test('blockedUntilDateTime 이 없으면 차단으로 보지 않는다', () {
      final block = FirebaseAuthDataSource.parseActiveServiceBlock(
        <String, dynamic>{'reason': '사유만 있음'},
        now: now,
      );

      expect(block, isNull);
    });

    test('미래 시각이면 활성 차단 정보를 반환한다', () {
      final blockedUntilDateTime = DateTime(2026, 3, 10, 9, 30);
      final blockedAtDateTime = DateTime(2026, 3, 8, 22);

      final block =
          FirebaseAuthDataSource.parseActiveServiceBlock(<String, dynamic>{
            'blockedUntilDateTime': blockedUntilDateTime,
            'blockedAtDateTime': blockedAtDateTime,
            'reason': '  반복적인 운영 정책 위반  ',
          }, now: now);

      expect(block, isA<UserServiceBlock>());
      expect(block?.blockedUntilDateTime, blockedUntilDateTime);
      expect(block?.blockedAtDateTime, blockedAtDateTime);
      expect(block?.normalizedReason, '반복적인 운영 정책 위반');
    });

    test('차단 종료 시각이 지났으면 null 을 반환한다', () {
      final block = FirebaseAuthDataSource.parseActiveServiceBlock(
        <String, dynamic>{
          'blockedUntilDateTime': DateTime(2026, 3, 8, 11, 59, 59),
          'reason': '만료된 차단',
        },
        now: now,
      );

      expect(block, isNull);
    });
  });
}
