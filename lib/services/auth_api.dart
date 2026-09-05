// ReMory 인증 API 클라이언트 (전화인증 + 패스키).
//
// backend_test.dart 에서 실기기로 검증한 로직을 실제 화면에서 재사용하기 위해
// 분리한 서비스. 화면은 이 클래스의 메서드만 호출하면 된다.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// 백엔드 주소. 기본값은 EC2 운영 서버다.
/// (패스키는 이 도메인이 rp_id 이며 assetlinks 를 HTTPS로 서빙해야 함)
///
/// 로컬 백엔드로 붙이려면 실행할 때 넘긴다:
///   flutter run --dart-define=BACKEND_BASE_URL=http://localhost:8000
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://32-184-124-116.sslip.io',
);

/// Firebase ID 토큰을 세션으로 바꿔주는 백엔드 엔드포인트 경로.
///
/// 백엔드에 이미 구현돼 있다(app/routers/phone.py). 경로가 바뀌면 실행할 때
/// 넘겨서 덮을 수 있다:
///   flutter run --dart-define=FIREBASE_VERIFY_PATH=/auth/phone/other
const String kFirebaseVerifyPath = String.fromEnvironment(
  'FIREBASE_VERIFY_PATH',
  defaultValue: '/auth/phone/verify-firebase',
);

/// 초대 코드로 가입하면서 곧바로 연결된 어르신.
class LinkedUser {
  LinkedUser({required this.userId, required this.name});

  factory LinkedUser.fromJson(Map<String, dynamic> json) => LinkedUser(
        userId: json['userId'] as int,
        name: (json['name'] as String?) ?? '',
      );

  final int userId;
  final String name;
}

/// 로그인/가입 성공 시 발급되는 세션 정보.
class AuthResult {
  AuthResult({
    required this.protectorId,
    required this.accessToken,
    required this.refreshToken,
    required this.onboardingCompleted,
    this.linkedUser,
  });

  final int protectorId;
  final String accessToken;
  final String refreshToken;
  final bool onboardingCompleted;

  /// 초대 코드를 함께 보냈을 때만 채워진다. 있으면 어르신을 새로 등록할
  /// 필요가 없다(이미 그 가족에 붙었다).
  final LinkedUser? linkedUser;
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
  ///
  /// [inviteCode]·[name]·[relation] 은 이 단계까지 access token 이 없어
  /// 앱이 들고 있던 값이다. 서버가 번호를 붙이면서 함께 저장한다.
  Future<AuthResult> attachPhone({
    required String onboardingToken,
    required String phone,
    required String code,
    String? inviteCode,
    String? name,
    String? relation,
  }) async {
    final d = await _post(
      '/auth/phone/verify',
      {
        'phoneNumber': phone,
        'code': code,
        ..._signupExtras(inviteCode: inviteCode, name: name, relation: relation),
      },
      bearer: onboardingToken,
    );
    return _toResult(d);
  }

  /// 가입 화면에서 모아 온 값 중 채워진 것만 요청에 싣는다.
  Map<String, dynamic> _signupExtras({
    String? inviteCode,
    String? name,
    String? relation,
  }) {
    final trimmed = name?.trim();
    return {
      if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
      if (trimmed != null && trimmed.isNotEmpty) 'name': trimmed,
      if (relation != null && relation.isNotEmpty) 'relation': relation,
    };
  }

  /// Face-ID-first: Firebase SMS 인증 결과로 번호를 연결 → 정식 세션 토큰.
  ///
  /// [idToken] 은 FirebasePhoneAuth 가 돌려준 Firebase ID 토큰이다.
  /// 백엔드는 Admin SDK 로 verifyIdToken 한 뒤 phone_number 클레임을
  /// onboardingToken 이 가리키는 패스키 계정에 연결하면 된다.
  ///
  ///   POST $kFirebaseVerifyPath
  ///   `Authorization: Bearer <onboardingToken>`
  ///   `{ "idToken": "<Firebase ID token>", "inviteCode"?, "name"?, "relation"? }`
  ///   → data: { protectorId, accessToken, refreshToken, onboardingCompleted,
  ///             linkedUser }
  Future<AuthResult> attachPhoneWithFirebase({
    required String onboardingToken,
    required String idToken,
    String? inviteCode,
    String? name,
    String? relation,
  }) async {
    final d = await _post(
      kFirebaseVerifyPath,
      {
        'idToken': idToken,
        ..._signupExtras(inviteCode: inviteCode, name: name, relation: relation),
      },
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

  AuthResult _toResult(Map<String, dynamic> d) {
    final linked = d['linkedUser'] as Map<String, dynamic>?;
    return AuthResult(
      protectorId: d['protectorId'] as int,
      accessToken: d['accessToken'] as String,
      refreshToken: d['refreshToken'] as String,
      onboardingCompleted: d['onboardingCompleted'] == true,
      linkedUser: linked == null ? null : LinkedUser.fromJson(linked),
    );
  }
}
