class FirestorePaths {
  const FirestorePaths._();

  static String user(String uid) => 'users/$uid';

  static String islands(String uid) => 'users/$uid/islands';

  static String island(String uid, String islandId) =>
      '${islands(uid)}/$islandId';

  static String homeSummary(String uid, String islandId) =>
      'users/$uid/homeSummaries/$islandId';

  static String airportQueue(String islandId) => 'airportQueues/$islandId';

  static String marketPost(String postId) => 'marketPosts/$postId';

  static String marketPosts() => 'marketPosts';

  static String marketTradeCode(String offerId) => 'marketTradeCodes/$offerId';

  static String marketTradeCodes() => 'marketTradeCodes';

  static String marketTradeProposals(String offerId) =>
      '${marketPost(offerId)}/proposals';

  static String marketTradeProposal(String offerId, String proposerUid) =>
      '${marketTradeProposals(offerId)}/$proposerUid';

  static String report(String reportId) => 'reports/$reportId';

  static String catalogStates(String uid) => 'users/$uid/catalogStates';

  static String catalogState(String uid, String itemId) =>
      '${catalogStates(uid)}/$itemId';

  static String islandCatalogStates(String uid, String islandId) =>
      '${island(uid, islandId)}/catalogStates';

  static String islandCatalogState(
    String uid,
    String islandId,
    String itemId,
  ) => '${islandCatalogStates(uid, islandId)}/$itemId';

  static String turnipState(String uid, {String? islandId}) {
    if (islandId == null || islandId.isEmpty) {
      return 'users/$uid/turnip/state';
    }
    return '${island(uid, islandId)}/turnip/state';
  }

  static String userNotifications(String uid) => 'users/$uid/notifications';

  static String hiddenMarketOffers(String uid) =>
      'users/$uid/hiddenMarketOffers';

  static String hiddenMarketOffer(String uid, String offerId) =>
      '${hiddenMarketOffers(uid)}/$offerId';
}
