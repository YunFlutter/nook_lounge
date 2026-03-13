import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/page_guide_content.dart';
import 'package:nook_lounge_app/domain/model/page_guide_step.dart';
import 'package:nook_lounge_app/presentation/view/common/app_page_guide_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const content = PageGuideContent(
    storageKey: 'overlay_test_page',
    badgeLabel: '테스트 안내',
    title: '테스트 페이지 가이드',
    description: '페이지 흐름을 설명하는 테스트용 가이드입니다.',
    primaryActionLabel: '확인',
    steps: <PageGuideStep>[
      PageGuideStep(title: '첫 단계', description: '가이드를 확인합니다.'),
    ],
  );

  group('AppPageGuideOverlay', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'page_guide_seen.overlay_test_page': true,
      });
    });

    testWidgets('이미 본 가이드는 처음 진입 시 자동 노출하지 않는다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppPageGuideOverlay(
                content: content,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('테스트 페이지 가이드'), findsNothing);
    });

    testWidgets('수동 트리거가 들어오면 다시 가이드를 노출한다', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AppPageGuideOverlay(
                content: content,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('테스트 페이지 가이드'), findsNothing);

      final notifier = container.read(
        pageGuidePresentationTickProvider(content.storageKey).notifier,
      );
      notifier.state = notifier.state + 1;
      await tester.pumpAndSettle();

      expect(find.text('테스트 페이지 가이드'), findsOneWidget);
      expect(find.text('첫 단계'), findsOneWidget);
    });
  });
}
