// 주간 리포트의 요일별 감정과 자주 나눈 키워드.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/settings_api.dart';

WeeklyReportData _parse(Map<String, dynamic> extra) =>
    WeeklyReportData.fromJson({
      'reportId': 1,
      'weekStart': '2026-08-31',
      'totalConversationCount': 11,
      'familyInteractionCount': 3,
      'emergencyAlertCount': 0,
      'weeklySummary': '머리말',
      ...extra,
    });

void main() {
  test('키워드를 잦은 순서로 읽는다', () {
    final report = _parse({
      'keywords': [
        {'word': '손주', 'count': 12},
        {'word': '식사', 'count': 9},
      ],
    });
    expect(report.keywords.map((k) => k.word), ['손주', '식사']);
    expect(report.keywords.first.count, 12);
  });

  test('요일별 감정은 일곱 칸으로 온다', () {
    final report = _parse({
      'dailyEmotions': [
        for (final d in ['월', '화', '수', '목', '금', '토', '일'])
          {'weekday': d, 'emotion': d == '일' ? null : 'calm', 'score': d == '일' ? null : 65},
      ],
    });
    expect(report.dailyEmotions, hasLength(7));
    expect(report.dailyEmotions.map((d) => d.weekday).toList(),
        ['월', '화', '수', '목', '금', '토', '일']);
  });

  test('기록이 없는 날은 비어 있다', () {
    final report = _parse({
      'dailyEmotions': [
        {'weekday': '월', 'emotion': null, 'score': null},
      ],
    });
    final day = report.dailyEmotions.single;
    expect(day.emotion, isNull);
    expect(day.score, isNull);
  });

  test('두 칸을 안 주는 예전 서버와도 맞물린다', () {
    final report = _parse({});
    expect(report.keywords, isEmpty);
    expect(report.dailyEmotions, isEmpty);
    expect(report.weekStory, isNull);
  });
}
