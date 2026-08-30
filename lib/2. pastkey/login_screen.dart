// 기존 사용자 로그인 화면.
//
// 가입 때 등록해 둔 패스키(Face ID/지문)로 서명해서 세션을 다시 받는다.
// 앱을 지웠거나 기기를 바꿔 세션이 비었을 때 들어오는 입구다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../main_shell.dart';
import '../services/auth_api.dart';
import '../services/session_store.dart';
import 'signup_method_screen.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = AuthApi();
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// 가입 화면으로. 스플래시에서 곧장 열렸을 때는 돌아갈 곳이 없어서
  /// pop 대신 가입 화면을 띄운다.
  void _goToSignup() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupMethodScreen()),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// 전화번호로 등록된 패스키를 찾아 생체인증 → 세션 저장 → 홈.
  Future<void> _onLogin() async {
    if (_busy) return;
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      _snack('전화번호를 확인해 주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _api.login(phone);
      await SessionStore.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        protectorId: result.protectorId,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('로그인 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.w),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 32.h,
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: Icon(
                                Icons.chevron_left,
                                color: _dark,
                                size: 21.sp,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 28.w),
                        Expanded(
                          child: Text(
                            '로그인',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                            ),
                          ),
                        ),
                        SizedBox(width: 28.w),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),
                        Text(
                          '다시 오셨네요',
                          style: TextStyle(
                            fontSize: 23.sp,
                            height: 1.25,
                            color: _dark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '가입할 때 쓰신 전화번호를 넣어주세요.\n비밀번호 없이 Face ID로 바로 들어갑니다.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            height: 1.55,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 30.h),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text(
                            '전화번호',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: _dark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 42.h,
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _onLogin(),
                            cursorColor: _brown,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _dark,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '전화번호를 입력하세요',
                              hintStyle: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFFB9ACA2),
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 14.w),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: _line),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: const BorderSide(color: _brown),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Icon(
                            Icons.center_focus_weak,
                            size: 60.sp,
                            color: _brown,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Center(
                          child: Text(
                            '등록해 두신 Face ID / 지문으로 확인해요',
                            style: TextStyle(
                              fontSize: 9.sp,
                              height: 1.35,
                              color: _muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _onLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _busy
                                  ? const Color(0xFFD2C5BC)
                                  : _brown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_open_rounded, size: 16.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  'Face ID로 로그인',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : _goToSignup,
                            child: Text(
                              '처음이신가요? 가입하기',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                  Container(
                    width: 58.w,
                    height: 3.h,
                    margin: EdgeInsets.only(bottom: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7B8AE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16.h),
                    Text(
                      '패스키로 로그인 중…\n생체인증을 진행하세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
