// ReMory 인증 API 클라이언트 (전화인증 + 패스키).
//
// backend_test.dart 에서 실기기로 검증한 로직을 실제 화면에서 재사용하기 위해
// 분리한 서비스. 화면은 이 클래스의 메서드만 호출하면 된다.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// 백엔드 주소. 실제 배포 도메인으로 교체하세요.
/// (패스키는 이 도메인이 rp_id 이며 assetlinks 를 HTTPS로 서빙해야 함)
const String kBackendBaseUrl = 'https://remory-passkey-hanium.onrender.com';

/// 로그인/가입 성공 시 발급되는 세션 정보.
class AuthResult {
  AuthResult({
    required this.protectorId,
    required this.accessToken,
    required this.refreshToken,
    required this.onboardingCompleted,
  });

  final int protectorId;
  final String accessToken;
  final String refreshToken;
  final bool onboardingCompleted;
}

class AuthApi {
  AuthApi({String? baseUrl}) : baseUrl = baseUrl ?? kBackendBaseUrl;

  final String baseUrl;
  final PasskeyAuthenticator _passkey = PasskeyAuthenticator();

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? bearer,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(decoded['message'] ?? '요청 실패 (${res.statusCode})');
    }
    return (decoded['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// 1) 인증번호(SMS OTP) 발송.
  Future<void> sendCode(String phone) =>
      _post('/auth/phone/verification-code', {'phoneNumber': phone});

  /// 2) 인증번호 확인 → registrationToken.
  /// alreadyRegistered=true 면 이미 가입된 번호(로그인으로 유도).
  Future<({String token, bool alreadyRegistered})> verifyCode(
      String phone, String code) async {
    final d = await _post('/auth/phone/verify', {
      'phoneNumber': phone,
      'code': code,
    });
    return (
      token: d['registrationToken'] as String,
      alreadyRegistered: d['alreadyRegistered'] == true,
    );
  }

  /// 패스키 생성(Face ID/지문) 공통 로직. 서버 응답 data를 그대로 반환.
  /// registerToken 이 있으면 번호에 묶여 즉시 완전가입, 없으면 Face-ID-first.
  Future<Map<String, dynamic>> _createPasskey({
    String? registerToken,
    String displayName = '보호자',
  }) async {
    final o = await _post(
      '/auth/passkey/registration/options',
      {'displayName': displayName},
      bearer: registerToken,
    );
    final rp = o['rp'] as Map<String, dynamic>;
    final user = o['user'] as Map<String, dynamic>;

    final reg = await _passkey.register(RegisterRequestType(
      challenge: o['challenge'] as String,
      relyingParty: RelyingPartyType(
        id: rp['id'] as String,
        name: rp['name'] as String,
      ),
      user: UserType(
        id: user['id'] as String,
        name: user['name'] as String,
        displayName: user['displayName'] as String,
      ),
      authSelectionType: AuthenticatorSelectionType(
        authenticatorAttachment: 'platform',
        requireResidentKey: false,
        residentKey: 'preferred',
        userVerification: 'required',
      ),
      pubKeyCredParams: (o['pubKeyCredParams'] as List)
          .map((e) => PubKeyCredParamType(
                type: e['type'] as String,
                alg: e['alg'] as int,
              ))
          .toList(),
      excludeCredentials: const [],
      timeout: o['timeout'] as int?,
      attestation: 'none',
    ));

    return _post('/auth/passkey/registration', {
      'credentialId': reg.id,
      'clientDataJSON': reg.clientDataJSON,
      'attestationObject': reg.attestationObject,
    }, bearer: registerToken);
  }

  /// Face-ID-first: 번호 없이 패스키부터 등록 → onboardingToken 반환.
  /// (다음 단계 attachPhone 에서 이 토큰으로 전화번호를 연결한다.)
  Future<String> registerPasskeyFirst({String displayName = '보호자'}) async {
    final d = await _createPasskey(displayName: displayName);
    return d['onboardingToken'] as String;
  }

  /// (번호 먼저 인증한 기존 흐름) 패스키 등록 → 세션 토큰.
  Future<AuthResult> registerPasskey(
    String registrationToken, {
    String displayName = '보호자',
  }) async {
    final d = await _createPasskey(
      registerToken: registrationToken,
      displayName: displayName,
    );
    return _toResult(d);
  }

  /// Face-ID-first: 전화번호 인증으로 패스키 계정에 번호를 연결 → 정식 세션 토큰.
  Future<AuthResult> attachPhone({
    required String onboardingToken,
    required String phone,
    required String code,
  }) async {
    final d = await _post(
      '/auth/phone/verify',
      {'phoneNumber': phone, 'code': code},
      bearer: onboardingToken,
    );
    return _toResult(d);
  }

  /// 4) 로그인(등록된 패스키로 서명) → 세션 토큰.
  Future<AuthResult> login(String phone) async {
    final o = await _post('/auth/passkey/authentication/options', {
      'phoneNumber': phone,
    });
    final allow = (o['allowCredentials'] as List? ?? [])
        .map((e) => CredentialType(
              type: e['type'] as String,
              id: e['id'] as String,
              transports: const [],
            ))
        .toList();

    final auth = await _passkey.authenticate(AuthenticateRequestType(
      relyingPartyId: o['rpId'] as String,
      challenge: o['challenge'] as String,
      timeout: o['timeout'] as int?,
      userVerification: o['userVerification'] as String?,
      allowCredentials: allow.isEmpty ? null : allow,
      mediation: MediationType.Optional,
      preferImmediatelyAvailableCredentials: true,
    ));

    final body = <String, dynamic>{
      'credentialId': auth.id,
      'clientDataJSON': auth.clientDataJSON,
      'authenticatorData': auth.authenticatorData,
      'signature': auth.signature,
    };
    if (auth.userHandle.isNotEmpty) body['userHandle'] = auth.userHandle;

    final d = await _post('/auth/passkey/authentication', body);
    return _toResult(d);
  }

  AuthResult _toResult(Map<String, dynamic> d) => AuthResult(
        protectorId: d['protectorId'] as int,
        accessToken: d['accessToken'] as String,
        refreshToken: d['refreshToken'] as String,
        onboardingCompleted: d['onboardingCompleted'] == true,
      );
}
