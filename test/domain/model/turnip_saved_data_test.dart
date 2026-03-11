import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/turnip_prediction.dart';
import 'package:nook_lounge_app/domain/model/turnip_saved_data.dart';

void main() {
  group('TurnipSavedData', () {
    test('toMap 은 Firestore 저장용으로 minMaxPattern 을 맵 배열로 직렬화한다', () {
      const data = TurnipSavedData(
        sundayBuyPrice: 95,
        weekSlots: <int?>[
          90,
          88,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ],
        prediction: TurnipPrediction(
          filter: <int>[95, 90, 88],
          minMaxPattern: <List<int>>[
            <int>[80, 120],
            <int>[70, 110],
          ],
          avgPattern: <double>[100, 90],
          minWeekValue: 70,
          previewUrl: 'https://example.com',
        ),
      );

      final map = data.toMap();
      final prediction = map['prediction'] as Map<String, dynamic>;

      expect(prediction['minMaxPattern'], <Map<String, int>>[
        <String, int>{'min': 80, 'max': 120},
        <String, int>{'min': 70, 'max': 110},
      ]);
    });

    test('fromMap 은 Firestore-safe minMaxPattern 포맷을 다시 읽는다', () {
      final data = TurnipSavedData.fromMap(<String, dynamic>{
        'sundayBuyPrice': 91,
        'weekSlots': <int?>[
          80,
          79,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ],
        'prediction': <String, dynamic>{
          'filter': <int>[91, 80, 79],
          'minMaxPattern': <Map<String, int>>[
            <String, int>{'min': 60, 'max': 130},
            <String, int>{'min': 55, 'max': 120},
          ],
          'avgPattern': <double>[95, 87],
          'minWeekValue': 55,
          'preview': 'https://example.com/preview',
        },
      });

      expect(data.prediction, isNotNull);
      expect(data.prediction!.minMaxPattern, <List<int>>[
        <int>[60, 130],
        <int>[55, 120],
      ]);
    });
  });
}
