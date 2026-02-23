import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';

part 'market_trade_code_session.freezed.dart';

@freezed
sealed class MarketTradeCodeSession with _$MarketTradeCodeSession {
  const MarketTradeCodeSession._();

  const factory MarketTradeCodeSession({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    @Default('') String code,
    @Default('') String codeSenderUid,
    @Default('') String codeReceiverUid,
    required DateTime acceptedAt,
    DateTime? codeSentAt,
    required DateTime updatedAt,
  }) = _MarketTradeCodeSession;

  bool get hasCode => code.trim().length == 6;

  bool isCodeSender(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return codeSenderUid == normalized;
  }

  bool isCodeReceiver(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return codeReceiverUid == normalized;
  }

  factory MarketTradeCodeSession.fromMap({
    required String offerId,
    required Map<String, dynamic> data,
  }) {
    return MarketTradeCodeSession(
      offerId: offerId,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      proposerUid: (data['proposerUid'] as String?) ?? '',
      moveType: _parseEnum(
        values: MarketMoveType.values,
        value: data['moveType'] as String?,
        fallback: MarketMoveType.visitor,
      ),
      code: (data['code'] as String?) ?? '',
      codeSenderUid: (data['codeSenderUid'] as String?) ?? '',
      codeReceiverUid: (data['codeReceiverUid'] as String?) ?? '',
      acceptedAt: _parseDateTime(
        dateTime: data['acceptedAt'],
        legacyMillis: data['acceptedAtMillis'],
      ),
      codeSentAt: _parseNullableDateTime(
        dateTime: data['codeSentAt'],
        legacyMillis: data['codeSentAtMillis'],
      ),
      updatedAt: _parseDateTime(
        dateTime: data['updatedAt'],
        legacyMillis: data['updatedAtMillis'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'offerId': offerId,
      'ownerUid': ownerUid,
      'proposerUid': proposerUid,
      'moveType': moveType.name,
      'code': code,
      'codeSenderUid': codeSenderUid,
      'codeReceiverUid': codeReceiverUid,
      'acceptedAt': acceptedAt,
      'codeSentAt': codeSentAt,
      'updatedAt': updatedAt,
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
