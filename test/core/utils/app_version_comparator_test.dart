import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/core/utils/app_version_comparator.dart';

void main() {
  group('AppVersionComparator.compare', () {
    const comparator = AppVersionComparator();

    test('세그먼트 숫자를 기준으로 버전을 비교한다', () {
      expect(comparator.compare('1.2.3', '1.2.4'), lessThan(0));
      expect(comparator.compare('1.2.10', '1.2.3'), greaterThan(0));
      expect(comparator.compare('2.0.0', '2.0.0'), 0);
    });

    test('빌드 번호와 비숫자 문자가 섞여 있어도 숫자만 추출해 비교한다', () {
      expect(comparator.compare('1.0.0+1', '1.0.0+2'), lessThan(0));
      expect(
        comparator.compare('1.0.0-beta.2', '1.0.0-beta.1'),
        greaterThan(0),
      );
    });
  });
}
