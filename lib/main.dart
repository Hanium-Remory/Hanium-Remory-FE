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
    final view = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;

    return ScreenUtilInit(
      designSize: logicalSize,
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
    return ColoredBox(
      color: const Color(0xFFFBF6EE),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 402
              ? 402.0
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
