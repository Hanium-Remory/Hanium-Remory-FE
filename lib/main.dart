import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '1. splash_onboarding/splash_screen.dart';
import '2. pastkey/login_screen.dart';
import 'firebase_options.dart';
import 'services/session_store.dart';
import 'services/settings_api.dart';

/// 어느 화면에서든 로그인으로 되돌릴 수 있도록 앱 전역 Navigator 를 잡아 둔다.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SessionStore.initialize();
  // 세션이 되살릴 수 없게 끊기면(재발급 실패) 로그인 화면으로 되돌린다.
  onSessionExpired = _handleSessionExpired;
  runApp(const ReMoryApp());
}

/// 저장된 세션은 이미 지워진 채로 불린다(SettingsApi._forceRelogin).
/// 여기서는 화면만 로그인으로 갈아끼운다. 스택을 비워 뒤로가기로 못 돌아오게 한다.
Future<void> _handleSessionExpired() async {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

class ReMoryApp extends StatelessWidget {
  const ReMoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
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
