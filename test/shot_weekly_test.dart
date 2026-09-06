import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/7.%20report/daily_report_screen.dart';

void main() {
  testWidgets('주간 리포트 그림', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => const MaterialApp(home: WeeklyReportScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    final image = await tester.binding.runAsync(() async {
      final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary),
      );
      return boundary.toImage(pixelRatio: 2.0);
    });
    final bytes = await image!.toByteData(format: ui.ImageByteFormat.png);
    File('/tmp/claude-501/-Users-iseul-Desktop-flutter/a564fe61-6e5d-41c3-827d-812cc75ef576/scratchpad/weekly.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
