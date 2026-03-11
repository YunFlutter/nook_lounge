import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/data/datasource/app_version_firestore_data_source.dart';

void main() {
  group('AppVersionFirestoreDataSource.parseConfig', () {
    test('version 맵 안의 android 와 ios 버전을 읽는다', () {
      final config = AppVersionFirestoreDataSource.parseConfig(
        documentId: 'current',
        data: <String, dynamic>{
          'version': <String, dynamic>{'android': '1.2.3', 'ios': '1.2.4'},
        },
      );

      expect(config?.documentId, 'current');
      expect(config?.androidVersion, '1.2.3');
      expect(config?.iosVersion, '1.2.4');
    });

    test('andriod 오타 필드도 안드로이드 버전으로 허용한다', () {
      final config = AppVersionFirestoreDataSource.parseConfig(
        documentId: 'current',
        data: <String, dynamic>{
          'version': <String, dynamic>{'andriod': '2.0.0'},
        },
      );

      expect(config?.androidVersion, '2.0.0');
    });

    test('version 맵이 없으면 문서 최상위 필드에서도 읽는다', () {
      final config = AppVersionFirestoreDataSource.parseConfig(
        documentId: 'current',
        data: <String, dynamic>{'android': 3, 'ios': '3.1.0'},
      );

      expect(config?.androidVersion, '3');
      expect(config?.iosVersion, '3.1.0');
    });

    test('읽을 수 있는 버전이 없으면 null 을 반환한다', () {
      final config = AppVersionFirestoreDataSource.parseConfig(
        documentId: 'current',
        data: <String, dynamic>{
          'version': <String, dynamic>{'web': '1.0.0'},
        },
      );

      expect(config, isNull);
    });
  });
}
