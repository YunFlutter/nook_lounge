import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/turnip_prediction.dart';

part 'turnip_saved_data.freezed.dart';

@freezed
sealed class TurnipSavedData with _$TurnipSavedData {
  const TurnipSavedData._();

  const factory TurnipSavedData({
    required int sundayBuyPrice,
    required List<int?> weekSlots,
    TurnipPrediction? prediction,
  }) = _TurnipSavedData;

  factory TurnipSavedData.fromMap(Map<String, dynamic> data) {
    final sundayBuyPrice = _parseInt(data['sundayBuyPrice']) ?? 102;

    final slots = List<int?>.filled(12, null, growable: false);
    final rawSlots = data['weekSlots'];
    if (rawSlots is List) {
      for (var i = 0; i < rawSlots.length && i < slots.length; i++) {
        slots[i] = _parseInt(rawSlots[i]);
      }
    }

    TurnipPrediction? prediction;
    final rawPrediction = data['prediction'];
    if (rawPrediction is Map) {
      try {
        prediction = TurnipPrediction.fromApiJson(
          Map<String, dynamic>.from(rawPrediction),
        );
      } catch (_) {
        prediction = null;
      }
    }

    return TurnipSavedData(
      sundayBuyPrice: sundayBuyPrice,
      weekSlots: slots,
      prediction: prediction,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sundayBuyPrice': sundayBuyPrice,
      'weekSlots': weekSlots,
      if (prediction != null)
        'prediction': <String, dynamic>{
          'filter': prediction!.filter,
          'minMaxPattern': prediction!.minMaxPattern,
          'avgPattern': prediction!.avgPattern,
          'minWeekValue': prediction!.minWeekValue,
          'preview': prediction!.previewUrl,
        },
    };
  }
}

int? _parseInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
