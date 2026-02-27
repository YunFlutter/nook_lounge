enum SettingsNotificationType {
  tradeOffer,
  dodoCodeInvite,
  airportQueueStandby,
}

class SettingsNotificationPreferences {
  const SettingsNotificationPreferences({
    required this.tradeOfferEnabled,
    required this.dodoCodeInviteEnabled,
    required this.airportQueueStandbyEnabled,
  });

  static const String tradeOfferField = 'tradeOfferEnabled';
  static const String dodoCodeInviteField = 'dodoCodeInviteEnabled';
  static const String airportQueueStandbyField = 'airportQueueStandbyEnabled';

  static const SettingsNotificationPreferences defaults =
      SettingsNotificationPreferences(
        tradeOfferEnabled: true,
        dodoCodeInviteEnabled: true,
        airportQueueStandbyEnabled: false,
      );

  final bool tradeOfferEnabled;
  final bool dodoCodeInviteEnabled;
  final bool airportQueueStandbyEnabled;

  SettingsNotificationPreferences copyWith({
    bool? tradeOfferEnabled,
    bool? dodoCodeInviteEnabled,
    bool? airportQueueStandbyEnabled,
  }) {
    return SettingsNotificationPreferences(
      tradeOfferEnabled: tradeOfferEnabled ?? this.tradeOfferEnabled,
      dodoCodeInviteEnabled:
          dodoCodeInviteEnabled ?? this.dodoCodeInviteEnabled,
      airportQueueStandbyEnabled:
          airportQueueStandbyEnabled ?? this.airportQueueStandbyEnabled,
    );
  }

  factory SettingsNotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return defaults;
    }

    return SettingsNotificationPreferences(
      tradeOfferEnabled:
          (map[tradeOfferField] as bool?) ?? defaults.tradeOfferEnabled,
      dodoCodeInviteEnabled:
          (map[dodoCodeInviteField] as bool?) ?? defaults.dodoCodeInviteEnabled,
      airportQueueStandbyEnabled:
          (map[airportQueueStandbyField] as bool?) ??
          defaults.airportQueueStandbyEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      tradeOfferField: tradeOfferEnabled,
      dodoCodeInviteField: dodoCodeInviteEnabled,
      airportQueueStandbyField: airportQueueStandbyEnabled,
    };
  }

  String fieldNameOf(SettingsNotificationType type) {
    switch (type) {
      case SettingsNotificationType.tradeOffer:
        return tradeOfferField;
      case SettingsNotificationType.dodoCodeInvite:
        return dodoCodeInviteField;
      case SettingsNotificationType.airportQueueStandby:
        return airportQueueStandbyField;
    }
  }
}
