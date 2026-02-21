class ResidentLimitExceededException implements Exception {
  const ResidentLimitExceededException({this.maxCount = 10});

  final int maxCount;

  String get message => '거주 주민은 최대 $maxCount명까지 설정할 수 있어요.';

  @override
  String toString() => message;
}
