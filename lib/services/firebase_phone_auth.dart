// Firebase 전화번호 인증(SMS) 래퍼.
//
// 백엔드가 직접 SMS를 보내던 자리를 Firebase Phone Auth 로 대체한다.
// 여기서 얻은 Firebase ID 토큰을 백엔드에 넘기면 백엔드가
// Admin SDK 로 검증하고(phone_number 클레임) 세션을 발급해 준다.
//   → AuthApi.attachPhoneWithFirebase

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// 사용자에게 그대로 보여줄 수 있는 인증 실패 메시지.
class PhoneAuthException implements Exception {
  PhoneAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 화면에서 입력받은 번호를 Firebase 가 요구하는 E.164 로 바꾼다.
/// '010-1234-5678' → '+821012345678'
String toE164Korea(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.startsWith('82')) return '+$cleaned';
  if (cleaned.startsWith('0')) return '+82${cleaned.substring(1)}';
  return '+82$cleaned';
}

class FirebasePhoneAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;

  /// SMS 인증번호를 보낸다.
  ///
  /// Android 에서 기기가 문자를 자동으로 읽어 인증이 끝나면 ID 토큰을 바로
  /// 돌려준다(이 경우 인증번호 입력을 건너뛴다). 그 외에는 null 을 돌려주고,
  /// 사용자가 번호를 입력하면 [confirmCode] 로 마무리한다.
  Future<String?> sendCode(String phone) async {
    // 지정하지 않으면 영어 문자가 간다. 한국어 템플릿으로 받는다.
    _auth.setLanguageCode('ko');

    final completer = Completer<String?>();

    await _auth.verifyPhoneNumber(
      phoneNumber: toE164Korea(phone),
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      // Android 자동 인증. 코드 입력 없이 바로 끝난다.
      verificationCompleted: (credential) async {
        if (completer.isCompleted) return;
        try {
          completer.complete(await _signInAndGetIdToken(credential));
        } catch (e) {
          completer.completeError(
            e is PhoneAuthException ? e : PhoneAuthException('$e'),
          );
        }
      },
      verificationFailed: (e) {
        if (completer.isCompleted) return;
        completer.completeError(PhoneAuthException(_messageFor(e)));
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(null);
      },
      // 자동 읽기 시간이 지나도 수동 입력은 계속 가능하다.
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    return completer.future;
  }

  /// 사용자가 입력한 6자리 인증번호로 확인하고 Firebase ID 토큰을 얻는다.
  Future<String> confirmCode(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw PhoneAuthException('먼저 인증번호를 요청해 주세요.');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInAndGetIdToken(credential);
  }

  Future<String> _signInAndGetIdToken(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final idToken = await result.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw PhoneAuthException('인증 토큰을 받지 못했어요. 다시 시도해 주세요.');
      }
      return idToken;
    } on FirebaseAuthException catch (e) {
      throw PhoneAuthException(_messageFor(e));
    }
  }

  /// 백엔드 세션을 받고 나면 Firebase 쪽 로그인 상태는 더 필요 없다.
  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return '전화번호 형식을 확인해 주세요.';
      case 'invalid-verification-code':
        return '인증번호가 맞지 않아요.';
      case 'session-expired':
        return '인증번호가 만료됐어요. 다시 요청해 주세요.';
      case 'too-many-requests':
        return '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
      case 'quota-exceeded':
        return 'SMS 발송 한도를 넘었어요. 잠시 후 다시 시도해 주세요.';
      default:
        return e.message ?? '인증에 실패했어요. (${e.code})';
    }
  }
}
