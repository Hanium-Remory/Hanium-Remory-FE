// FCM 푸시.
//
// 서버는 알림을 만들 때마다(감정 이상·연결 끊김·가족 메시지·리포트) 그
// 보호자의 폰으로 푸시를 보낸다. 앱이 하는 일은 세 가지다.
//
//   1. 권한을 받고 FCM 토큰을 서버에 등록한다(로그인 직후, 그리고 앱이 뜰 때).
//   2. 토큰이 바뀌면 다시 등록한다 — 앱을 지웠다 깔거나 데이터를 복원하면 바뀐다.
//   3. 로그아웃할 때 지운다. 안 지우면 폰을 넘겨받은 사람에게 남의 알림이 간다.
//
// 알림함 자체는 서버 DB 에 그대로 쌓이므로, 푸시가 막혀 있어도(권한 거부 등)
// 앱을 열면 알림을 볼 수 있다. 그래서 여기서 나는 실패는 전부 삼킨다.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'settings_api.dart';

class PushService {
  PushService._();

  static final SettingsApi _api = SettingsApi();

  /// 지금 이 폰에 등록해 둔 토큰. 로그아웃할 때 이걸 지운다.
  static String? _token;

  static StreamSubscription<String>? _refreshSub;

  /// 새 알림이 도착했다고 알려준다. 앱이 떠 있는 동안 온 푸시는 시스템
  /// 알림으로 뜨지 않으므로, 화면이 이걸 듣고 알림함을 다시 불러온다.
  static final ValueNotifier<int> arrived = ValueNotifier<int>(0);

  /// 로그인을 마친 뒤 부른다. 권한을 묻고 토큰을 등록한다.
  static Future<void> start() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 안드로이드 13+ 는 여기서 시스템 권한 창이 뜬다. 거부해도 토큰은 받는다.
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _register(token);

      // 한 번만 걸어 둔다. 로그아웃했다 다시 로그인해도 중복으로 붙지 않는다.
      _refreshSub ??= messaging.onTokenRefresh.listen(_register);

      FirebaseMessaging.onMessage.listen((_) => arrived.value++);
    } catch (e) {
      // 권한 거부, 구글 플레이 서비스 없음(에뮬레이터) 등. 앱은 그대로 쓴다.
      debugPrint('푸시를 켜지 못했어요: $e');
    }
  }

  /// 로그아웃할 때 부른다. 이 폰으로는 더 이상 알림이 오지 않는다.
  static Future<void> stop() async {
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _api.unregisterPushToken(token);
    } catch (_) {
      // 서버에 못 알려도 로그아웃은 그대로 진행한다. 남은 토큰으로 푸시가
      // 가더라도 앱을 열면 로그인 화면이라 내용이 보이지는 않는다.
    }
  }

  static Future<void> _register(String token) async {
    try {
      await _api.registerPushToken(token);
      _token = token;
    } catch (e) {
      debugPrint('푸시 토큰 등록 실패: $e');
    }
  }
}
