class BlockedUserSummary {
  const BlockedUserSummary({
    required this.uid,
    required this.displayName,
    required this.islandName,
    required this.avatarUrl,
    required this.blockedAt,
  });

  final String uid;
  final String displayName;
  final String islandName;
  final String avatarUrl;
  final DateTime blockedAt;

  bool get hasAvatar => avatarUrl.trim().isNotEmpty;
}
