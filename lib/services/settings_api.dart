// ReMory 설정 API 클라이언트.
//
// 백엔드 응답은 모두 { status, message, data } 봉투로 감싸여 있고,
// 인증이 필요한 요청은 Authorization: Bearer <accessToken> 을 쓴다.
// access 토큰(기본 30분)이 만료되면 refresh 토큰으로 한 번 재발급 후 재시도한다.

import 'dart:convert';
import 'dart:typed_data';

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
  /// 인형(모리)을 어르신에게 연결한다. 이걸 하기 전에는 deviceId 가 없어서
  /// 인형 설정·방해 금지·약 복용 화면을 아예 열 수 없다.
  Future<PairedDevice> pairDevice(
    int userId, {
    String? name,
    String? serial,
  }) async {
    final d = await _send(
      'POST',
      '/devices',
      body: {
        'userId': userId,
        'name': ?name,
        'serial': ?serial,
      },
    );
    return PairedDevice.fromJson(d as Map<String, dynamic>);
  }

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

  // ── 목소리 등록(보이스 클로닝) ─────────────────────
  /// 녹음 파일을 올려 목소리 학습을 시작한다.
  /// 반환된 voiceId 로 [voiceStatus] 를 폴링해 ready/failed 를 확인한다.
  Future<DeviceVoice> registerVoice(
    int deviceId, {
    required String name,
    required String filePath,
  }) async {
    final d = await _sendMultipart(
      '/devices/$deviceId/voices',
      field: 'file',
      filePath: filePath,
      fields: {'name': name},
    );
    return DeviceVoice.fromJson(d as Map<String, dynamic>);
  }

  /// 웹과 모바일에서 녹음 스트림 바이트를 바로 업로드한다.
  Future<DeviceVoice> registerVoiceBytes(
    int deviceId, {
    required String name,
    required Uint8List bytes,
  }) async {
    final d = await _sendMultipartBytes(
      '/devices/$deviceId/voices',
      field: 'file',
      bytes: bytes,
      filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.wav',
      fields: {'name': name},
    );
    return DeviceVoice.fromJson(d as Map<String, dynamic>);
  }

  /// 목소리 학습 상태 조회(폴링용). training → ready | failed.
  Future<VoiceStatus> voiceStatus(int voiceId) async =>
      VoiceStatus.fromJson(await _get('/voices/$voiceId/status'));

  /// multipart 파일 업로드용 전송. JSON 전용인 [_send] 와 달리 파일을 실어 보낸다.
  /// access 토큰 만료(401)면 한 번 재발급 후 재시도한다(요청을 새로 만들어 파일을 다시 읽음).
  // ── 이미지 업로드 ──────────────────────────────────
  /// 사진 1장 업로드 → 서버가 돌려주는 URL.
  ///
  /// userId 를 주면 그 어르신 폴더에 저장된다. 프로필 사진처럼 주인이 되는
  /// 어르신이 없을 때만 생략한다. 파일 이름은 서버가 확장자로 이미지 종류를
  /// 가리므로 고르면서 받은 원본 이름을 그대로 넘긴다.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    int? userId,
  }) async {
    final d = await _sendMultipartBytes(
      '/files/images',
      field: 'file',
      bytes: bytes,
      filename: filename,
      fields: userId == null ? null : {'userId': '$userId'},
    );
    return (d as Map<String, dynamic>)['imageUrl'] as String;
  }

  // ── 추억 ───────────────────────────────────────────
  /// 추억 등록. imageUrl 은 uploadImage 가 돌려준 값을 그대로 넣는다.
  Future<void> createMemory({
    required int userId,
    required String imageUrl,
    required String title,
    String? period,
    String? description,
  }) async {
    await _send(
      'POST',
      '/users/$userId/memories',
      body: {
        'imageUrl': imageUrl,
        'title': title,
        if (period != null && period.isNotEmpty) 'period': period,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
  }

  // ── 가족 대화방 ────────────────────────────────────
  /// 대화 목록. 서버는 최신순으로 주므로 화면 순서에 맞게 뒤집어 준다.
  /// 조회하면 서버가 안 읽은 메시지를 읽음 처리한다.
  Future<List<ChatMessage>> chatMessages(int userId, {int size = 30}) async {
    final d = await _send('GET', '/users/$userId/chat/messages?size=$size');
    return (d as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  /// 메시지 전송. 내용과 사진 중 하나는 있어야 한다(서버도 같은 조건).
  Future<ChatMessage> sendChatMessage(
    int userId, {
    String? content,
    String? imageUrl,
  }) async {
    final d = await _send(
      'POST',
      '/users/$userId/chat/messages',
      body: {
        if (content != null && content.isNotEmpty) 'content': content,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
    );
    return ChatMessage.fromJson(d as Map<String, dynamic>);
  }

  // ── 홈 대시보드 ────────────────────────────────────
  /// 홈에 필요한 값(연결 상태·감정·활동·안 읽은 수)을 한 번에 받아온다.
  Future<HomeSummary> home(int userId) async =>
      HomeSummary.fromJson(await _get('/home?userId=$userId'));

  // ── 알림 ───────────────────────────────────────────
  /// 내 알림 목록(최신순, 삭제한 것 제외).
  Future<List<AppNotification>> notifications() async {
    final d = await _send('GET', '/notifications');
    return (d as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int notificationId) async =>
      _send('PATCH', '/notifications/$notificationId/read');

  // ── 리포트 ─────────────────────────────────────────
  /// 데일리 리포트. [offset] 0 이 가장 최근, 1 이 그 전날치다.
  /// 더 이전 것이 없으면 null 이다(앱은 이걸로 < 버튼 끝을 안다).
  Future<DailyReportData?> dailyReport(int userId, {int offset = 0}) async {
    final d = await _send('GET', '/users/$userId/reports/daily?offset=$offset');
    if (d == null) return null;
    return DailyReportData.fromJson(d as Map<String, dynamic>);
  }

  /// 주간 리포트. [offset] 0 이 가장 최근, 1 이 그 전주치다.
  Future<WeeklyReportData?> weeklyReport(int userId, {int offset = 0}) async {
    final d = await _send(
      'GET',
      '/users/$userId/reports/weekly?offset=$offset',
    );
    if (d == null) return null;
    return WeeklyReportData.fromJson(d as Map<String, dynamic>);
  }

  // ── 어르신 등록 ────────────────────────────────────
  /// 어르신을 만들고 나를 주보호자로 연결한다.
  /// 이미 연결된 어르신이 있으면 서버가 400 으로 막는다.
  Future<ElderUser> createUser({
    required String name,
    String? gender,
    DateTime? birthDate,
  }) async {
    final d = await _send(
      'POST',
      '/users',
      body: {
        'name': name,
        'gender': ?gender,
        if (birthDate != null)
          'birthDate':
              '${birthDate.year.toString().padLeft(4, '0')}-'
              '${birthDate.month.toString().padLeft(2, '0')}-'
              '${birthDate.day.toString().padLeft(2, '0')}',
      },
    );
    return ElderUser.fromJson(d as Map<String, dynamic>);
  }

  // ── 가족 초대 코드 ─────────────────────────────────
  /// 가족에게 알려줄 6자리 코드를 만든다.
  Future<InviteCodeData> createInviteCode(int userId) async {
    final d = await _send('POST', '/users/$userId/invite-codes');
    return InviteCodeData.fromJson(d as Map<String, dynamic>);
  }

  /// 받은 코드로 가족에 합류한다. 코드는 한 번만 쓸 수 있다.
  Future<LinkedFamily> acceptInviteCode(String code) async {
    final d = await _send('POST', '/invite-codes/$code/accept');
    return LinkedFamily.fromJson(d as Map<String, dynamic>);
  }

  Future<dynamic> _sendMultipart(
    String path, {
    required String field,
    required String filePath,
    Map<String, String>? fields,
    bool allowRetry = true,
  }) async {
    final token = await SessionStore.accessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('로그인이 필요합니다.', 401);
    }

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(field, filePath));

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 401 && allowRetry && await _refreshSession()) {
      return _sendMultipart(
        path,
        field: field,
        filePath: filePath,
        fields: fields,
        allowRetry: false,
      );
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

  Future<dynamic> _sendMultipartBytes(
    String path, {
    required String field,
    required Uint8List bytes,
    required String filename,
    Map<String, String>? fields,
    bool allowRetry = true,
  }) async {
    final token = await SessionStore.accessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('로그인이 필요합니다.', 401);
    }

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401 && allowRetry && await _refreshSession()) {
      return _sendMultipartBytes(
        path,
        field: field,
        bytes: bytes,
        filename: filename,
        fields: fields,
        allowRetry: false,
      );
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

/// 발급한 초대 코드.
class InviteCodeData {
  InviteCodeData({
    required this.inviteCode,
    required this.userId,
    this.expiresAt,
  });

  factory InviteCodeData.fromJson(Map<String, dynamic> json) => InviteCodeData(
    inviteCode: json['inviteCode'] as String,
    userId: json['userId'] as int,
    expiresAt: DateTime.tryParse(
      (json['expiresAt'] as String?) ?? '',
    )?.toLocal(),
  );

  final String inviteCode;
  final int userId;
  final DateTime? expiresAt;
}

/// 초대 코드를 받아들인 결과.
class LinkedFamily {
  LinkedFamily({
    required this.userId,
    required this.name,
    required this.isPrimary,
  });

  factory LinkedFamily.fromJson(Map<String, dynamic> json) => LinkedFamily(
    userId: json['userId'] as int,
    name: (json['name'] as String?) ?? '',
    isPrimary: json['isPrimary'] == true,
  );

  final int userId;
  final String name;
  final bool isPrimary;
}

/// 홈 화면이 한 번에 받아오는 값(GET /home).
class HomeSummary {
  HomeSummary({
    required this.userId,
    required this.userName,
    this.device,
    this.currentEmotion,
    required this.emotionTrend,
    required this.activities,
    required this.unreadNotificationCount,
    required this.unreadChatCount,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final device = json['device'] as Map<String, dynamic>?;
    final emotion = json['currentEmotion'] as Map<String, dynamic>?;
    return HomeSummary(
      userId: user['userId'] as int,
      userName: (user['name'] as String?) ?? '',
      device: device == null ? null : HomeDevice.fromJson(device),
      currentEmotion: emotion == null ? null : EmotionPoint.fromJson(emotion),
      // 서버가 최신순으로 주므로 그래프 순서에 맞게 뒤집는다.
      emotionTrend: ((json['emotionTrend'] as List?) ?? [])
          .map((e) => EmotionPoint.fromJson(e as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(),
      activities: ((json['activities'] as List?) ?? [])
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadNotificationCount: (json['unreadNotificationCount'] as int?) ?? 0,
      unreadChatCount: (json['unreadChatCount'] as int?) ?? 0,
    );
  }

  final int userId;
  final String userName;

  /// 아직 인형을 연결하지 않았으면 null.
  final HomeDevice? device;
  final EmotionPoint? currentEmotion;
  final List<EmotionPoint> emotionTrend;
  final List<ActivityItem> activities;
  final int unreadNotificationCount;
  final int unreadChatCount;
}

class HomeDevice {
  HomeDevice({
    required this.deviceId,
    required this.name,
    required this.connected,
    required this.batteryLevel,
    required this.batteryHoursLeft,
  });

  factory HomeDevice.fromJson(Map<String, dynamic> json) => HomeDevice(
    deviceId: json['deviceId'] as int,
    name: (json['name'] as String?) ?? '인형',
    connected: json['connected'] == true,
    batteryLevel: (json['batteryLevel'] as int?) ?? 0,
    batteryHoursLeft: (json['batteryHoursLeft'] as int?) ?? 0,
  );

  final int deviceId;
  final String name;
  final bool connected;
  final int batteryLevel;
  final int batteryHoursLeft;
}

class EmotionPoint {
  EmotionPoint({
    required this.emotionId,
    required this.emotion,
    this.createdAt,
  });

  factory EmotionPoint.fromJson(Map<String, dynamic> json) => EmotionPoint(
    emotionId: json['emotionId'] as int,
    emotion: (json['emotion'] as String?) ?? '',
    createdAt: DateTime.tryParse(
      (json['createdAt'] as String?) ?? '',
    )?.toLocal(),
  );

  final int emotionId;

  /// happy | calm | sad | angry | anxious | lonely
  final String emotion;
  final DateTime? createdAt;
}

class ActivityItem {
  ActivityItem({
    required this.activityId,
    required this.activityType,
    this.content,
    this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    activityId: json['activityId'] as int,
    activityType: (json['activityType'] as String?) ?? '',
    content: json['content'] as String?,
    createdAt: DateTime.tryParse(
      (json['createdAt'] as String?) ?? '',
    )?.toLocal(),
  );

  final int activityId;

  /// DAILY_CONVERSATION 같은 대문자 코드.
  final String activityType;
  final String? content;
  final DateTime? createdAt;
}

/// 알림 센터 한 건.
class AppNotification {
  AppNotification({
    required this.notificationId,
    required this.type,
    this.title,
    this.content,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        notificationId: json['notificationId'] as int,
        type: (json['type'] as int?) ?? 0,
        title: json['title'] as String?,
        content: json['content'] as String?,
        isRead: json['isRead'] == true,
        createdAt: DateTime.tryParse(
          (json['createdAt'] as String?) ?? '',
        )?.toLocal(),
      );

  final int notificationId;

  /// 0=긴급, 1=리포트. 그 밖은 일반 알림으로 본다.
  final int type;
  final String? title;
  final String? content;
  final bool isRead;
  final DateTime? createdAt;

  bool get isUrgent => type == 0;
  bool get isReport => type == 1;
}

/// 데일리 리포트. 서버가 아직 만들지 않았으면 조회 결과가 null 이다.
/// 주간 리포트. GET /users/{id}/reports/weekly 응답.
class WeeklyReportData {
  WeeklyReportData({
    required this.reportId,
    required this.totalConversationCount,
    required this.familyInteractionCount,
    this.avgEmotionScore,
    this.dominantEmotion,
    required this.emergencyAlertCount,
    this.weeklySummary,
    this.createdAt,
  });

  factory WeeklyReportData.fromJson(Map<String, dynamic> json) =>
      WeeklyReportData(
        reportId: json['reportId'] as int,
        totalConversationCount: (json['totalConversationCount'] as int?) ?? 0,
        familyInteractionCount: (json['familyInteractionCount'] as int?) ?? 0,
        avgEmotionScore: json['avgEmotionScore'] as int?,
        dominantEmotion: json['dominantEmotion'] as String?,
        emergencyAlertCount: (json['emergencyAlertCount'] as int?) ?? 0,
        weeklySummary: json['weeklySummary'] as String?,
        createdAt: DateTime.tryParse(
          (json['createdAt'] as String?) ?? '',
        )?.toLocal(),
      );

  final int reportId;
  final int totalConversationCount;
  final int familyInteractionCount;

  /// 0~100. 서버가 아직 못 채우면 null 이다.
  final int? avgEmotionScore;
  final String? dominantEmotion;
  final int emergencyAlertCount;
  final String? weeklySummary;
  final DateTime? createdAt;
}

class DailyReportData {
  DailyReportData({
    required this.reportId,
    this.reportDate,
    required this.conversationCount,
    required this.familyInteractionCount,
    this.emotionSummary,
    this.summary,
    this.suggestion,
    this.createdAt,
  });

  factory DailyReportData.fromJson(Map<String, dynamic> json) =>
      DailyReportData(
        reportId: json['reportId'] as int,
        reportDate: json['reportDate'] == null
            ? null
            : DateTime.parse(json['reportDate'] as String),
        conversationCount: (json['conversationCount'] as int?) ?? 0,
        familyInteractionCount: (json['familyInteractionCount'] as int?) ?? 0,
        emotionSummary: json['emotionSummary'] as String?,
        summary: json['summary'] as String?,
        suggestion: json['suggestion'] as String?,
        createdAt: DateTime.tryParse(
          (json['createdAt'] as String?) ?? '',
        )?.toLocal(),
      );

  final int reportId;

  /// 어느 날의 요약인지. 만들어진 시각(createdAt)과 다르다 —
  /// 배치가 자정 넘어 전날 것을 만들기 때문이다.
  final DateTime? reportDate;
  final int conversationCount;
  final int familyInteractionCount;
  final String? emotionSummary;
  final String? summary;

  /// 보호자가 오늘 해볼 만한 것. 서버가 못 만들었으면 비어 있다.
  final String? suggestion;
  final DateTime? createdAt;
}

/// 가족 대화방 메시지 한 건.
class ChatMessage {
  ChatMessage({
    required this.messageId,
    required this.senderType,
    this.senderId,
    this.content,
    this.imageUrl,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    messageId: json['messageId'] as int,
    senderType: (json['senderType'] as String?) ?? 'system',
    senderId: json['senderId'] as int?,
    content: json['content'] as String?,
    imageUrl: json['imageUrl'] as String?,
    createdAt: DateTime.tryParse(
      (json['createdAt'] as String?) ?? '',
    )?.toLocal(),
  );

  final int messageId;

  /// user(어르신) | protector(가족) | system(인형이 알려주는 소식)
  final String senderType;

  /// protector 가 보낸 메시지일 때의 보호자 id.
  final int? senderId;
  final String? content;
  final String? imageUrl;
  final DateTime? createdAt;

  bool get isSystem => senderType == 'system';
  bool get hasPhoto => (imageUrl ?? '').isNotEmpty;
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

/// POST /devices 응답 중 앱이 쓰는 부분.
class PairedDevice {
  PairedDevice({
    required this.deviceId,
    required this.userId,
    required this.name,
  });

  factory PairedDevice.fromJson(Map<String, dynamic> json) => PairedDevice(
    deviceId: json['deviceId'] as int,
    userId: json['userId'] as int,
    name: json['name'] as String? ?? '모리',
  );

  final int deviceId;
  final int userId;
  final String name;
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
    this.audioUrl,
  });

  factory DeviceVoice.fromJson(Map<String, dynamic> json) => DeviceVoice(
    voiceId: json['voiceId'] as int,
    name: json['name'] as String,
    status: json['status'] as String,
    progress: json['progress'] as int? ?? 0,
    isDefault: json['isDefault'] == true,
    audioUrl: json['audioUrl'] as String?,
  );

  final int voiceId;
  final String name;
  final String status; // ready | training | failed
  final int progress;
  final bool isDefault;

  /// 등록한 원본 녹음. 다시 들어볼 때 쓴다.
  final String? audioUrl;

  bool get isTraining => status == 'training';
  bool get isReady => status == 'ready';

  String get statusText => switch (status) {
    'ready' => '등록 완료',
    'training' => '학습 중...',
    _ => '학습 실패',
  };
}

/// 목소리 학습 상태 폴링 응답(GET /voices/{id}/status).
class VoiceStatus {
  VoiceStatus({
    required this.voiceId,
    required this.status,
    required this.progress,
    required this.speakerId,
    required this.errorMessage,
  });

  factory VoiceStatus.fromJson(Map<String, dynamic> json) => VoiceStatus(
    voiceId: json['voiceId'] as int,
    status: json['status'] as String,
    progress: json['progress'] as int? ?? 0,
    speakerId: json['speakerId'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  final int voiceId;
  final String status; // training | ready | failed
  final int progress;
  final String? speakerId; // ready 면 채워짐
  final String? errorMessage; // failed 면 사유

  bool get isReady => status == 'ready';
  bool get isFailed => status == 'failed';
  bool get isTraining => status == 'training';
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
