import 'package:freezed_annotation/freezed_annotation.dart';

part 'turnip_prediction.freezed.dart';

@freezed
sealed class TurnipPrediction with _$TurnipPrediction {
  const TurnipPrediction._();

  const factory TurnipPrediction({
    required List<int> filter,
    required List<List<int>> minMaxPattern,
    required List<double> avgPattern,
    required int minWeekValue,
    required String previewUrl,
  }) = _TurnipPrediction;

  factory TurnipPrediction.fromApiJson(Map<String, dynamic> json) {
    final filter = _parseIntList(json['filter']);
    final minMaxPattern = _parseMinMaxPattern(json['minMaxPattern']);
    final avgPattern = _parseDoubleList(json['avgPattern']);
    final minWeekValue = _parseInt(json['minWeekValue']);
    final previewUrl = (json['preview'] ?? '').toString().trim();

    return TurnipPrediction(
      filter: filter,
      minMaxPattern: minMaxPattern,
      avgPattern: avgPattern,
      minWeekValue: minWeekValue,
      previewUrl: previewUrl,
    );
  }

  int get peakMaxValue {
    var peak = 0;
    for (final point in minMaxPattern) {
      if (point.length < 2) {
        continue;
      }
      if (point[1] > peak) {
        peak = point[1];
      }
    }
    return peak;
  }

  int get peakIndex {
    var peak = 0;
    var index = 0;
    for (var i = 0; i < minMaxPattern.length; i++) {
      final point = minMaxPattern[i];
      if (point.length < 2) {
        continue;
      }
      if (point[1] > peak) {
        peak = point[1];
        index = i;
      }
    }
    return index;
  }

  static List<int> _parseIntList(Object? source) {
    if (source is! List) {
      return const <int>[];
    }
    final result = <int>[];
    for (final value in source) {
      result.add(_parseInt(value));
    }
    return result;
  }

  static List<double> _parseDoubleList(Object? source) {
    if (source is! List) {
      return const <double>[];
    }
    final result = <double>[];
    for (final value in source) {
      if (value is num) {
        result.add(value.toDouble());
        continue;
      }
      result.add(double.tryParse(value.toString()) ?? 0);
    }
    return result;
  }

  static List<List<int>> _parseMinMaxPattern(Object? source) {
    if (source is! List) {
      return const <List<int>>[];
    }

    final result = <List<int>>[];
    for (final point in source) {
      if (point is! List) {
        continue;
      }
      if (point.length < 2) {
        continue;
      }
      result.add(<int>[_parseInt(point[0]), _parseInt(point[1])]);
    }
    return result;
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}
