import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_markdown_body.dart';

void main() {
  group('SettingsMarkdownBody', () {
    testWidgets('마크다운 문법을 렌더링한다', (tester) async {
      const markdown = '# 제목\n\n본문 **강조**\n- 항목 A\n- 항목 B';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsMarkdownBody(data: markdown)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('# 제목'), findsNothing);
      expect(find.textContaining('제목'), findsWidgets);
      expect(find.textContaining('본문 강조'), findsWidgets);
      expect(find.textContaining('항목 A'), findsWidgets);
      expect(find.textContaining('항목 B'), findsWidgets);
    });

    testWidgets('빈 본문이면 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SettingsMarkdownBody(data: '   ')),
        ),
      );

      expect(find.text('등록된 내용이 없어요.'), findsOneWidget);
    });
  });
}
