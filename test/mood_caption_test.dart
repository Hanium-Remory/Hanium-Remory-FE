// 감정 그래프 아래 한 줄이 그 날 기록대로 나오는지.
// 예전에는 '오후 5시 손녀와의 대화 후 가장 좋아지셨어요.' 가 대화 0번인 날에도
// 그대로 떴다. 그래서 대화가 없던 날을 제일 먼저 확인한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/7.%20report/daily_report_screen.dart';
import 'package:flutter_application_1/services/settings_api.dart';

EmotionPoint at(int hour, String emotion) => EmotionPoint(
  emotionId: hour,
  emotion: emotion,
  createdAt: DateTime(2026, 9, 5, hour),
);

void main() {
  test('감정 기록이 없으면 한 줄 자체가 없다', () {
    expect(moodCaptionOf(3, []), isNull);
  });

  test('대화가 없던 날은 대화로 설명하지 않는다', () {
    final caption = moodCaptionOf(0, [at(9, 'calm'), at(17, 'happy')]);
    expect(caption, '이 날은 인형과 이야기를 나누지 않으셨어요. 표정으로 읽은 감정만 담겼어요.');
  });

  test('가장 좋았던 때를 시각으로 짚는다', () {
    final caption = moodCaptionOf(4, [
      at(9, 'sad'),
      at(13, 'calm'),
      at(17, 'happy'),
      at(20, 'calm'),
    ]);
    expect(caption, '오후 5시 무렵 기분이 가장 좋으셨어요.');
  });

  test('오전도 12시간제로 읽는다', () {
    final caption = moodCaptionOf(2, [at(8, 'happy'), at(14, 'sad')]);
    expect(caption, '오전 8시 무렵 기분이 가장 좋으셨어요.');
  });

  test('자정은 12시로 읽는다', () {
    final caption = moodCaptionOf(2, [at(0, 'happy'), at(14, 'sad')]);
    expect(caption, '오전 12시 무렵 기분이 가장 좋으셨어요.');
  });

  test('하루 종일 같은 감정이면 가장 좋았던 때를 짚지 않는다', () {
    final caption = moodCaptionOf(5, [
      at(9, 'calm'),
      at(13, 'calm'),
      at(18, 'calm'),
    ]);
    expect(caption, '하루 종일 비슷한 상태로 지내셨어요.');
  });

  test('앱이 모르는 감정 코드끼리도 평평한 것으로 본다', () {
    // 서버가 새 코드를 보내면 높이가 다 같은 기본값이 된다. 그때
    // 아무 지점이나 '가장 좋았던 때' 로 짚으면 거짓말이 된다.
    final caption = moodCaptionOf(5, [at(9, 'excited'), at(18, 'bored')]);
    expect(caption, '하루 종일 비슷한 상태로 지내셨어요.');
  });
}
