class LastIslandDeletionBlockedException implements Exception {
  const LastIslandDeletionBlockedException();

  String get message => '섬이 1개일 때는 삭제할 수 없어요.';

  @override
  String toString() => message;
}
