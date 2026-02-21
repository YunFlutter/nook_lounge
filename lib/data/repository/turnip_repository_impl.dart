import 'package:nook_lounge_app/data/datasource/turnip_api_data_source.dart';
import 'package:nook_lounge_app/data/datasource/turnip_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/turnip_prediction.dart';
import 'package:nook_lounge_app/domain/model/turnip_saved_data.dart';
import 'package:nook_lounge_app/domain/repository/turnip_repository.dart';

class TurnipRepositoryImpl implements TurnipRepository {
  TurnipRepositoryImpl({
    required TurnipApiDataSource apiDataSource,
    required TurnipFirestoreDataSource firestoreDataSource,
  }) : _apiDataSource = apiDataSource,
       _firestoreDataSource = firestoreDataSource;

  final TurnipApiDataSource _apiDataSource;
  final TurnipFirestoreDataSource _firestoreDataSource;

  @override
  Future<TurnipPrediction> predict({required List<int> filter}) async {
    final json = await _apiDataSource.requestPrediction(filter: filter);
    return TurnipPrediction.fromApiJson(json);
  }

  @override
  Stream<TurnipSavedData?> watchSavedState({required String uid}) {
    return _firestoreDataSource.watchTurnipState(uid);
  }

  @override
  Future<void> saveState({required String uid, required TurnipSavedData data}) {
    return _firestoreDataSource.saveTurnipState(uid: uid, data: data);
  }
}
