class FirestorePaths {
  const FirestorePaths._();

  static String user(String uid) => 'users/$uid';

  static String island(String uid, String islandId) =>
      'users/$uid/islands/$islandId';

  static String homeSummary(String uid, String islandId) =>
      'users/$uid/homeSummaries/$islandId';

  static String airportQueue(String islandId) => 'airportQueues/$islandId';

  static String marketPost(String postId) => 'marketPosts/$postId';

  static String report(String reportId) => 'reports/$reportId';

  static String catalogStates(String uid) => 'users/$uid/catalogStates';

  static String catalogState(String uid, String itemId) =>
      '${catalogStates(uid)}/$itemId';
}
