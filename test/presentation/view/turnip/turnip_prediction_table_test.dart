import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_chart.dart';
import 'package:nook_lounge_app/presentation/view/turnip/turnip_prediction_table.dart';

void main() {
  testWidgets('차트 요일 라벨과 테이블 헤더 열 중심이 정렬된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TurnipPredictionChart(
                  minValues: <int>[90, 92, 143, 41, 31, 21],
                  maxValues: <int>[90, 204, 204, 92, 92, 92],
                  peakDayIndex: 1,
                  peakLabel: '화요일 오후',
                  peakValue: 612,
                ),
                SizedBox(height: 12),
                TurnipPredictionTable(
                  minValues: <int>[90, 92, 143, 41, 31, 21],
                  maxValues: <int>[90, 204, 204, 92, 92, 92],
                  avgValues: <int>[90, 149, 173, 66, 63, 59],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    _expectAligned(
      tester,
      label: '월',
      chart: find.byType(TurnipPredictionChart),
      table: find.byType(TurnipPredictionTable),
    );
    _expectAligned(
      tester,
      label: '수',
      chart: find.byType(TurnipPredictionChart),
      table: find.byType(TurnipPredictionTable),
    );
    _expectAligned(
      tester,
      label: '토',
      chart: find.byType(TurnipPredictionChart),
      table: find.byType(TurnipPredictionTable),
    );
  });
}

void _expectAligned(
  WidgetTester tester, {
  required String label,
  required Finder chart,
  required Finder table,
}) {
  final chartLabel = find.descendant(of: chart, matching: find.text(label));
  final tableLabel = find.descendant(of: table, matching: find.text(label));

  expect(chartLabel, findsOneWidget);
  expect(tableLabel, findsOneWidget);
  expect(
    (tester.getCenter(chartLabel).dx - tester.getCenter(tableLabel).dx).abs(),
    lessThanOrEqualTo(1),
  );
}
