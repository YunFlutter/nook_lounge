class AppVersionConfig {
  const AppVersionConfig({
    required this.documentId,
    this.androidVersion,
    this.iosVersion,
  });

  final String documentId;
  final String? androidVersion;
  final String? iosVersion;
}
