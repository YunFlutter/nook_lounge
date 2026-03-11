class FirestorePaths {
  const FirestorePaths._();

  static String user(String uid) => 'users/$uid';

  static String islands(String uid) => 'users/$uid/islands';

  static String island(String uid, String islandId) =>
      '${islands(uid)}/$islandId';

  static String homeSummary(String uid, String islandId) =>
      'users/$uid/homeSummaries/$islandId';

  static String airportQueues() => 'airportQueues';

  static String airportQueue(String islandId) => 'airportQueues/$islandId';

  static String airportRequests(String islandId) =>
      '${airportQueue(islandId)}/requests';

  static String airportRequest(String islandId, String requestId) =>
      '${airportRequests(islandId)}/$requestId';

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

  static String userServiceBlocks() => 'userServiceBlocks';

  static String userServiceBlock(String uid) => '${userServiceBlocks()}/$uid';

  static String hiddenMarketOffers(String uid) =>
      'users/$uid/hiddenMarketOffers';

  static String hiddenMarketOffer(String uid, String offerId) =>
      '${hiddenMarketOffers(uid)}/$offerId';

  static String blockedUsers(String uid) => 'users/$uid/blockedUsers';

  static String blockedUser(String uid, String blockedUid) =>
      '${blockedUsers(uid)}/$blockedUid';

  static String blockedByUsers(String uid) => 'users/$uid/blockedByUsers';

  static String blockedByUser(String uid, String blockerUid) =>
      '${blockedByUsers(uid)}/$blockerUid';

  static String userSettings(String uid) => 'users/$uid/settings';

  static String userSetting(String uid, String settingId) =>
      '${userSettings(uid)}/$settingId';

  static String supportInquiries() => 'supportInquiries';

  static String supportInquiry(String inquiryId) =>
      '${supportInquiries()}/$inquiryId';

  static String appVersions() => 'app_version';

  static String adminInquiryReplyTemplates() => 'adminInquiryReplyTemplates';

  static String adminInquiryReplyTemplate(String templateId) =>
      '${adminInquiryReplyTemplates()}/$templateId';

  static String appConfigFaqs() => 'app_config/faqs';

  static String moderationHistories() => 'moderationHistories';

  static String moderationHistory(String historyId) =>
      '${moderationHistories()}/$historyId';

  static String notices() => 'notices';

  static String notice(String noticeId) => '${notices()}/$noticeId';

  static String appNotices() => 'appNotices';

  static String appNotice(String noticeId) => '${appNotices()}/$noticeId';

  static String legalDocs() => 'legal_docs';

  static String legalDoc(String documentId) => '${legalDocs()}/$documentId';

  static String appDocuments() => 'appDocuments';

  static String appDocument(String documentId) =>
      '${appDocuments()}/$documentId';
}
