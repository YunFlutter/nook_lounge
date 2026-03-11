class AppVersionComparator {
  const AppVersionComparator();

  int compare(String currentVersion, String targetVersion) {
    final currentParts = _parseVersionParts(currentVersion);
    final targetParts = _parseVersionParts(targetVersion);
    final maxLength = currentParts.length > targetParts.length
        ? currentParts.length
        : targetParts.length;

    for (var index = 0; index < maxLength; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final targetPart = index < targetParts.length ? targetParts[index] : 0;

      if (currentPart == targetPart) {
        continue;
      }

      return currentPart < targetPart ? -1 : 1;
    }

    return 0;
  }

  List<int> _parseVersionParts(String version) {
    return RegExp(r'\d+')
        .allMatches(version)
        .map((match) => int.tryParse(match.group(0) ?? '') ?? 0)
        .toList(growable: false);
  }
}
