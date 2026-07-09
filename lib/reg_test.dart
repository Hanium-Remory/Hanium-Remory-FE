// 임시 진입점: 온보딩/앱 껍데기를 건너뛰고 가입 흐름만 바로 띄운다.
// 패스키 배선 테스트용. flutter run -t lib/reg_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '3. code/first_registration_flow.dart';

void main() => runApp(const _RegTestApp());

class _RegTestApp extends StatelessWidget {
  const _RegTestApp();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFBF6EE),
          fontFamily: 'Pretendard',
        ),
        home: const FirstRegistrationFlow(),
      ),
    );
  }
}
