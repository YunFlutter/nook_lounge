import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/turnip_prediction.dart';

part 'turnip_view_state.freezed.dart';

@freezed
sealed class TurnipViewState with _$TurnipViewState {
  const TurnipViewState._();

  const factory TurnipViewState({
    @Default(102) int sundayBuyPrice,
    @Default(<int?>[
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
      null,
      null,
    ])
    List<int?> weekSlots,
    @Default(-1) int activeDayIndex,
    @Default(false) bool isLoading,
    String? errorMessage,
    TurnipPrediction? prediction,
  }) = _TurnipViewState;

  List<int> buildFilter() {
    final values = <int>[sundayBuyPrice];
    for (final slot in weekSlots) {
      if (slot == null) {
        break;
      }
      values.add(slot);
    }
    return values;
  }

  bool get canCalculate => buildFilter().length >= 3;

  int get todayCardIndex {
    final weekday = DateTime.now().weekday;
    if (weekday < 1) {
      return 0;
    }
    if (weekday > 6) {
      return 5;
    }
    return weekday - 1;
  }
}
