import 'package:nook_lounge_app/data/datasource/app_version_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/model/app_version_config.dart';
import 'package:nook_lounge_app/domain/repository/app_version_repository.dart';

class AppVersionRepositoryImpl implements AppVersionRepository {
  AppVersionRepositoryImpl({required AppVersionFirestoreDataSource dataSource})
    : _dataSource = dataSource;

  final AppVersionFirestoreDataSource _dataSource;

  @override
  Stream<AppVersionConfig?> watchConfig() {
    return _dataSource.watchConfig();
  }
}
