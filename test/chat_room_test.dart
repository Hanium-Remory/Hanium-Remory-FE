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
}
