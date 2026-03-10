import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/blocked_user_summary.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_blocked_users_page.dart';

void main() {
  group('SettingsBlockedUsersPage', () {
    late _FakeUserBlockRepository repository;

    tearDown(() async {
      await repository.dispose();
    });

    testWidgets('차단 목록을 보여주고 해제 요청을 보낸다', (tester) async {
      repository = _FakeUserBlockRepository(
        initialUsers: <BlockedUserSummary>[
          BlockedUserSummary(
            uid: 'blocked-user',
            displayName: '루나',
            islandName: '별빛섬',
            avatarUrl: '',
            blockedAt: DateTime(2026, 3, 10),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            userBlockRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: SettingsBlockedUsersPage(uid: 'me')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('루나'), findsOneWidget);
      expect(find.text('별빛섬'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '해제'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('루나 차단을 해제할까요?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '해제'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(repository.unblockCalls.length, 1);
      expect(repository.unblockCalls.single.uid, 'me');
      expect(repository.unblockCalls.single.blockedUid, 'blocked-user');
      expect(find.text('차단을 해제했어요.'), findsOneWidget);
    });

    testWidgets('차단한 유저가 없으면 빈 상태를 보여준다', (tester) async {
      repository = _FakeUserBlockRepository(
        initialUsers: const <BlockedUserSummary>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            userBlockRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: SettingsBlockedUsersPage(uid: 'me')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('차단한 유저가 없어요.'), findsOneWidget);
    });
  });
}

class _FakeUserBlockRepository implements UserBlockRepository {
  _FakeUserBlockRepository({required List<BlockedUserSummary> initialUsers}) {
    _currentUsers = initialUsers;
  }

  late List<BlockedUserSummary> _currentUsers;
  final StreamController<List<BlockedUserSummary>> _controller =
      StreamController<List<BlockedUserSummary>>.broadcast();
  final List<({String uid, String blockedUid})> unblockCalls =
      <({String uid, String blockedUid})>[];

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<List<BlockedUserSummary>> watchBlockedUsers(String uid) {
    return Stream<List<BlockedUserSummary>>.multi((controller) {
      controller.add(_currentUsers);
      final subscription = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) async {
    unblockCalls.add((uid: uid, blockedUid: blockedUid));
    _currentUsers = const <BlockedUserSummary>[];
    _controller.add(_currentUsers);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
