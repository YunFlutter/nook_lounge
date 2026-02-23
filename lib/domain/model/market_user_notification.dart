class MarketUserNotification {
  const MarketUserNotification({
    required this.id,
    required this.type,
    required this.offerId,
    required this.senderUid,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.tradeCode,
  });

  final String id;
  final String type;
  final String offerId;
  final String senderUid;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String tradeCode;

  bool get isTradeProposal => type == 'market_trade_proposal';
  bool get isTradeAccept => type == 'market_trade_accept';
  bool get isTradeCode => type == 'market_trade_code';
  bool get isTradeCancel => type == 'market_trade_cancel';

  factory MarketUserNotification.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return MarketUserNotification(
      id: id,
      type: (data['type'] as String?)?.trim() ?? '',
      offerId: (data['offerId'] as String?)?.trim() ?? '',
      senderUid: (data['senderUid'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? '',
      body: (data['body'] as String?)?.trim() ?? '',
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
      tradeCode: (data['tradeCode'] as String?)?.trim() ?? '',
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
