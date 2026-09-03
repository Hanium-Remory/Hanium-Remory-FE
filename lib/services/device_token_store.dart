// 발급받은 기기 토큰(X-Device-Token)을 이 폰에만 저장한다.
//
// 서버는 발급 응답에서만 값을 내려주고 다시는 알려주지 않는다. 인형에 값을
// 넣다가 앱을 닫거나, 나중에 다시 확인하고 싶을 때마다 재발급을 받으면
// 이미 인형에 넣어둔 토큰이 무효가 되므로, 마지막으로 발급한 값을 여기에
// 들고 있다가 프로필 화면에서 다시 보여준다.
//
// 저장 위치가 이 폰이라 앱을 지우거나 다른 폰으로 옮기면 사라진다. 그때는
// 서버의 hasDeviceToken 으로 "발급은 됐지만 값은 모른다"는 걸 구분한다.
import 'package:shared_preferences/shared_preferences.dart';

class DeviceTokenStore {
  /// 기기마다 따로 저장한다(어르신이 여럿이면 인형도 여럿이라서).
  static String _key(int deviceId) => 'device_token_$deviceId';

  static String _issuedAtKey(int deviceId) => 'device_token_issued_at_$deviceId';

  static Future<void> save(int deviceId, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(deviceId), token);
    await p.setString(
      _issuedAtKey(deviceId),
      DateTime.now().toIso8601String(),
    );
  }

  /// 이 폰에서 마지막으로 발급받은 값. 발급한 적이 없으면 null.
  static Future<String?> read(int deviceId) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key(deviceId));
  }

  static Future<DateTime?> issuedAt(int deviceId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_issuedAtKey(deviceId));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<void> clear(int deviceId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(deviceId));
    await p.remove(_issuedAtKey(deviceId));
  }
}
