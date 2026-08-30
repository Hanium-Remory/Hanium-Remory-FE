// 로컬 세션 저장 (자동 로그인 + 온보딩 1회).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 저장된 세션을 지금 쓸 수 있는지.
enum SessionState {
  /// 로그인한 적이 없거나 로그아웃했다.
  none,

  /// 자동 로그인할 수 있다.
  valid,

  /// 쓰던 계정이 있지만 만료됐다. 다시 로그인해야 한다.
  expired,
}

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

  /// 저장된 세션 상태. refresh 토큰의 exp 를 직접 보므로 서버가 필요 없다.
  ///
  /// 토큰이 있는지만 보고 홈으로 보내면, 만료된 토큰으로 들어가 401 만 보고
  /// 빠져나갈 길이 없어진다. 그래서 만료를 확인하는 김에 여기서 지운다.
  static Future<SessionState> sessionState() async {
    final p = await SharedPreferences.getInstance();
    final refresh = p.getString(_kRefresh) ?? '';
    if (refresh.isEmpty) return SessionState.none;
    if (!_isJwtExpired(refresh)) return SessionState.valid;
    await clear();
    return SessionState.expired;
  }

  /// JWT payload 의 exp 를 본다. 읽을 수 없으면 만료로 친다(안전한 쪽).
  static bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    try {
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
        isUtc: true,
      );
      // 경계에서 아슬아슬하게 통과시키지 않도록 여유를 둔다.
      return DateTime.now().toUtc().isAfter(
        expiresAt.subtract(const Duration(seconds: 30)),
      );
    } catch (_) {
      return true;
    }
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
