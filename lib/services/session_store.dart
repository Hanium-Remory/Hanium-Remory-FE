// 로컬 세션 저장 (자동 로그인 + 온보딩 1회).
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _kRefresh = 'refresh_token';
  static const _kAccess = 'access_token';
  static const _kProtectorId = 'protector_id';
  static const _kSeenOnboarding = 'seen_onboarding';
  static const _kElderGender = 'elder_gender';

  static String elderGender = 'female';
  static String get elderHonorific => elderGender == 'male' ? '아버님' : '어머님';

  static Future<void> initialize() async {
    final p = await SharedPreferences.getInstance();
    elderGender = p.getString(_kElderGender) ?? 'female';
  }

  static Future<void> setElderGender(String gender) async {
    elderGender = gender == 'male' ? 'male' : 'female';
    final p = await SharedPreferences.getInstance();
    await p.setString(_kElderGender, elderGender);
  }

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

  /// access 토큰이 만료됐을 때 재발급에 쓴다.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
    await p.setString(_kRefresh, refreshToken);
  }

  static Future<String?> accessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  static Future<String?> refreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  static Future<int?> protectorId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kProtectorId);
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
