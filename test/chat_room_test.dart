// 대화방의 '여기까지 읽어드렸어요' 금과 읽음 수.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/settings_api.dart';

ChatMessage _msg(int id, {bool delivered = false, int readCount = 0}) =>
    ChatMessage.fromJson({
      'messageId': id,
      'senderType': 'protector',
      'senderId': 1,
      'content': '$id번째',
      'deliveredToDevice': delivered,
      'readCount': readCount,
      'createdAt': '2026-09-06T09:00:00+00:00',
    });

/// 화면이 금을 놓는 자리를 고르는 방식과 같다(family_chat_screen.dart).
int _dividerAfter(List<ChatMessage> messages) {
  final last = messages.lastIndexWhere((m) => m.deliveredToDevice);
  return (last >= 0 && last < messages.length - 1) ? last : -1;
}

/// 화면이 날짜 금에 쓰는 말과 같다(family_chat_screen.dart 의 _formatDay).
String _formatDay(DateTime day, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final gap = today.difference(day).inDays;
  if (gap == 0) return '오늘';
  if (gap == 1) return '어제';
  const names = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = names[day.weekday - 1];
  final year = day.year == today.year ? '' : '${day.year}년 ';
  return '$year${day.month}월 ${day.day}일 $weekday요일';
}

/// 날짜가 바뀌는 자리를 찾는다. 화면이 금을 끼는 기준과 같다.
List<int> _dayBreaks(List<DateTime?> times) {
  final breaks = <int>[];
  DateTime? shown;
  for (var i = 0; i < times.length; i++) {
    final at = times[i];
    if (at == null) continue;
    final day = DateTime(at.year, at.month, at.day);
    if (shown == null || day != shown) {
      breaks.add(i);
      shown = day;
    }
  }
  return breaks;
}

void main() {
  test('전달 여부와 읽음 수를 읽는다', () {
    final m = _msg(1, delivered: true, readCount: 2);
    expect(m.deliveredToDevice, isTrue);
    expect(m.readCount, 2);
  });

  test('필드를 안 주는 예전 서버와도 맞물린다', () {
    final m = ChatMessage.fromJson({
      'messageId': 1,
      'senderType': 'protector',
      'content': '안녕',
    });
    expect(m.deliveredToDevice, isFalse);
    expect(m.readCount, 0);
  });

  test('금은 마지막으로 읽어드린 글 바로 뒤에 놓인다', () {
    final messages = [
      _msg(1, delivered: true),
      _msg(2, delivered: true),
      _msg(3),
    ];
    expect(_dividerAfter(messages), 1);
  });

  test('다 읽어드렸으면 금을 긋지 않는다', () {
    final messages = [_msg(1, delivered: true), _msg(2, delivered: true)];
    expect(_dividerAfter(messages), -1, reason: '맨 아래 금은 뜻이 없다');
  });

  test('하나도 못 읽어드렸으면 금을 긋지 않는다', () {
    expect(_dividerAfter([_msg(1), _msg(2)]), -1,
        reason: '맨 위에 걸리면 무엇을 가르는 선인지 알 수 없다');
  });

  test('메시지가 없어도 터지지 않는다', () {
    expect(_dividerAfter([]), -1);
  });

  // ── 날짜 금 ──
  group('날짜 금', () {
    final now = DateTime(2026, 9, 7, 15);

    test('오늘과 어제는 날짜 대신 그렇게 부른다', () {
      expect(_formatDay(DateTime(2026, 9, 7), now: now), '오늘');
      expect(_formatDay(DateTime(2026, 9, 6), now: now), '어제');
    });

    test('그보다 오래되면 날짜와 요일을 쓴다', () {
      expect(_formatDay(DateTime(2026, 9, 2), now: now), '9월 2일 수요일');
    });

    test('해가 다르면 연도까지 붙인다', () {
      expect(_formatDay(DateTime(2025, 12, 31), now: now), '2025년 12월 31일 수요일');
    });

    test('날짜가 바뀌는 첫 메시지 앞에만 금을 긋는다', () {
      final times = [
        DateTime(2026, 9, 5, 9),
        DateTime(2026, 9, 5, 18),      // 같은 날 — 금 없음
        DateTime(2026, 9, 6, 10),      // 날이 바뀜
        DateTime(2026, 9, 6, 11),
      ];
      expect(_dayBreaks(times), [0, 2]);
    });

    test('첫 메시지 앞에는 늘 금이 있다', () {
      expect(_dayBreaks([DateTime(2026, 9, 5, 9)]), [0]);
    });

    test('시각을 모르는 메시지는 건너뛴다', () {
      expect(_dayBreaks([null, DateTime(2026, 9, 5, 9)]), [1]);
    });

    test('메시지가 없으면 금도 없다', () {
      expect(_dayBreaks([]), isEmpty);
    });
  });
}
