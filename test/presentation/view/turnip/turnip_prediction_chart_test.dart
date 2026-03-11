import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_chart.dart';

void main() {
  testWidgets('좁은 폭에서도 TurnipPredictionChart 가 예외 없이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: TurnipPredictionChart(
              minValues: <int>[80, 70, 60, 50, 40, 30],
              maxValues: <int>[120, 130, 140, 150, 160, 170],
              peakDayIndex: 4,
              peakLabel: '금요일 오전',
              peakValue: 170,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(TurnipPredictionChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
