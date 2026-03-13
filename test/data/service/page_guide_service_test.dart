import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/data/service/page_guide_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageGuideService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('처음 진입한 가이드는 미노출 상태로 본다', () async {
      final service = PageGuideService();

      final hasSeen = await service.hasSeen('home_shell_home_tab_v1');

      expect(hasSeen, isFalse);
    });

    test('가이드 노출 저장 후 reset 하면 다시 미노출 상태가 된다', () async {
      final service = PageGuideService();

      await service.markSeen('home_shell_home_tab_v1');
      final hasSeenAfterMark = await service.hasSeen('home_shell_home_tab_v1');
      await service.reset('home_shell_home_tab_v1');
      final hasSeenAfterReset = await service.hasSeen('home_shell_home_tab_v1');

      expect(hasSeenAfterMark, isTrue);
      expect(hasSeenAfterReset, isFalse);
    });
  });
}
