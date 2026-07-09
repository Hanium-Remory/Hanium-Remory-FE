// 로컬 세션 저장 (자동 로그인 + 온보딩 1회).
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _kRefresh = 'refresh_token';
  static const _kAccess = 'access_token';
  static const _kProtectorId = 'protector_id';
  static const _kSeenOnboarding = 'seen_onboarding';

  /// 로그인/가입 성공 시 토큰 저장.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int protectorId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
    await p.setString(_kRefresh, refreshToken);
    await p.setInt(_kProtectorId, protectorId);
  }

  /// 저장된 세션이 있으면(자동 로그인 대상) true.
  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_kRefresh) ?? '').isNotEmpty;
  }

  static Future<String?> accessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  /// 로그아웃/세션 초기화.
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kProtectorId);
  }

  static Future<void> setSeenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSeenOnboarding, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kSeenOnboarding) ?? false;
  }
}
