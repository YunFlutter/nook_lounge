class SettingsNotice {
  const SettingsNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;

  factory SettingsNotice.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return SettingsNotice(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '공지 제목',
      body: (data['body'] as String?)?.trim() ?? '',
      publishedAt: _toDateTime(data['publishedAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _toDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  try {
    final dynamic converted = (value as dynamic).toDate();
    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {}
  return null;
}
