import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';

enum AirportVisitRequestStatus {
  pending('대기중'),
  invited('초대 완료'),
  arrived('섬에 있음'),
  cancelled('취소됨'),
  completed('방문 종료');

  const AirportVisitRequestStatus(this.label);

  final String label;

  static AirportVisitRequestStatus fromName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      // 유지보수 포인트:
      // 상태값이 비어있거나 손상된 레거시 문서는 활성 요청으로 보지 않도록
      // 기본값을 cancelled로 처리합니다.
      return AirportVisitRequestStatus.cancelled;
    }
    for (final status in AirportVisitRequestStatus.values) {
      if (status.name == normalized) {
        return status;
      }
    }
    return AirportVisitRequestStatus.cancelled;
  }
}

class AirportVisitRequest {
  const AirportVisitRequest({
    required this.id,
    required this.islandId,
    required this.hostUid,
    required this.hostName,
    required this.hostIslandName,
    required this.hostIslandImageUrl,
    required this.requesterUid,
    required this.requesterName,
    required this.requesterAvatarUrl,
    required this.requesterIslandName,
    required this.requesterIslandImageUrl,
    required this.message,
    required this.purpose,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
    this.invitedAt,
    this.arrivedAt,
    this.inviteCode,
    this.sourceType,
    this.sourceOfferId,
    this.sourceMoveType,
  });

  final String id;
  final String islandId;
  final String hostUid;
  final String hostName;
  final String hostIslandName;
  final String hostIslandImageUrl;
  final String requesterUid;
  final String requesterName;
  final String requesterAvatarUrl;
  final String requesterIslandName;
  final String requesterIslandImageUrl;
  final String message;
  final AirportVisitPurpose purpose;
  final AirportVisitRequestStatus status;
  final DateTime requestedAt;
  final DateTime updatedAt;
  final DateTime? invitedAt;
  final DateTime? arrivedAt;
  final String? inviteCode;
  final String? sourceType;
  final String? sourceOfferId;
  final String? sourceMoveType;

  bool get isPending => status == AirportVisitRequestStatus.pending;
  bool get isInvited => status == AirportVisitRequestStatus.invited;
  bool get isArrived => status == AirportVisitRequestStatus.arrived;

  bool get isActive {
    return status == AirportVisitRequestStatus.pending ||
        status == AirportVisitRequestStatus.invited ||
        status == AirportVisitRequestStatus.arrived;
  }

  AirportVisitRequest copyWith({
    String? id,
    String? islandId,
    String? hostUid,
    String? hostName,
    String? hostIslandName,
    String? hostIslandImageUrl,
    String? requesterUid,
    String? requesterName,
    String? requesterAvatarUrl,
    String? requesterIslandName,
    String? requesterIslandImageUrl,
    String? message,
    AirportVisitPurpose? purpose,
    AirportVisitRequestStatus? status,
    DateTime? requestedAt,
    DateTime? updatedAt,
    DateTime? invitedAt,
    DateTime? arrivedAt,
    String? inviteCode,
    String? sourceType,
    String? sourceOfferId,
    String? sourceMoveType,
  }) {
    return AirportVisitRequest(
      id: id ?? this.id,
      islandId: islandId ?? this.islandId,
      hostUid: hostUid ?? this.hostUid,
      hostName: hostName ?? this.hostName,
      hostIslandName: hostIslandName ?? this.hostIslandName,
      hostIslandImageUrl: hostIslandImageUrl ?? this.hostIslandImageUrl,
      requesterUid: requesterUid ?? this.requesterUid,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatarUrl: requesterAvatarUrl ?? this.requesterAvatarUrl,
      requesterIslandName: requesterIslandName ?? this.requesterIslandName,
      requesterIslandImageUrl:
          requesterIslandImageUrl ?? this.requesterIslandImageUrl,
      message: message ?? this.message,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      invitedAt: invitedAt ?? this.invitedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      inviteCode: inviteCode ?? this.inviteCode,
      sourceType: sourceType ?? this.sourceType,
      sourceOfferId: sourceOfferId ?? this.sourceOfferId,
      sourceMoveType: sourceMoveType ?? this.sourceMoveType,
    );
  }

  factory AirportVisitRequest.fromMap({
    required String id,
    required String islandId,
    required Map<String, dynamic> data,
  }) {
    return AirportVisitRequest(
      id: id,
      islandId: islandId,
      hostUid: (data['hostUid'] as String?)?.trim() ?? '',
      hostName: (data['hostName'] as String?)?.trim() ?? '호스트',
      hostIslandName: (data['hostIslandName'] as String?)?.trim() ?? '이름 없는 섬',
      hostIslandImageUrl: (data['hostIslandImageUrl'] as String?)?.trim() ?? '',
      requesterUid: (data['requesterUid'] as String?)?.trim() ?? '',
      requesterName: (data['requesterName'] as String?)?.trim() ?? '방문객',
      requesterAvatarUrl: (data['requesterAvatarUrl'] as String?)?.trim() ?? '',
      requesterIslandName:
          (data['requesterIslandName'] as String?)?.trim() ?? '이름 없는 섬',
      requesterIslandImageUrl:
          (data['requesterIslandImageUrl'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim() ?? '',
      purpose: AirportVisitPurpose.fromName(data['purpose'] as String?),
      status: AirportVisitRequestStatus.fromName(data['status'] as String?),
      requestedAt: _toDateTime(data['requestedAt']) ?? DateTime.now(),
      updatedAt:
          _toDateTime(data['updatedAt']) ??
          _toDateTime(data['requestedAt']) ??
          DateTime.now(),
      invitedAt: _toDateTime(data['invitedAt']),
      arrivedAt: _toDateTime(data['arrivedAt']),
      inviteCode: (data['inviteCode'] as String?)?.trim().toUpperCase(),
      sourceType: (data['sourceType'] as String?)?.trim(),
      sourceOfferId: (data['sourceOfferId'] as String?)?.trim(),
      sourceMoveType: (data['sourceMoveType'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hostUid': hostUid,
      'hostName': hostName,
      'hostIslandName': hostIslandName,
      'hostIslandImageUrl': hostIslandImageUrl,
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'requesterAvatarUrl': requesterAvatarUrl,
      'requesterIslandName': requesterIslandName,
      'requesterIslandImageUrl': requesterIslandImageUrl,
      'message': message,
      'purpose': purpose.name,
      'status': status.name,
      'requestedAt': requestedAt,
      'updatedAt': updatedAt,
      'invitedAt': invitedAt,
      'arrivedAt': arrivedAt,
      'inviteCode': inviteCode,
      'sourceType': sourceType,
      'sourceOfferId': sourceOfferId,
      'sourceMoveType': sourceMoveType,
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
