import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../2. pastkey/signup_method_screen.dart';
import '../4. home/home_and_alert_center.dart';
import '../services/session_store.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () async {
      // 자동 로그인 라우팅: 세션 있으면 홈, 온보딩 봤으면 가입방법, 처음이면 온보딩.
      final loggedIn = await SessionStore.isLoggedIn();
      final seenOnboarding = await SessionStore.hasSeenOnboarding();
      if (!mounted) return;
      final Widget next = loggedIn
          ? const HomeAndAlertPreview()
          : seenOnboarding
              ? const SignupMethodScreen()
              : const OnboardingScreen();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 56.sp,
                color: const Color(0xFF936249),
              ),

              SizedBox(height: 18.h),

              Text(
                'ReMory',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2F2521),
                ),
              ),

              SizedBox(height: 6.h),

              Text(
                '기억의 온도를 잇다',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: const Color(0xFF6D5A50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}// TODO Implement this library.