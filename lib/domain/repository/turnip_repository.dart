import 'package:nook_lounge_app/domain/model/turnip_saved_data.dart';
import 'package:nook_lounge_app/domain/model/turnip_prediction.dart';

abstract class TurnipRepository {
  Future<TurnipPrediction> predict({required List<int> filter});

  Stream<TurnipSavedData?> watchSavedState({
    required String uid,
    required String islandId,
  });

  Future<void> saveState({
    required String uid,
    required String islandId,
    required TurnipSavedData data,
  });
}
