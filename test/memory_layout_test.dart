// 기억 추가 화면의 배치.
// 두 화면(새 기억·새 추억)은 칩으로 오가는 짝이라, 헤더와 그 아래 여백이
// 어긋나면 '추가하고 싶은 부분을 선택해주세요' 가 전환할 때마다 흔들린다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/5.%20memory/memory_add_flow.dart';

/// 테스트 창은 기본이 800x600 가로형이라 세로 화면이 넘친다. 실제 폰 비율로 맞춘다.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// 칩 줄 안의 글자만 짚는다. 아래 설명도 같은 낱말을 쓰기 때문이다.
Finder _chip(String label) => find.descendant(
  of: find.byKey(memoryTypeChipsKey),
  matching: find.text(label),
);

Widget _wrap(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(home: child),
);

void main() {
  testWidgets('두 화면 모두 제목이 "기억 추가" 로 고정된다', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_wrap(MemoryTypeScreen(
      onOpenMemoryForm: () {}, onSave: () {})));
    await tester.pumpAndSettle();
    expect(find.text('기억 추가'), findsOneWidget);
    expect(_chip('새 기억'), findsOneWidget);
    expect(_chip('새 추억'), findsOneWidget);

    await tester.pumpWidget(_wrap(MemoryAddScreen(
      onSave: ({required photo, required filename, required title,
                required period, required description}) async {},
      onSelectNewMemory: () {})));
    await tester.pumpAndSettle();
    expect(find.text('기억 추가'), findsOneWidget);
  });

  testWidgets('안내 문구가 두 화면에서 같은 자리에 있다', (tester) async {
    _usePhoneScreen(tester);
    const label = '추가하고 싶은 부분을 선택해주세요';

    await tester.pumpWidget(_wrap(MemoryTypeScreen(
      onOpenMemoryForm: () {}, onSave: () {})));
    await tester.pumpAndSettle();
    final onType = tester.getTopLeft(find.text(label));

    await tester.pumpWidget(_wrap(MemoryAddScreen(
      onSave: ({required photo, required filename, required title,
                required period, required description}) async {},
      onSelectNewMemory: () {})));
    await tester.pumpAndSettle();
    final onAdd = tester.getTopLeft(find.text(label));

    expect(onAdd, onType, reason: '두 화면 사이를 오갈 때 문구가 흔들리면 안 된다');
  });

  testWidgets('새 추억 칩이 새 기억보다 앞에 있다', (tester) async {
    _usePhoneScreen(tester);

    Future<void> check(Widget screen) async {
      await tester.pumpWidget(_wrap(screen));
      await tester.pumpAndSettle();
      final memo = tester.getTopLeft(_chip('새 추억')).dx;
      final note = tester.getTopLeft(_chip('새 기억')).dx;
      expect(memo, lessThan(note), reason: '새 추억이 왼쪽이어야 한다');
    }

    await check(MemoryTypeScreen(onOpenMemoryForm: () {}, onSave: () {}));
    await check(MemoryAddScreen(
      onSave: ({required photo, required filename, required title,
                required period, required description}) async {},
      onSelectNewMemory: () {}));
  });

  testWidgets('두 화면 모두 무엇이 다른지 설명을 보여준다', (tester) async {
    _usePhoneScreen(tester);

    for (final screen in [
      MemoryTypeScreen(onOpenMemoryForm: () {}, onSave: () {}),
      MemoryAddScreen(
        onSave: ({required photo, required filename, required title,
                  required period, required description}) async {},
        onSelectNewMemory: () {}),
    ]) {
      await tester.pumpWidget(_wrap(screen));
      await tester.pumpAndSettle();
      expect(find.textContaining('가족과 함께한 지난 일'), findsOneWidget);
      expect(find.textContaining('알아두면 좋을 것들'), findsOneWidget);
    }
  });

  testWidgets("'언제 기억인가요' 칩 넷이 한 줄에 선다", (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_wrap(MemoryAddScreen(
      onSave: ({required photo, required filename, required title,
                required period, required description}) async {},
      onSelectNewMemory: () {})));
    await tester.pumpAndSettle();

    const options = ['오늘', '최근', '몇 년 전', '오래된 기억'];

    // 글자가 아니라 칩(테두리 상자)을 잰다. 긴 말은 FittedBox 가 줄여서 넣으므로
    // 글자 좌표는 칩마다 조금씩 다르다 — 줄이 나뉘었다는 뜻이 아니다.
    Rect chipOf(String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
    );

    for (final o in options) {
      expect(find.text(o), findsOneWidget, reason: '$o 칩이 보여야 한다');
    }
    final rects = [for (final o in options) chipOf(o)];

    expect(rects.map((r) => r.top).toSet().length, 1,
        reason: '넷의 윗변이 같아야 한 줄이다');

    // 왼쪽에서 오른쪽으로, 겹치지 않게 차례대로
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right),
          reason: '${options[i]} 가 ${options[i - 1]} 뒤에 놓여야 한다');
    }

    // 화면 밖으로 밀려나지 않는다
    final screen = tester.getSize(find.byType(Scaffold)).width;
    expect(rects.last.right, lessThanOrEqualTo(screen),
        reason: '마지막 칩이 화면 안에 들어와야 한다');
  });
}
