// 인형 목소리는 등록한 사람 것이 아니라 그 인형 것이다.
// 가족 모두에게 보이므로, 목록에 누가 등록했는지가 드러나야 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/settings_api.dart';

DeviceVoice _voice({
  String name = '김지영',
  int? protectorId = 1,
  String? ownerName,
  String? ownerRelation,
  String status = 'ready',
}) => DeviceVoice.fromJson({
  'voiceId': 1,
  'name': name,
  'status': status,
  'progress': 100,
  'isDefault': false,
  'protectorId': protectorId,
  'ownerName': ownerName,
  'ownerRelation': ownerRelation,
});

void main() {
  test('관계와 이름을 함께 부른다', () {
    final v = _voice(ownerName: '김지영', ownerRelation: '딸');
    expect(v.ownerLabel, '딸 김지영');
  });

  test('관계를 모르면 이름만 부른다', () {
    expect(_voice(ownerName: '김지영', ownerRelation: null).ownerLabel, '김지영');
    expect(_voice(ownerName: '김지영', ownerRelation: '  ').ownerLabel, '김지영');
  });

  test('인형에 들어 있는 기본 목소리는 등록자가 없다', () {
    final v = _voice(name: '기본 목소리', protectorId: null);
    expect(v.isBuiltIn, isTrue);
    expect(v.ownerLabel, isEmpty);
  });

  test('등록자를 안 주는 예전 서버와도 맞물린다', () {
    final v = DeviceVoice.fromJson({
      'voiceId': 1,
      'name': '김지영',
      'status': 'ready',
      'progress': 100,
      'isDefault': false,
      'protectorId': 1,
    });
    expect(v.ownerName, isNull);
    expect(v.ownerLabel, isEmpty);
  });
}
