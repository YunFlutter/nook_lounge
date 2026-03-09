class UserServiceBlock {
  const UserServiceBlock({
    required this.blockedUntilDateTime,
    this.blockedAtDateTime,
    this.reason,
  });

  final DateTime blockedUntilDateTime;
  final DateTime? blockedAtDateTime;
  final String? reason;

  bool isActiveAt(DateTime now) => blockedUntilDateTime.isAfter(now);

  String? get normalizedReason {
    final trimmedReason = reason?.trim();
    if (trimmedReason == null || trimmedReason.isEmpty) {
      return null;
    }
    return trimmedReason;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserServiceBlock &&
            other.blockedUntilDateTime == blockedUntilDateTime &&
            other.blockedAtDateTime == blockedAtDateTime &&
            other.reason == reason;
  }

  @override
  int get hashCode =>
      Object.hash(blockedUntilDateTime, blockedAtDateTime, reason);
}
