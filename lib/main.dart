import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '1. splash_onboarding/splash_screen.dart';
import 'services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.initialize();
  runApp(const ReMoryApp());
}

class ReMoryApp extends StatelessWidget {
  const ReMoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _PhoneViewport(child: child),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBF6EE),
        fontFamily: 'Pretendard',
      ),
      home: const SplashScreen(),
    );
  }
}

class _PhoneViewport extends StatelessWidget {
  const _PhoneViewport({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final phoneSize = Size(
      size.width.clamp(0.0, 402.0),
      size.height.clamp(0.0, 874.0),
    );
    final mediaQuery = MediaQuery.of(context).copyWith(size: phoneSize);

    return ColoredBox(
      color: const Color(0xFFFBF6EE),
      child: Center(
        child: SizedBox(
          width: phoneSize.width,
          height: phoneSize.height,
          child: MediaQuery(
            data: mediaQuery,
            child: ScreenUtilInit(
              designSize: const Size(402, 874),
              minTextAdapt: true,
              splitScreenMode: true,
              enableScaleWH: () => false,
              enableScaleText: () => false,
              builder: (context, _) => child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
