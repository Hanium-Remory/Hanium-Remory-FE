// ReMory 설정 API 클라이언트.
//
// 백엔드 응답은 모두 { status, message, data } 봉투로 감싸여 있고,
// 인증이 필요한 요청은 Authorization: Bearer <accessToken> 을 쓴다.
// access 토큰(기본 30분)이 만료되면 refresh 토큰으로 한 번 재발급 후 재시도한다.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart' show kBackendBaseUrl;
import 'session_store.dart';

// TODO: 설정 백엔드 연동이 준비되면 false로 변경한다.
const bool kUseMockSettingsForDevelopment = false;

/// 서버가 돌려준 message를 그대로 사용자에게 보여줄 수 있는 에러.
class ApiException implements Exception {
  ApiException(this.message, this.status);

  final String message;
  final int status;

  /// 세션이 끊겨 다시 로그인해야 하는 상태.
  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

class SettingsApi {
  SettingsApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? kBackendBaseUrl,
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  // ── 공통 요청 ──────────────────────────────────────
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool allowRetry = true,
  }) async {
    if (kUseMockSettingsForDevelopment) {
      return _mockSettingsResponse(method, path, body);
    }
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await SessionStore.accessToken();
      if (token == null || token.isEmpty) {
        throw ApiException('로그인이 필요합니다.', 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);

    // 만료된 access 토큰이면 한 번만 재발급 후 재시도.
    if (res.statusCode == 401 &&
        auth &&
        allowRetry &&
        await _refreshSession()) {
      return _send(method, path, body: body, auth: auth, allowRetry: false);
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        '서버 응답을 읽을 수 없습니다. (${res.statusCode})',
        res.statusCode,
      );
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        (decoded['message'] as String?) ?? '요청에 실패했어요. (${res.statusCode})',
        res.statusCode,
      );
    }
    return decoded['data'];
  }

  Future<Map<String, dynamic>> _get(String path, {bool auth = true}) async =>
      (await _send('GET', path, auth: auth)) as Map<String, dynamic>;

  Future<bool> _refreshSession() async {
    final refresh = await SessionStore.refreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _client.post(
        Uri.parse('$baseUrl/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode >= 400) return false;
      final data =
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      await SessionStore.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── 보호자 프로필 ──────────────────────────────────
  Future<MyProfile> myProfile() async {
    final profile = MyProfile.fromJson(await _get('/protectors/me'));
    final linkedUser = profile.mainUser;
    if (linkedUser != null) {
      final userData = await _get('/users/${linkedUser.userId}');
      final gender = ElderUser.fromJson(userData).gender;
      if (gender != null) await SessionStore.setElderGender(gender);
    }
    return profile;
  }

  Future<MyProfile> updateProfile({
    String? name,
    String? relation,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (relation != null) body['relation'] = relation;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;
    final d = await _send('PUT', '/protectors/me', body: body);
    return MyProfile.fromJson(d as Map<String, dynamic>);
  }

  /// 보낸 항목만 부분 수정된다. 키는 NotificationKeys 참고.
  Future<Map<String, bool>> updateNotificationSettings(
    Map<String, bool> changes,
  ) async {
    final d = await _send(
      'PATCH',
      '/protectors/me/notification-settings',
      body: changes,
    );
    return _boolMap(d as Map<String, dynamic>);
  }

  Future<void> withdraw() async => _send('DELETE', '/protectors/me');

  // ── 어르신 정보 ────────────────────────────────────
  Future<ElderUser> user(int userId) async =>
      ElderUser.fromJson(await _get('/users/$userId'));

  Future<ElderUser> updateUser(
    int userId, {
    String? name,
    String? gender,
    DateTime? birthDate,
    String? note,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (gender != null) body['gender'] = gender;
    if (birthDate != null) {
      body['birthDate'] =
          '${birthDate.year.toString().padLeft(4, '0')}-'
          '${birthDate.month.toString().padLeft(2, '0')}-'
          '${birthDate.day.toString().padLeft(2, '0')}';
    }
    if (note != null) body['note'] = note;
    final d = await _send('PUT', '/users/$userId', body: body);
    return ElderUser.fromJson(d as Map<String, dynamic>);
  }

  // ── 가족 멤버 ──────────────────────────────────────
  Future<FamilyMembers> familyMembers(int userId) async =>
      FamilyMembers.fromJson(await _get('/users/$userId/family-members'));

  Future<void> removeFamilyMember(int protectorId) async =>
      _send('DELETE', '/family-members/$protectorId');

  // ── 인형 설정 ──────────────────────────────────────
  Future<DeviceSettings> deviceSettings(int deviceId) async =>
      DeviceSettings.fromJson(await _get('/devices/$deviceId/settings'));

  Future<DeviceSettings> updateDeviceSettings(
    int deviceId, {
    String? name,
    int? volume,
    int? defaultVoiceId,
    bool? medicationCheck,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (volume != null) body['volume'] = volume;
    if (defaultVoiceId != null) body['defaultVoiceId'] = defaultVoiceId;
    if (medicationCheck != null) body['medicationCheck'] = medicationCheck;
    final d = await _send('PUT', '/devices/$deviceId/settings', body: body);
    return DeviceSettings.fromJson(d as Map<String, dynamic>);
  }

  Future<void> setDefaultVoice(int deviceId, int voiceId) async => _send(
    'PATCH',
    '/devices/$deviceId/settings/voice',
    body: {'voiceId': voiceId},
  );

  // ── 방해 금지 시간 ─────────────────────────────────
  Future<DndSettings> dnd(int deviceId) async =>
      DndSettings.fromJson(await _get('/devices/$deviceId/dnd'));

  Future<DndSettings> updateDnd(
    int deviceId, {
    bool? enabled,
    int? startHour,
    int? endHour,
    bool? allowUrgentAlert,
    bool? allowWakeWord,
  }) async {
    final body = <String, dynamic>{};
    if (enabled != null) body['enabled'] = enabled;
    if (startHour != null) body['startHour'] = startHour;
    if (endHour != null) body['endHour'] = endHour;
    if (allowUrgentAlert != null) body['allowUrgentAlert'] = allowUrgentAlert;
    if (allowWakeWord != null) body['allowWakeWord'] = allowWakeWord;
    final d = await _send('PUT', '/devices/$deviceId/dnd', body: body);
    return DndSettings.fromJson(d as Map<String, dynamic>);
  }

  // ── 약 복용 ────────────────────────────────────────
  Future<MedicationList> medications(int deviceId) async =>
      MedicationList.fromJson(await _get('/devices/$deviceId/medications'));

  Future<Medication> addMedication(
    int deviceId, {
    required String name,
    required String time, // "HH:MM"
    required String timing, // 식전 | 식후 | 공복 | 아무때나
  }) async {
    final d = await _send(
      'POST',
      '/devices/$deviceId/medications',
      body: {'name': name, 'time': time, 'timing': timing},
    );
    return Medication.fromJson(d as Map<String, dynamic>);
  }

  Future<Medication> updateMedication(
    int medicationId, {
    String? name,
    String? time,
    String? timing,
    bool? enabled,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (time != null) body['time'] = time;
    if (timing != null) body['timing'] = timing;
    if (enabled != null) body['enabled'] = enabled;
    final d = await _send('PUT', '/medications/$medicationId', body: body);
    return Medication.fromJson(d as Map<String, dynamic>);
  }

  Future<void> deleteMedication(int medicationId) async =>
      _send('DELETE', '/medications/$medicationId');

  // ── 서비스 정보 ────────────────────────────────────
  Future<ServiceInfo> serviceInfo() async =>
      ServiceInfo.fromJson(await _get('/service/info', auth: false));

  /// 개발용: 어르신·인형 샘플 데이터를 만든다(백엔드 DEBUG=true 일 때만).
  /// 첫 등록/초대 코드 플로우가 붙으면 지워도 된다.
  Future<void> seedDemoData() async => _send('POST', '/dev/seed');
}

dynamic _mockSettingsResponse(
  String method,
  String path,
  Map<String, dynamic>? body,
) {
  if (path == '/protectors/me') {
    return {
      'protectorId': 1,
      'name': body?['name'] ?? '김기억',
      'phoneNumber': '01012345678',
      'relation': body?['relation'] ?? '딸',
      'profileImageUrl': body?['profileImageUrl'],
      'users': [
        {'userId': 1, 'name': '박순자', 'deviceId': 1, 'isPrimary': true},
      ],
      'notificationSettings': {
        'urgent': true,
        'dailyReport': true,
        'chat': true,
        'marketing': false,
      },
    };
  }
  if (path == '/protectors/me/notification-settings') {
    return body ?? <String, bool>{};
  }
  if (RegExp(r'^/users/\d+$').hasMatch(path)) {
    return {
      'userId': 1,
      'name': body?['name'] ?? '박순자',
      'gender': body?['gender'] ?? 'female',
      'birthDate': body?['birthDate'] ?? '1957-06-20',
      'age': 69,
      'photoUrl': null,
      'note': body?['note'] ?? '따뜻한 대화를 좋아해요.',
      'deviceId': 1,
    };
  }
  if (path.endsWith('/family-members')) {
    return {
      'stats': {'familyCount': 2, 'voiceCount': 1, 'inviteCodeCount': 1},
      'members': [
        {
          'protectorId': 1,
          'name': '김기억',
          'relation': '딸',
          'isPrimary': true,
          'isMe': true,
        },
        {
          'protectorId': 2,
          'name': '김마음',
          'relation': '아들',
          'isPrimary': false,
          'isMe': false,
        },
      ],
    };
  }
  if (path.endsWith('/settings/voice')) return <String, dynamic>{};
  if (path.endsWith('/settings')) {
    return {
      'deviceId': 1,
      'name': body?['name'] ?? '모리',
      'connected': true,
      'batteryLevel': 82,
      'batteryHoursLeft': 18,
      'volume': body?['volume'] ?? 60,
      'medicationCheck': body?['medicationCheck'] ?? true,
      'defaultVoiceId': body?['defaultVoiceId'] ?? 1,
      'voices': [
        {
          'voiceId': 1,
          'name': '기억이 목소리',
          'status': 'ready',
          'progress': 100,
          'isDefault': true,
        },
      ],
      'pairedAt': '2026-07-01T00:00:00.000Z',
    };
  }
  if (path.endsWith('/dnd')) {
    return {
      'enabled': body?['enabled'] ?? true,
      'startHour': body?['startHour'] ?? 22,
      'endHour': body?['endHour'] ?? 7,
      'allowUrgentAlert': body?['allowUrgentAlert'] ?? true,
      'allowWakeWord': body?['allowWakeWord'] ?? false,
    };
  }
  if (path.endsWith('/medications')) {
    if (method == 'POST') {
      return {
        'medicationId': 2,
        'name': body?['name'] ?? '약',
        'time': body?['time'] ?? '08:00',
        'timing': body?['timing'] ?? '식후',
        'enabled': true,
      };
    }
    return {
      'medicationCheck': true,
      'medications': [
        {
          'medicationId': 1,
          'name': '혈압약',
          'time': '08:00',
          'timing': '식후',
          'enabled': true,
        },
      ],
    };
  }
  if (RegExp(r'^/medications/\d+$').hasMatch(path) && method == 'PUT') {
    return {
      'medicationId': 1,
      'name': body?['name'] ?? '혈압약',
      'time': body?['time'] ?? '08:00',
      'timing': body?['timing'] ?? '식후',
      'enabled': body?['enabled'] ?? true,
    };
  }
  if (path == '/service/info') {
    return {'appName': 'ReMory', 'version': '개발 미리보기'};
  }
  return <String, dynamic>{};
}

Map<String, bool> _boolMap(Map<String, dynamic> json) =>
    json.map((k, v) => MapEntry(k, v == true));

// ── 알림 설정 키 ─────────────────────────────────────
/// 화면 라벨 ↔ 백엔드 필드 이름 매핑.
class NotificationKeys {
  static const urgent = 'urgent';
  static const dailyReport = 'dailyReport';
  static const chat = 'chat';
  static const marketing = 'marketing';

  /// 알림 설정 화면(9개 항목)의 라벨 → 필드.
  static const byLabel = <String, String>{
    '감정 변화': 'emotionChange',
    '기기 연결 해제': 'deviceDisconnected',
    '약 미복용': 'medicationMissed',
    '어머님 음성 요청': 'voiceRequest',
    '메시지 전달 완료': 'messageDelivered',
    '목소리 학습 완료': 'voiceTrainingCompleted',
    '데일리 리포트': 'dailyReport',
    '주간 리포트': 'weeklyReport',
    '앱 업데이트': 'appUpdate',
  };
}

// ── 모델 ─────────────────────────────────────────────
class MyProfile {
  MyProfile({
    required this.protectorId,
    required this.name,
    required this.phoneNumber,
    required this.relation,
    required this.profileImageUrl,
    required this.users,
    required this.notifications,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) => MyProfile(
    protectorId: json['protectorId'] as int,
    name: json['name'] as String? ?? '보호자',
    phoneNumber: json['phoneNumber'] as String?,
    relation: json['relation'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
    users: (json['users'] as List? ?? [])
        .map((e) => LinkedUser.fromJson(e as Map<String, dynamic>))
        .toList(),
    notifications: _boolMap(
      json['notificationSettings'] as Map<String, dynamic>,
    ),
  );

  final int protectorId;
  final String name;
  final String? phoneNumber;
  final String? relation;
  final String? profileImageUrl;
  final List<LinkedUser> users;
  final Map<String, bool> notifications;

  /// 아직 어르신이 연결되지 않았으면 null.
  LinkedUser? get mainUser => users.isEmpty ? null : users.first;

  /// 010-1234-5678 형태로.
  String get formattedPhone {
    final digits = (phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return phoneNumber ?? '';
  }
}

class LinkedUser {
  LinkedUser({
    required this.userId,
    required this.name,
    required this.deviceId,
    required this.isPrimary,
  });

  factory LinkedUser.fromJson(Map<String, dynamic> json) => LinkedUser(
    userId: json['userId'] as int,
    name: json['name'] as String,
    deviceId: json['deviceId'] as int?,
    isPrimary: json['isPrimary'] == true,
  );

  final int userId;
  final String name;
  final int? deviceId;
  final bool isPrimary;
}

class ElderUser {
  ElderUser({
    required this.userId,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.age,
    required this.photoUrl,
    required this.note,
    required this.deviceId,
  });

  factory ElderUser.fromJson(Map<String, dynamic> json) => ElderUser(
    userId: json['userId'] as int,
    name: json['name'] as String,
    gender: json['gender'] as String?,
    birthDate: json['birthDate'] == null
        ? null
        : DateTime.parse(json['birthDate'] as String),
    age: json['age'] as int?,
    photoUrl: json['photoUrl'] as String?,
    note: json['note'] as String? ?? '',
    deviceId: json['deviceId'] as int?,
  );

  final int userId;
  final String name;
  final String? gender; // female | male
  final DateTime? birthDate;
  final int? age;
  final String? photoUrl;
  final String note;
  final int? deviceId;

  String get genderText => switch (gender) {
    'female' => '여성',
    'male' => '남성',
    _ => '미입력',
  };

  String get birthText => birthDate == null
      ? '미입력'
      : '${birthDate!.year}년 ${birthDate!.month}월 ${birthDate!.day}일';
}

class FamilyMembers {
  FamilyMembers({
    required this.familyCount,
    required this.voiceCount,
    required this.inviteCodeCount,
    required this.members,
  });

  factory FamilyMembers.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return FamilyMembers(
      familyCount: stats['familyCount'] as int,
      voiceCount: stats['voiceCount'] as int,
      inviteCodeCount: stats['inviteCodeCount'] as int,
      members: (json['members'] as List)
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int familyCount;
  final int voiceCount;
  final int inviteCodeCount;
  final List<FamilyMember> members;

  /// 내가 주보호자면 가족을 제거할 수 있다.
  bool get iAmPrimary => members.any((m) => m.isMe && m.isPrimary);
}

class FamilyMember {
  FamilyMember({
    required this.protectorId,
    required this.name,
    required this.relation,
    required this.isPrimary,
    required this.isMe,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    protectorId: json['protectorId'] as int,
    name: json['name'] as String,
    relation: json['relation'] as String?,
    isPrimary: json['isPrimary'] == true,
    isMe: json['isMe'] == true,
  );

  final int protectorId;
  final String name;
  final String? relation;
  final bool isPrimary;
  final bool isMe;

  List<String> get badges => [if (isMe) '나', if (isPrimary) '주보호자'];
}

class DeviceSettings {
  DeviceSettings({
    required this.deviceId,
    required this.name,
    required this.connected,
    required this.batteryLevel,
    required this.batteryHoursLeft,
    required this.volume,
    required this.medicationCheck,
    required this.defaultVoiceId,
    required this.voices,
    required this.pairedAt,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => DeviceSettings(
    deviceId: json['deviceId'] as int,
    name: json['name'] as String,
    connected: json['connected'] == true,
    batteryLevel: json['batteryLevel'] as int,
    batteryHoursLeft: json['batteryHoursLeft'] as int,
    volume: json['volume'] as int,
    medicationCheck: json['medicationCheck'] == true,
    defaultVoiceId: json['defaultVoiceId'] as int?,
    voices: (json['voices'] as List)
        .map((e) => DeviceVoice.fromJson(e as Map<String, dynamic>))
        .toList(),
    pairedAt: json['pairedAt'] == null
        ? null
        : DateTime.parse(json['pairedAt'] as String),
  );

  final int deviceId;
  final String name;
  final bool connected;
  final int batteryLevel;
  final int batteryHoursLeft;
  final int volume;
  final bool medicationCheck;
  final int? defaultVoiceId;
  final List<DeviceVoice> voices;
  final DateTime? pairedAt;

  String get volumeText => switch (volume) {
    <= 40 => '작게',
    <= 65 => '보통',
    <= 85 => '크게',
    _ => '아주 크게',
  };
}

class DeviceVoice {
  DeviceVoice({
    required this.voiceId,
    required this.name,
    required this.status,
    required this.progress,
    required this.isDefault,
  });

  factory DeviceVoice.fromJson(Map<String, dynamic> json) => DeviceVoice(
    voiceId: json['voiceId'] as int,
    name: json['name'] as String,
    status: json['status'] as String,
    progress: json['progress'] as int? ?? 0,
    isDefault: json['isDefault'] == true,
  );

  final int voiceId;
  final String name;
  final String status; // ready | training | failed
  final int progress;
  final bool isDefault;

  bool get isTraining => status == 'training';
  bool get isReady => status == 'ready';

  String get statusText => switch (status) {
    'ready' => '등록 완료',
    'training' => '학습 중...',
    _ => '학습 실패',
  };
}

class DndSettings {
  DndSettings({
    required this.enabled,
    required this.startHour,
    required this.endHour,
    required this.allowUrgentAlert,
    required this.allowWakeWord,
  });

  factory DndSettings.fromJson(Map<String, dynamic> json) => DndSettings(
    enabled: json['enabled'] == true,
    startHour: json['startHour'] as int,
    endHour: json['endHour'] as int,
    allowUrgentAlert: json['allowUrgentAlert'] == true,
    allowWakeWord: json['allowWakeWord'] == true,
  );

  final bool enabled;
  final int startHour;
  final int endHour;
  final bool allowUrgentAlert;
  final bool allowWakeWord;
}

class MedicationList {
  MedicationList({required this.medicationCheck, required this.items});

  factory MedicationList.fromJson(Map<String, dynamic> json) => MedicationList(
    medicationCheck: json['medicationCheck'] == true,
    items: (json['medications'] as List)
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final bool medicationCheck;
  final List<Medication> items;
}

class Medication {
  Medication({
    required this.medicationId,
    required this.name,
    required this.time,
    required this.timing,
    required this.enabled,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    medicationId: json['medicationId'] as int,
    name: json['name'] as String,
    time: json['time'] as String,
    timing: json['timing'] as String,
    enabled: json['enabled'] == true,
  );

  final int medicationId;
  final String name;
  final String time; // "08:00"
  final String timing;
  final bool enabled;
}

class ServiceInfo {
  ServiceInfo({required this.appName, required this.version});

  factory ServiceInfo.fromJson(Map<String, dynamic> json) => ServiceInfo(
    appName: json['appName'] as String? ?? 'ReMory',
    version: json['version'] as String? ?? '-',
  );

  final String appName;
  final String version;
}
