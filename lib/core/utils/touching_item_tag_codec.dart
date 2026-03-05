typedef TouchingItemTag = ({
  String id,
  String name,
  String imageUrl,
  String category,
});

const String _touchingItemTagPrefix = 'item';
const String _touchingItemTagDelimiter = '|||';

String encodeTouchingItemTag({
  required String id,
  required String name,
  required String imageUrl,
  required String category,
}) {
  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    return '';
  }
  final escapedId = _escapeTouchingItemTagField(id.trim());
  final escapedName = _escapeTouchingItemTagField(normalizedName);
  final escapedImageUrl = _escapeTouchingItemTagField(imageUrl.trim());
  final escapedCategory = _escapeTouchingItemTagField(category.trim());
  return <String>[
    _touchingItemTagPrefix,
    escapedId,
    escapedName,
    escapedImageUrl,
    escapedCategory,
  ].join(_touchingItemTagDelimiter);
}

TouchingItemTag? decodeTouchingItemTag(String raw) {
  final source = raw.trim();
  if (source.isEmpty) {
    return null;
  }
  final parts = source.split(_touchingItemTagDelimiter);
  if (parts.length < 5 || parts.first != _touchingItemTagPrefix) {
    return null;
  }

  final name = parts[2].trim();
  if (name.isEmpty) {
    return null;
  }
  return (
    id: parts[1].trim(),
    name: name,
    imageUrl: parts[3].trim(),
    category: parts[4].trim(),
  );
}

List<String> resolveTouchingTagLabels(List<String> tags) {
  final labels = <String>[];
  final seen = <String>{};
  for (final raw in tags) {
    final decoded = decodeTouchingItemTag(raw);
    if (decoded != null) {
      if (seen.add(decoded.name)) {
        labels.add(decoded.name);
      }
      continue;
    }

    for (final token in raw.split(',')) {
      final normalized = token.trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized)) {
        labels.add(normalized);
      }
    }
  }
  return labels;
}

String _escapeTouchingItemTagField(String value) {
  return value.replaceAll(_touchingItemTagDelimiter, ' ');
}
