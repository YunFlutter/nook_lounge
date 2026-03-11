class AppUpdateStatus {
  const AppUpdateStatus({
    required this.currentVersion,
    required this.remoteVersion,
    required this.requiresUpdate,
  });

  final String currentVersion;
  final String? remoteVersion;
  final bool requiresUpdate;
}
