enum SupportInquiryType { general, appeal }

enum SupportInquiryStatus { received, processing, completed }

class SupportInquiry {
  const SupportInquiry({
    required this.id,
    required this.uid,
    required this.category,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.createdAt,
    this.adminReply,
    this.answeredAt,
  });

  final String id;
  final String uid;
  final String category;
  final String title;
  final String body;
  final SupportInquiryType type;
  final SupportInquiryStatus status;
  final DateTime createdAt;
  final String? adminReply;
  final DateTime? answeredAt;

  bool get isAppeal => type == SupportInquiryType.appeal;

  factory SupportInquiry.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return SupportInquiry(
      id: id,
      uid: (data['uid'] as String?)?.trim() ?? '',
      category: (data['category'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '문의 제목',
      body: (data['body'] as String?)?.trim() ?? '',
      type: _typeFromName((data['type'] as String?)?.trim()),
      status: _statusFromName((data['status'] as String?)?.trim()),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
      adminReply: (data['adminReply'] as String?)?.trim(),
      answeredAt: _toDateTime(data['answeredAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'category': category,
      'title': title,
      'body': body,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt,
      'adminReply': adminReply,
      'answeredAt': answeredAt,
    };
  }
}

SupportInquiryType _typeFromName(String? raw) {
  if (raw == null || raw.isEmpty) {
    return SupportInquiryType.general;
  }

  for (final type in SupportInquiryType.values) {
    if (type.name == raw) {
      return type;
    }
  }

  return SupportInquiryType.general;
}

SupportInquiryStatus _statusFromName(String? raw) {
  if (raw == null || raw.isEmpty) {
    return SupportInquiryStatus.received;
  }

  for (final status in SupportInquiryStatus.values) {
    if (status.name == raw) {
      return status;
    }
  }

  return SupportInquiryStatus.received;
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
