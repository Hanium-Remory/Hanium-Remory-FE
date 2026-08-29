// ReMory 패스키 목업 앱 (Android/iOS 실기기 테스트용)
//
// 백엔드(remory-backend)의 인증 플로우를 손으로 눌러보며 검증한다:
//   전화번호 인증 → 패스키 등록(생체인증) → 로그인(생체인증) → 토큰 재발급
//
// 백엔드 API는 모두 { status, message, data } 봉투로 응답한다.
// 패스키 실기기 동작 조건:
//   - Base URL(=rp_id 도메인)이 HTTPS로 /.well-known/assetlinks.json(Android)
//     또는 apple-app-site-association(iOS)을 서빙해야 한다. (ngrok 권장)
//   - 안드로이드: 폰에 Google 계정 로그인 + 화면잠금/생체 설정 필요.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import 'services/auth_api.dart';

void main() => runApp(const RemoryMockApp());

class RemoryMockApp extends StatelessWidget {
  const RemoryMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReMory Passkey Mock',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _passkey = PasskeyAuthenticator();

  // 기본값은 EC2 운영 서버. 다른 주소로 시험하려면 화면에서 고치면 된다.
  final _baseUrl = TextEditingController(text: kBackendBaseUrl);
  final _phone = TextEditingController(text: '010-1234-5678');
  final _code = TextEditingController();

  String? _registrationToken;
  String? _accessToken;
  String? _refreshToken;
  final _log = <String>[];
  bool _busy = false;

  void _append(String line) {
    setState(() => _log.insert(0, line));
  }

