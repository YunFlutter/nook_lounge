import 'package:cloud_firestore/cloud_firestore.dart';

enum AirportVisitPurpose {
  moveOut('이사 보내기'),
  moveIn('이사 받기'),
  turnip('무주식'),
  touching('만지작'),
  design('디자인 공유');

  const AirportVisitPurpose(this.label);

  final String label;

  static AirportVisitPurpose fromName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AirportVisitPurpose.touching;
    }
    for (final purpose in AirportVisitPurpose.values) {
      if (purpose.name == value) {
        return purpose;
      }
    }
    return AirportVisitPurpose.touching;
  }
}

class AirportSession {
  const AirportSession({
    required this.islandId,
    required this.ownerUid,
    required this.islandName,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.islandImageUrl,
    required this.introMessage,
    required this.rules,
    required this.purpose,
    required this.gateOpen,
    required this.dodoCode,
    required this.updatedAt,
    required this.capacity,
    this.dodoCodeUpdatedAt,
  });

  final String islandId;
  final String ownerUid;
  final String islandName;
  final String hostName;
  final String hostAvatarUrl;
  final String islandImageUrl;
  final String introMessage;
  final String rules;
  final AirportVisitPurpose purpose;
  final bool gateOpen;
  final String dodoCode;
  final DateTime updatedAt;
  final DateTime? dodoCodeUpdatedAt;
  final int capacity;

  static const String defaultIntroMessage = '너굴너굴섬에 놀러오세요!';
  static const String defaultRules =
      '1. 꽃 밟지 않기\n2. 열매 따먹지 않기\n3. 게시판에 방문록 남기기';
  static const int codeLifetimeMinutes = 10;

  String activeDodoCode({DateTime? now}) {
    final normalized = dodoCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      return '';
    }
    final baseTime = dodoCodeUpdatedAt ?? updatedAt;
    final nowDateTime = now ?? DateTime.now();
    final expired = nowDateTime.isAfter(
      baseTime.add(const Duration(minutes: codeLifetimeMinutes)),
    );
    if (expired) {
      return '';
    }
    return normalized;
  }

  bool get hasActiveDodoCode => activeDodoCode().isNotEmpty;

  AirportSession copyWith({
    String? islandId,
    String? ownerUid,
    String? islandName,
    String? hostName,
    String? hostAvatarUrl,
    String? islandImageUrl,
    String? introMessage,
    String? rules,
    AirportVisitPurpose? purpose,
    bool? gateOpen,
    String? dodoCode,
    DateTime? updatedAt,
    DateTime? dodoCodeUpdatedAt,
    int? capacity,
  }) {
    return AirportSession(
      islandId: islandId ?? this.islandId,
      ownerUid: ownerUid ?? this.ownerUid,
      islandName: islandName ?? this.islandName,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      islandImageUrl: islandImageUrl ?? this.islandImageUrl,
      introMessage: introMessage ?? this.introMessage,
      rules: rules ?? this.rules,
      purpose: purpose ?? this.purpose,
      gateOpen: gateOpen ?? this.gateOpen,
      dodoCode: dodoCode ?? this.dodoCode,
      updatedAt: updatedAt ?? this.updatedAt,
      dodoCodeUpdatedAt: dodoCodeUpdatedAt ?? this.dodoCodeUpdatedAt,
      capacity: capacity ?? this.capacity,
    );
  }

  factory AirportSession.fromMap({
    required String islandId,
    required Map<String, dynamic> data,
  }) {
    return AirportSession(
      islandId: islandId,
      ownerUid: (data['ownerUid'] as String?)?.trim() ?? '',
      islandName: (data['islandName'] as String?)?.trim() ?? '이름 없는 섬',
      hostName: (data['hostName'] as String?)?.trim() ?? '호스트',
      hostAvatarUrl: (data['hostAvatarUrl'] as String?)?.trim() ?? '',
      islandImageUrl: (data['islandImageUrl'] as String?)?.trim() ?? '',
      introMessage: (data['introMessage'] as String?)?.trim().isNotEmpty == true
          ? (data['introMessage'] as String).trim()
          : defaultIntroMessage,
      rules: (data['rules'] as String?)?.trim().isNotEmpty == true
          ? (data['rules'] as String).trim()
          : defaultRules,
      purpose: AirportVisitPurpose.fromName(data['purpose'] as String?),
      gateOpen: (data['gateOpen'] as bool?) ?? false,
      dodoCode: (data['dodoCode'] as String?)?.trim().toUpperCase() ?? '',
      updatedAt: _toDateTime(data['updatedAt']) ?? DateTime.now(),
      dodoCodeUpdatedAt: _toDateTime(data['dodoCodeUpdatedAt']),
      capacity: ((data['capacity'] as num?)?.toInt() ?? 8).clamp(1, 8),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerUid': ownerUid,
      'islandName': islandName,
      'hostName': hostName,
      'hostAvatarUrl': hostAvatarUrl,
      'islandImageUrl': islandImageUrl,
      'introMessage': introMessage,
      'rules': rules,
      'purpose': purpose.name,
      'gateOpen': gateOpen,
      'dodoCode': dodoCode.trim().toUpperCase(),
      'updatedAt': updatedAt,
      'dodoCodeUpdatedAt': dodoCodeUpdatedAt,
      'capacity': capacity,
    };
  }
}

DateTime? _toDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  try {
    final dynamic parsed = (value as dynamic).toDate();
    if (parsed is DateTime) {
      return parsed;
    }
  } catch (_) {}
  return null;
}
