import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/7.%20report/daily_report_screen.dart';
import 'package:flutter_application_1/services/settings_api.dart';

DateTime _d(int m, int day) => DateTime(2026, m, day);

void main() {
  // 리포트가 매일 있는 것은 아니다. 9/2 와 9/6 사이는 비어 있다.
  final days = {_d(9, 1), _d(9, 2), _d(9, 6), _d(9, 7)};

  test('빈 날은 건너뛰고 리포트가 있는 날로 간다', () {
    expect(neighbourReportDay(days, _d(9, 6), older: true), _d(9, 2));
    expect(neighbourReportDay(days, _d(9, 2), older: false), _d(9, 6));
  });

  test('가장 예전 날에서는 왼쪽이 막힌다', () {
    expect(neighbourReportDay(days, _d(9, 1), older: true), isNull);
    expect(neighbourReportDay(days, _d(9, 1), older: false), _d(9, 2));
  });

  test('가장 최근 날에서는 오른쪽이 막힌다', () {
    expect(neighbourReportDay(days, _d(9, 7), older: false), isNull);
    expect(neighbourReportDay(days, _d(9, 7), older: true), _d(9, 6));
  });

  test('달력으로 가운데 날로 건너뛰어도 양쪽이 다 열린다', () {
    // 이게 원래 어긋났던 자리다. offset 을 알 수 없다는 이유로 오른쪽이
    // 막혔는데, 뒤에 9/6·9/7 이 멀쩡히 있다.
    expect(neighbourReportDay(days, _d(9, 2), older: false), isNotNull);
    expect(neighbourReportDay(days, _d(9, 2), older: true), isNotNull);
  });

  test('시각이 섞여 있어도 날짜만 본다', () {
    final withTime = {DateTime(2026, 9, 1, 23, 40), DateTime(2026, 9, 6, 8, 5)};
    expect(
      neighbourReportDay(withTime, DateTime(2026, 9, 6, 21, 0), older: true),
      _d(9, 1),
    );
  });

  test('날짜를 모르는 예전 리포트에서는 어느 쪽도 못 짚는다', () {
    expect(neighbourReportDay(days, null, older: true), isNull);
    expect(neighbourReportDay(days, null, older: false), isNull);
  });

  group('요일별 감정 그래프', () {
    test('점수를 그대로 높이로 쓴다', () {
      expect(weekMoodValueOf(DayEmotion(weekday: '월', score: 80)), 0.8);
      expect(weekMoodValueOf(DayEmotion(weekday: '화', score: 0)), 0.0);
    });

    test('점수가 없으면 감정 종류의 높이로 물러난다', () {
      final v = weekMoodValueOf(DayEmotion(weekday: '수', emotion: 'happy'));
      expect(v, isNotNull);
      expect(v, inInclusiveRange(0.0, 1.0));
    });

    test('기록이 없는 날은 null 이라 선이 끊긴다', () {
      // 0 으로 떨어뜨리면 그날 기분이 바닥이었던 것처럼 읽힌다.
      expect(weekMoodValueOf(DayEmotion(weekday: '목')), isNull);
    });
  });
}
