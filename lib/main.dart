import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '1. splash_onboarding/splash_screen.dart';

void main() {
  runApp(const ReMoryApp());
}

class ReMoryApp extends StatelessWidget {
  const ReMoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // 디자인 기준 크기(고정). 첫 프레임에 View.of(context).physicalSize 가 0이라
      // 이를 designSize로 쓰면 ScreenUtil이 모든 크기를 0으로 계산해 화면이 비었었음.
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => _PhoneViewport(child: child),
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFBF6EE),
            fontFamily: 'Pretendard',
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class _PhoneViewport extends StatelessWidget {
  const _PhoneViewport({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // MaterialApp.builder 안에서는 LayoutBuilder의 maxHeight가 무한일 수 있어
    // SizedBox(height: 무한) → Scaffold의 Expanded가 터진다.
    // MediaQuery로 '유한한' 화면 크기를 받아 폭만 402로 제한한다.
    final size = MediaQuery.sizeOf(context);
    final width = size.width > 402 ? 402.0 : size.width;
    return ColoredBox(
      color: const Color(0xFFFBF6EE),
      child: Center(
        child: SizedBox(
          width: width,
          height: size.height,
          child: child,
        ),
      ),
    );
  }
}
