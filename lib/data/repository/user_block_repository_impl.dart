import 'package:nook_lounge_app/data/datasource/user_block_firestore_data_source.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';

class UserBlockRepositoryImpl implements UserBlockRepository {
  UserBlockRepositoryImpl({required UserBlockFirestoreDataSource dataSource})
    : _dataSource = dataSource;

  final UserBlockFirestoreDataSource _dataSource;

  @override
  Stream<Set<String>> watchBlockedUserIds(String uid) {
    return _dataSource.watchBlockedUserIds(uid);
  }

  @override
  Stream<Set<String>> watchInvisibleUserIds(String uid) {
    return _dataSource.watchInvisibleUserIds(uid);
  }

  @override
  Future<void> blockUser({required String uid, required String blockedUid}) {
    return _dataSource.blockUser(uid: uid, blockedUid: blockedUid);
  }

  @override
  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  }) {
    return _dataSource.hasBlockRelationship(uid: uid, otherUid: otherUid);
  }
}
