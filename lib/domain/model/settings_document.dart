enum SettingsDocumentType { operationPolicy, termsOfService, privacyPolicy }

class SettingsDocument {
  const SettingsDocument({
    required this.type,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final SettingsDocumentType type;
  final String title;
  final String body;
  final DateTime updatedAt;

  factory SettingsDocument.fromMap({
    required SettingsDocumentType type,
    required Map<String, dynamic> data,
  }) {
    return SettingsDocument(
      type: type,
      title: (data['title'] as String?)?.trim() ?? type.defaultTitle,
      body: (data['body'] as String?)?.trim() ?? '',
      updatedAt: _toDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }
}

extension SettingsDocumentTypeX on SettingsDocumentType {
  String get documentId {
    switch (this) {
      case SettingsDocumentType.operationPolicy:
        return 'operationPolicy';
      case SettingsDocumentType.termsOfService:
        return 'termsOfService';
      case SettingsDocumentType.privacyPolicy:
        return 'privacyPolicy';
    }
  }

  String get defaultTitle {
    switch (this) {
      case SettingsDocumentType.operationPolicy:
        return '운영정책';
      case SettingsDocumentType.termsOfService:
        return '이용약관';
      case SettingsDocumentType.privacyPolicy:
        return '개인정보처리방침';
    }
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
