// 리포트의 '오늘 나눈 이야기'.
// 발화 원문은 앱에 내려오지 않는다. 리포트를 만들 때 서버가 골라 둔 몇 대목만
// 실린다(daily_reports.excerpt).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/settings_api.dart';

DailyReportData _parse(Object? excerpt) => DailyReportData.fromJson({
  'reportId': 1,
  'reportDate': '2026-09-06',
  'conversationCount': 6,
  'familyInteractionCount': 0,
  'summary': '요약',
  'excerpt': excerpt,
});

void main() {
  test('발췌를 대화 대목으로 읽는다', () {
    final report = _parse(jsonDecode('''
      [{"at": "2026-09-06T08:23:00+00:00",
        "user": "오늘 아침에 무릎이 시큰거려서 병원에 다녀왔어",
        "mori": "다행이에요. 무리하지 마세요."}]
    '''));

    expect(report.excerpt, hasLength(1));
    final turn = report.excerpt.single;
    expect(turn.user, '오늘 아침에 무릎이 시큰거려서 병원에 다녀왔어');
    expect(turn.mori, '다행이에요. 무리하지 마세요.');
    expect(turn.at, isNotNull);
  });

  test('여러 대목을 순서대로 읽는다', () {
    final report = _parse([
      {'at': '2026-09-06T08:00:00+00:00', 'user': '첫 번째', 'mori': '네.'},
      {'at': '2026-09-06T12:00:00+00:00', 'user': '두 번째', 'mori': '네.'},
    ]);
    expect(report.excerpt.map((t) => t.user), ['첫 번째', '두 번째']);
  });

  test('모리가 답하기 전에 끊긴 대목도 읽는다', () {
    final report = _parse([
      {'at': '2026-09-06T08:00:00+00:00', 'user': '오늘은 좀 쓸쓸하네'},
    ]);
    expect(report.excerpt.single.mori, '');
  });

  test('발췌가 없는 날은 빈 채로 둔다', () {
    expect(_parse(null).excerpt, isEmpty);
    expect(_parse([]).excerpt, isEmpty);
  });

  test('excerpt 를 아예 안 주는 예전 서버와도 맞물린다', () {
    final report = DailyReportData.fromJson({
      'reportId': 1,
      'conversationCount': 0,
      'familyInteractionCount': 0,
    });
    expect(report.excerpt, isEmpty);
  });
}