  Uri _url(String path) => Uri.parse('${_baseUrl.text.trim()}$path');

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  /// 봉투에서 data를 꺼낸다. status가 2xx가 아니면 예외.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? bearer,
  }) async {
    final headers = {..._jsonHeaders};
    if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
    final res = await http.post(_url(path), headers: headers, body: jsonEncode(body));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    _append('◀ $path  [${res.statusCode}] ${decoded['message'] ?? ''}');
    if (res.statusCode >= 400) {
      throw Exception('$path 실패: ${decoded['message'] ?? res.body}');
    }
    return (decoded['data'] as Map<String, dynamic>? ) ?? <String, dynamic>{};
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _append('⚠️ $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  // ── 1) 인증번호 발송 ──────────────────────────────
  Future<void> _sendCode() => _guard(() async {
        final data = await _post('/auth/phone/verification-code', {
          'phoneNumber': _phone.text.trim(),
        });
        _append('📱 인증번호 발송됨 (유효 ${data['expiresInSec']}초). '
            '서버 로그의 [MOCK SMS] code 확인 후 입력하세요.');
      });

  // ── 2) 인증번호 확인 → registrationToken ──────────
  Future<void> _verifyCode() => _guard(() async {
        final data = await _post('/auth/phone/verify', {
          'phoneNumber': _phone.text.trim(),
          'code': _code.text.trim(),
        });
        _registrationToken = data['registrationToken'] as String?;
        final already = data['alreadyRegistered'] == true;
        _append('✅ 전화번호 인증 완료. '
            '${already ? "이미 가입됨 → 로그인으로" : "registrationToken 발급 → 패스키 등록 가능"}');
        setState(() {});
      });

  // ── 3) 패스키 등록 (생체인증 창이 떠야 성공 신호) ──
  Future<void> _register() => _guard(() async {
        if (_registrationToken == null) {
          throw Exception('먼저 전화번호 인증을 완료하세요.');
        }
        // 3-1. 서버에서 등록 옵션(challenge) 받기
        final opts = await _post(
          '/auth/passkey/registration/options',
          {'displayName': '보호자'},
          bearer: _registrationToken,
        );
        final rp = opts['rp'] as Map<String, dynamic>;
        final user = opts['user'] as Map<String, dynamic>;
        final params = (opts['pubKeyCredParams'] as List)
            .map((e) => PubKeyCredParamType(
                  type: e['type'] as String,
                  alg: e['alg'] as int,
                ))
            .toList();

        // 3-2. 기기에서 패스키 생성 (여기서 지문/얼굴 인증 프롬프트가 뜬다)
        _append('🔐 기기 패스키 생성 요청… (생체인증 프롬프트가 떠야 정상)');
        final reg = await _passkey.register(RegisterRequestType(
          challenge: opts['challenge'] as String,
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
          pubKeyCredParams: params,
          excludeCredentials: const [],
          timeout: opts['timeout'] as int?,
          attestation: 'none',
        ));

        // 3-3. 서버로 attestation 전송 → 검증·저장 → 토큰 발급
        final data = await _post('/auth/passkey/registration', {
          'credentialId': reg.id,
          'clientDataJSON': reg.clientDataJSON,
          'attestationObject': reg.attestationObject,
        }, bearer: _registrationToken);
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _append('🎉 가입 완료! protectorId=${data['protectorId']} '
            'accessToken 발급됨');
        setState(() {});
      });

  // ── 4) 로그인 (등록된 패스키로 서명) ──────────────
  Future<void> _login() => _guard(() async {
        // 4-1. 로그인 옵션(challenge + allowCredentials)
        final opts = await _post('/auth/passkey/authentication/options', {
          'phoneNumber': _phone.text.trim(),
        });
        final allow = (opts['allowCredentials'] as List? ?? [])
            .map((e) => CredentialType(
                  type: e['type'] as String,
                  id: e['id'] as String,
                  transports: const [],
                ))
            .toList();

        // 4-2. 기기 서명 (생체인증 프롬프트)
        _append('🔓 기기 서명 요청… (생체인증 프롬프트가 떠야 정상)');
        final auth = await _passkey.authenticate(AuthenticateRequestType(
          relyingPartyId: opts['rpId'] as String,
          challenge: opts['challenge'] as String,
          timeout: opts['timeout'] as int?,
          userVerification: opts['userVerification'] as String?,
          allowCredentials: allow.isEmpty ? null : allow,
          mediation: MediationType.Optional,
          preferImmediatelyAvailableCredentials: true,
        ));

        // 4-3. 서버로 assertion 전송 → 검증 → 토큰
        final data = await _post('/auth/passkey/authentication', {
          'credentialId': auth.id,
          'clientDataJSON': auth.clientDataJSON,
          'authenticatorData': auth.authenticatorData,
          'signature': auth.signature,
          if (auth.userHandle.isNotEmpty) 'userHandle': auth.userHandle,
        });
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _append('🎉 로그인 성공! protectorId=${data['protectorId']}');
        setState(() {});
      });

  // ── 5) 토큰 재발급 ────────────────────────────────
  Future<void> _refresh() => _guard(() async {
        if (_refreshToken == null) throw Exception('refreshToken이 없습니다.');
        final data = await _post('/auth/token/refresh', {
          'refreshToken': _refreshToken,
        });
        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _append('🔄 토큰 재발급 완료 (refresh 로테이션됨)');
        setState(() {});
      });

  @override
  Widget build(BuildContext context) {
    final canRegister = _registrationToken != null;
    return Scaffold(
      appBar: AppBar(title: const Text('ReMory 패스키 목업')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL (HTTPS, ngrok)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '인증번호 (서버 로그 확인)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('발송'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: _busy ? null : _verifyCode, child: const Text('1. 인증확인')),
                  FilledButton(onPressed: _busy || !canRegister ? null : _register, child: const Text('2. 패스키 등록')),
                  FilledButton(onPressed: _busy ? null : _login, child: const Text('3. 로그인')),
                  OutlinedButton(onPressed: _busy ? null : _refresh, child: const Text('4. 토큰재발급')),
                ],
              ),
              const Divider(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('로그 (최신순)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x0D000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _log.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
