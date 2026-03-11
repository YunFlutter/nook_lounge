import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/app_update_status.dart';
import 'package:nook_lounge_app/presentation/view/app_update_guard.dart';

void main() {
  group('AppUpdateGuard', () {
    testWidgets('업데이트가 필요하면 차단 레이어를 띄운다', (tester) async {
      var tappedCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appUpdateStatusProvider.overrideWith(
              (ref) => Stream<AppUpdateStatus>.value(
                const AppUpdateStatus(
                  currentVersion: '1.0.0',
                  remoteVersion: '1.1.0',
                  requiresUpdate: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateGuard(
                child: Center(
                  child: FilledButton(
                    onPressed: () {
                      tappedCount += 1;
                    },
                    child: const Text('원래 버튼'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('업데이트가 필요해요'), findsOneWidget);
      expect(find.textContaining('1.1.0'), findsOneWidget);

      await tester.tap(find.text('원래 버튼'), warnIfMissed: false);
      await tester.pump();

      expect(tappedCount, 0);
    });
  });
}
