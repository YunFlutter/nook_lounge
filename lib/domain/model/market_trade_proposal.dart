import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_trade_proposal.freezed.dart';

enum MarketTradeProposalStatus {
  pending('대기중'),
  accepted('승낙됨'),
  rejected('거절됨'),
  cancelled('취소됨');

  const MarketTradeProposalStatus(this.label);
  final String label;
}

@freezed
sealed class MarketTradeProposal with _$MarketTradeProposal {
  const MarketTradeProposal._();

  const factory MarketTradeProposal({
    required String id,
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    @Default('') String proposerName,
    @Default('') String proposerAvatarUrl,
    required MarketTradeProposalStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? acceptedAt,
  }) = _MarketTradeProposal;

  bool get isPending => status == MarketTradeProposalStatus.pending;
  bool get isAccepted => status == MarketTradeProposalStatus.accepted;

  factory MarketTradeProposal.fromMap({
    required String id,
    required String offerId,
    required Map<String, dynamic> data,
  }) {
    return MarketTradeProposal(
      id: id,
      offerId: offerId,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      proposerUid: (data['proposerUid'] as String?) ?? '',
      proposerName: (data['proposerName'] as String?) ?? '',
      proposerAvatarUrl: (data['proposerAvatarUrl'] as String?) ?? '',
      status: _parseEnum(
        values: MarketTradeProposalStatus.values,
        value: data['status'] as String?,
        fallback: MarketTradeProposalStatus.pending,
      ),
      createdAt: _parseDateTime(
        dateTime: data['createdAt'],
        legacyMillis: data['createdAtMillis'],
      ),
      updatedAt: _parseDateTime(
        dateTime: data['updatedAt'] ?? data['createdAt'],
        legacyMillis: data['updatedAtMillis'] ?? data['createdAtMillis'],
      ),
      acceptedAt: _parseNullableDateTime(
        dateTime: data['acceptedAt'],
        legacyMillis: data['acceptedAtMillis'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'offerId': offerId,
      'ownerUid': ownerUid,
      'proposerUid': proposerUid,
      'proposerName': proposerName,
      'proposerAvatarUrl': proposerAvatarUrl,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'acceptedAt': acceptedAt,
    };
  }
}

T _parseEnum<T extends Enum>({
  required List<T> values,
  required String? value,
  required T fallback,
}) {
  if (value == null) {
    return fallback;
  }
  for (final item in values) {
    if (item.name == value) {
      return item;
    }
  }
  return fallback;
}

DateTime _parseDateTime({
  required Object? dateTime,
  required Object? legacyMillis,
}) {
  final parsed = _toDateTime(dateTime);
  if (parsed != null) {
    return parsed;
  }
  final millis = _toInt(legacyMillis);
  if (millis != null && millis > 0) {
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return DateTime.now();
}

DateTime? _parseNullableDateTime({
  required Object? dateTime,
  required Object? legacyMillis,
}) {
  final parsed = _toDateTime(dateTime);
  if (parsed != null) {
    return parsed;
  }
  final millis = _toInt(legacyMillis);
  if (millis != null && millis > 0) {
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return null;
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

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
