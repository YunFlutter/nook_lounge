import 'package:nook_lounge_app/domain/model/app_version_config.dart';

abstract class AppVersionRepository {
  Stream<AppVersionConfig?> watchConfig();
}
