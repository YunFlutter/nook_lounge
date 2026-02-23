String formatRelativeTime(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(createdAt).inMilliseconds;

  if (diff < 60 * 1000) {
    return '방금 전';
  }

  final minutes = diff ~/ (60 * 1000);
  if (minutes < 60) {
    return '$minutes분 전';
  }

  final hours = diff ~/ (60 * 60 * 1000);
  if (hours < 24) {
    return '$hours시간 전';
  }

  final days = diff ~/ (24 * 60 * 60 * 1000);
  if (days == 1) {
    return '어제';
  }
  return '$days일 전';
}
