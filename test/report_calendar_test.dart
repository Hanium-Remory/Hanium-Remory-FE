// 리포트 달력. 점이 있는 날만 고를 수 있어야 한다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/7.%20report/report_calendar_sheet.dart';

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// 달력을 띄우고, 고른 날짜를 담아 둔다.
Future<DateTime?> _open(
  WidgetTester tester, {
  required Set<DateTime> marked,
  required DateTime focused,
}) async {
  DateTime? picked;
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            picked = await showReportCalendar(
              context, markedDays: marked, focusedDay: focused);
          },
          child: const Text('열기'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  final focused = DateTime(2026, 9, 6);

  testWidgets('고른 달을 보여준다', (tester) async {
    _usePhoneScreen(tester);
    await _open(tester, marked: {}, focused: focused);
    expect(find.text('2026년 9월'), findsOneWidget);
    expect(find.text('점이 있는 날에 리포트가 있어요.'), findsOneWidget);
  });

  testWidgets('리포트가 있는 날을 누르면 그 날짜를 준다', (tester) async {
    _usePhoneScreen(tester);
    DateTime? picked;
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              picked = await showReportCalendar(
                context,
                markedDays: {DateTime(2026, 9, 3)},
                focusedDay: focused,
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 9, 3));
  });

  testWidgets('점이 없는 날은 눌러도 닫히지 않는다', (tester) async {
    _usePhoneScreen(tester);
    await _open(tester, marked: {DateTime(2026, 9, 3)}, focused: focused);

    await tester.tap(find.text('11'));      // 리포트가 없는 날
    await tester.pumpAndSettle();
    expect(find.text('2026년 9월'), findsOneWidget, reason: '달력이 그대로 떠 있어야 한다');
  });

  testWidgets('이전 달로 넘어간다', (tester) async {
    _usePhoneScreen(tester);
    await _open(tester, marked: {}, focused: focused);

    await tester.tap(find.byTooltip('이전 달'));
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월'), findsOneWidget);
  });

  testWidgets('아직 오지 않은 달로는 넘어가지 않는다', (tester) async {
    _usePhoneScreen(tester);
    final now = DateTime.now();
    await _open(tester, marked: {}, focused: now);

    // 아이콘으로 찾는다. 툴팁으로 찾으면 안 된다 — 플러터는 눌리지 않는
    // 버튼에는 툴팁을 달지 않아서, 정작 확인하려는 상태에서 찾지 못한다.
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNull, reason: '앞으로는 리포트가 있을 수 없다');
  });
}
