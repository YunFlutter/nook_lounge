import 'package:shared_preferences/shared_preferences.dart';

class PageGuideService {
  static const String _seenPrefix = 'page_guide_seen.';

  SharedPreferences? _preferences;

  Future<bool> hasSeen(String storageKey) async {
    try {
      final preferences = await _getPreferences();
      return preferences.getBool(_buildSeenKey(storageKey)) ?? false;
    } catch (_) {
      // 유지보수 포인트:
      // 로컬 저장소 초기화에 실패하더라도 페이지 진입 자체는 막지 않습니다.
      // 이 경우 가이드는 다시 노출될 수 있지만 앱 흐름은 유지됩니다.
      return false;
    }
  }

  Future<void> markSeen(String storageKey) async {
    try {
      final preferences = await _getPreferences();
      await preferences.setBool(_buildSeenKey(storageKey), true);
    } catch (_) {
      // 유지보수 포인트:
      // 저장 실패는 사용자 동선보다 우선순위가 낮으므로 조용히 무시합니다.
    }
  }

  Future<void> reset(String storageKey) async {
    try {
      final preferences = await _getPreferences();
      await preferences.remove(_buildSeenKey(storageKey));
    } catch (_) {
      // 유지보수 포인트:
      // 디버그/운영 중 재노출 복구가 필요할 때 사용하는 유틸 메서드입니다.
    }
  }

  Future<SharedPreferences> _getPreferences() async {
    final cachedPreferences = _preferences;
    if (cachedPreferences != null) {
      return cachedPreferences;
    }

    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    return preferences;
  }

  String _buildSeenKey(String storageKey) {
    return '$_seenPrefix$storageKey';
  }
}
