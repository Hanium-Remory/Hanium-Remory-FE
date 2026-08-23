import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../1. splash_onboarding/splash_screen.dart';
import '../4. home/home_and_alert_center.dart';
import '../5. memory/memory_add_flow.dart';
import '../6. chat/family_chat_screen.dart';
import '../services/session_store.dart';
import '../services/settings_api.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);
const Color _green = Color(0xFF5D9E41);

final SettingsApi _api = SettingsApi();

class SettingsFlow extends StatefulWidget {
  const SettingsFlow({super.key});

  @override
  State<SettingsFlow> createState() => _SettingsFlowState();
}

class _SettingsFlowState extends State<SettingsFlow> {
  int _destination = 3;

  @override
  Widget build(BuildContext context) {
    return switch (_destination) {
      0 => const HomeAndAlertPreview(),
      1 => const FamilyChatScreen(),
      2 => const MemoryAddFlow(),
      _ => SettingsHubScreen(
        onBack: () => setState(() => _destination = 0),
        onDestinationSelected: (index) => setState(() => _destination = index),
      ),
    };
  }
}

/// 설정 허브에서 한 번에 불러오는 것들(각 화면 부제목에 쓰인다).
class _HubData {
  _HubData({
    required this.profile,
    required this.family,
    required this.dnd,
    required this.medications,
    required this.info,
  });

  final MyProfile profile;
  final FamilyMembers? family;
  final DndSettings? dnd;
  final MedicationList? medications;
  final ServiceInfo? info;
}

Future<_HubData> _loadHub() async {
  final profile = await _api.myProfile();
  final user = profile.mainUser;
  final deviceId = user?.deviceId;

  // 아직 어르신/인형이 연결되지 않았으면 해당 호출은 건너뛴다.
  final Future<FamilyMembers?> familyF = user == null
      ? Future<FamilyMembers?>.value()
      : _api.familyMembers(user.userId);
  final Future<DndSettings?> dndF = deviceId == null
      ? Future<DndSettings?>.value()
      : _api.dnd(deviceId);
  final Future<MedicationList?> medsF = deviceId == null
      ? Future<MedicationList?>.value()
      : _api.medications(deviceId);
  final Future<ServiceInfo?> infoF = _api
      .serviceInfo()
      .then<ServiceInfo?>((v) => v)
      .catchError((_) => null);

  return _HubData(
    profile: profile,
    family: await familyF,
    dnd: await dndF,
    medications: await medsF,
    info: await infoF,
  );
}

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({
    super.key,
    this.onBack,
    required this.onDestinationSelected,
  });

  final VoidCallback? onBack;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Row(
            children: [
              IconButton(
                tooltip: '홈으로 돌아가기',
                onPressed:
                    onBack ??
                    () => _replaceRoot(context, const HomeAndAlertPreview()),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: _dark,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 4),
              const Text(
                '설정',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Expanded(
            child: _AsyncView<_HubData>(
              load: _loadHub,
              builder: (context, data, reload) =>
                  _HubBody(data: data, reload: reload),
            ),
          ),
          _SettingsNavBar(onSelected: onDestinationSelected),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({required this.data, required this.reload});

  final _HubData data;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final user = profile.mainUser;
    final deviceId = user?.deviceId;
    final dnd = data.dnd;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        GestureDetector(
          onTap: () => _openAndReload(context, const MyProfileScreen(), reload),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                _Avatar(label: _initial(profile.name), size: 50, color: _brown),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _dark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (profile.relation != null) profile.relation!,
                          if (profile.formattedPhone.isNotEmpty)
                            profile.formattedPhone,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _muted, size: 20),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        if (user == null)
          _NoElderCard(reload: reload)
        else ...[
          _Section(
            title: '돌봄',
            children: [
              _MenuRow(
                icon: Icons.sentiment_satisfied_alt,
                title: '모리 인형 설정',
                subtitle: '목소리, 볼륨, 배터리',
                onTap: deviceId == null
                    ? null
                    : () => _openAndReload(
                        context,
                        DollSettingsScreen(deviceId: deviceId),
                        reload,
                      ),
              ),
              _MenuRow(
                icon: Icons.person_outline,
                title: '${user.name}님 정보',
                subtitle: '이름, 성별, 생년월일',
                onTap: () => _openAndReload(
                  context,
                  ElderInfoScreen(userId: user.userId),
                  reload,
                ),
              ),
              _MenuRow(
                icon: Icons.groups_outlined,
                title: '가족 멤버',
                subtitle: '${data.family?.familyCount ?? 0}명 연결됨',
                badge: '${data.family?.familyCount ?? 0}',
                onTap: () => _openAndReload(
                  context,
                  FamilyMembersScreen(userId: user.userId),
                  reload,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _Section(
            title: '알림',
            children: [
              _MenuRow(
                icon: Icons.notifications_none,
                title: '알림 설정',
                subtitle: '긴급 / 데일리 / 일반',
                onTap: () => _openAndReload(
                  context,
                  const NotificationSettingsScreen(),
                  reload,
                ),
              ),
              _MenuRow(
                icon: Icons.nightlight_round,
                title: '방해 금지 시간',
                subtitle: dnd == null
                    ? '-'
                    : dnd.enabled
                    ? '${_hourText(dnd.startHour)} ~ ${_hourText(dnd.endHour)}'
                    : '사용 안 함',
                onTap: deviceId == null
                    ? null
                    : () => _openAndReload(
                        context,
                        QuietHoursScreen(deviceId: deviceId),
                        reload,
                      ),
              ),
              _MenuRow(
                icon: Icons.medication_outlined,
                title: '약 복용 시간',
                subtitle: '하루 ${data.medications?.items.length ?? 0}번',
                onTap: deviceId == null
                    ? null
                    : () => _openAndReload(
                        context,
                        MedicationTimeScreen(deviceId: deviceId),
                        reload,
                      ),
              ),
            ],
          ),
        ],
        SizedBox(height: 14.h),
        _Section(
          title: '계정',
          children: [
            const _MenuRow(
              icon: Icons.shield_outlined,
              title: '개인정보 및 보안',
              subtitle: '',
            ),
            _MenuRow(
              icon: Icons.info_outline,
              title: 'ReMory 정보',
              subtitle: data.info == null ? '' : '버전 ${data.info!.version}',
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

/// 어르신·인형이 아직 연결되지 않은 상태(첫 등록/초대 코드 플로우 연결 전).
class _NoElderCard extends StatefulWidget {
  const _NoElderCard({required this.reload});

  final Future<void> Function() reload;

  @override
  State<_NoElderCard> createState() => _NoElderCardState();
}

class _NoElderCardState extends State<_NoElderCard> {
  bool _busy = false;

  Future<void> _seed() async {
    setState(() => _busy = true);
    try {
      await _api.seedDemoData();
      await widget.reload();
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.link_off, color: _muted, size: 28),
          SizedBox(height: 10.h),
          Text(
            '아직 연결된 어르신이 없어요.\n인형을 등록하면 돌봄·알림 설정을 쓸 수 있어요.',
            textAlign: TextAlign.center,
            style: _caption(),
          ),
          SizedBox(height: 12.h),
          // 첫 등록/초대 코드 플로우가 붙기 전까지 쓰는 개발용 버튼.
          TextButton(
            onPressed: _busy ? null : _seed,
            style: TextButton.styleFrom(foregroundColor: _brown),
            child: Text(_busy ? '만드는 중...' : '샘플 데이터 만들기 (개발용)'),
          ),
        ],
      ),
    );
  }
}

// ── 내 프로필 ────────────────────────────────────────
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<MyProfile>(
        load: _api.myProfile,
        builder: (context, profile, reload) => Column(
          children: [
            _TopHeader(
              title: '내 프로필',
              onBack: () => setState(() => _showSettings = true),
              action: '편집',
              onAction: () => _openAndReload(
                context,
                MyProfileEditScreen(profile: profile),
                reload,
              ),
            ),
            Expanded(child: _MyProfileBody(profile: profile)),
            const _HomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _MyProfileBody extends StatefulWidget {
  const _MyProfileBody({required this.profile});

  final MyProfile profile;

  @override
  State<_MyProfileBody> createState() => _MyProfileBodyState();
}

class _MyProfileBodyState extends State<_MyProfileBody> {
  late Map<String, bool> _values = Map.of(widget.profile.notifications);

  /// 스위치는 즉시 반영하고, 실패하면 이전 값으로 되돌린다.
  Future<void> _toggle(String key, bool value) async {
    final previous = _values[key] ?? false;
    setState(() => _values[key] = value);
    try {
      final saved = await _api.updateNotificationSettings({key: value});
      if (mounted) setState(() => _values = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _values[key] = previous);
      _toast(context, _errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final elder = profile.mainUser;

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        SizedBox(height: 22.h),
        Center(
          child: _Avatar(
            label: _initial(profile.name),
            size: 78,
            color: _brown,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            color: _dark,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (elder != null && profile.relation != null)
          Text(
            '${elder.name}의 ${profile.relation}',
            textAlign: TextAlign.center,
            style: _tiny(),
          ),
        SizedBox(height: 28.h),
        _Label('기본 정보'),
        _InfoCard(
          rows: [
            ('이름', profile.name),
            ('전화번호', profile.formattedPhone),
            ('관계', profile.relation ?? '미입력'),
          ],
        ),
        SizedBox(height: 16.h),
        _Label('내가 받는 알림'),
        _SwitchCard(
          rows: [
            _SwitchData(
              '긴급 알림',
              '감정 변화, 기기 연결 등',
              _values[NotificationKeys.urgent] ?? false,
              (v) => _toggle(NotificationKeys.urgent, v),
            ),
            _SwitchData(
              '데일리 리포트',
              '매일 아침 7시',
              _values[NotificationKeys.dailyReport] ?? false,
              (v) => _toggle(NotificationKeys.dailyReport, v),
            ),
            _SwitchData(
              '대화 알림',
              '${elder?.name ?? '어르신'}님이 말씀하실 때',
              _values[NotificationKeys.chat] ?? false,
              (v) => _toggle(NotificationKeys.chat, v),
            ),
            _SwitchData(
              '마케팅 알림',
              '신기능 안내',
              _values[NotificationKeys.marketing] ?? false,
              (v) => _toggle(NotificationKeys.marketing, v),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class MyProfileEditScreen extends StatefulWidget {
  const MyProfileEditScreen({super.key, required this.profile});

  final MyProfile profile;

  @override
  State<MyProfileEditScreen> createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  static const _relations = ['딸', '아들', '며느리', '사위', '손주', '손녀', '기타'];

  late final TextEditingController name = TextEditingController(
    text: widget.profile.name,
  );
  late final TextEditingController phone = TextEditingController(
    text: widget.profile.formattedPhone,
  );
  Uint8List? photoBytes;
  late String? relation = widget.profile.relation;
  bool _saving = false;
  bool _showProfile = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      _toast(context, '이름을 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.updateProfile(name: name.text.trim(), relation: relation);
      if (!mounted) return;
      _savedToast(context);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bg,
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '탈퇴하면 패스키와 돌봄 기록이 모두 삭제돼요.\n정말 탈퇴하시겠어요?',
          style: _caption(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('탈퇴', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.withdraw();
      await SessionStore.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showProfile) return const MyProfileScreen();
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '프로필 편집',
            onBack: () => setState(() => _showProfile = true),
            action: _saving ? '저장 중' : '저장',
            onAction: _saving ? null : _save,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 18.h),
                Center(
                  child: _EditableProfilePhoto(
                    label: _initial(name.text),
                    imageBytes: photoBytes,
                    onChanged: (bytes) => setState(() => photoBytes = bytes),
                  ),
                ),
                SizedBox(height: 24.h),
                _InputField(label: '이름', controller: name),
                _InputField(
                  label: '전화번호',
                  controller: phone,
                  // 번호 변경은 SMS 재인증이 필요해 여기서는 수정할 수 없다.
                  enabled: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check, color: _green, size: 13),
                      SizedBox(width: 3),
                      Text(
                        '인증됨',
                        style: TextStyle(
                          fontSize: 10,
                          color: _green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _Label('관계'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relations.map((item) {
                    return _ChoiceChipButton(
                      text: item,
                      selected: relation == item,
                      onTap: () => setState(() => relation = item),
                    );
                  }).toList(),
                ),
                SizedBox(height: 64.h),
                Center(
                  child: GestureDetector(
                    onTap: _withdraw,
                    child: Text(
                      '회원 탈퇴',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

// ── 인형 설정 ────────────────────────────────────────
class DollSettingsScreen extends StatefulWidget {
  const DollSettingsScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  State<DollSettingsScreen> createState() => _DollSettingsScreenState();
}

class _DollSettingsScreenState extends State<DollSettingsScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();

    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '인형 설정',
            onBack: () => setState(() => _showSettings = true),
          ),
          Expanded(
            child: _AsyncView<DeviceSettings>(
              load: () => _api.deviceSettings(widget.deviceId),
              builder: (context, device, reload) =>
                  _DollSettingsBody(device: device, reload: reload),
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

class _DollSettingsBody extends StatelessWidget {
  const _DollSettingsBody({required this.device, required this.reload});

  final DeviceSettings device;
  final Future<void> Function() reload;

  Future<void> _selectVoice(BuildContext context, DeviceVoice voice) async {
    if (voice.isDefault) return;
    if (!voice.isReady) {
      _toast(context, '아직 학습 중인 목소리예요.');
      return;
    }
    try {
      await _api.setDefaultVoice(device.deviceId, voice.voiceId);
      await reload();
    } catch (e) {
      if (context.mounted) _toast(context, _errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paired = device.pairedAt;
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        SizedBox(height: 12.h),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFEFD6C5),
                child: Icon(Icons.smart_toy_outlined, size: 56, color: _brown),
              ),
              SizedBox(height: 14.h),
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 18,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              if (paired != null)
                Text(
                  '${paired.year}.${paired.month.toString().padLeft(2, '0')}.${paired.day.toString().padLeft(2, '0')}',
                  style: _tiny(),
                ),
              SizedBox(height: 12.h),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: device.connected
                      ? const Color(0xFFE7F6D8)
                      : const Color(0xFFF1E4D9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  device.connected ? '잘 연결되어 있어요' : '연결이 끊겼어요',
                  style: TextStyle(
                    fontSize: 10,
                    color: device.connected ? _green : _brown,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        _Label('배터리'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${device.batteryLevel}%',
                    style: const TextStyle(
                      fontSize: 26,
                      color: _dark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text('약 ${device.batteryHoursLeft}시간 남았어요', style: _tiny()),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: device.batteryLevel / 100,
                  minHeight: 8,
                  color: device.batteryLevel <= 20 ? _yellow : _green,
                  backgroundColor: const Color(0xFFEAE1D8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        _Label('인형 목소리'),
        if (device.voices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Text('아직 등록된 목소리가 없어요.', style: _caption()),
          )
        else
          _SectionCard(
            children: device.voices
                .map(
                  (voice) => _VoiceRow(
                    name: voice.name,
                    subtitle: voice.statusText,
                    checked: voice.isDefault,
                    progress: voice.isTraining ? voice.progress / 100 : null,
                    onTap: () => _selectVoice(context, voice),
                  ),
                )
                .toList(),
          ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: () => _toast(context, '목소리 등록은 음성 녹음 화면에서 준비 중이에요.'),
          icon: const Icon(Icons.add),
          label: const Text('새 목소리 등록'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brown,
            side: const BorderSide(color: _brown),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        _Label('그 외'),
        _SectionCard(
          children: [
            _MenuRow(
              icon: Icons.volume_up_outlined,
              title: '인형 볼륨',
              subtitle: '${device.volumeText} (${device.volume}%)',
              onTap: () => _openAndReload(
                context,
                DollVolumeScreen(
                  deviceId: device.deviceId,
                  initialVolume: device.volume,
                ),
                reload,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class DollVolumeScreen extends StatefulWidget {
  const DollVolumeScreen({
    super.key,
    required this.deviceId,
    required this.initialVolume,
  });

  final int deviceId;
  final int initialVolume;

  @override
  State<DollVolumeScreen> createState() => _DollVolumeScreenState();
}

class _DollVolumeScreenState extends State<DollVolumeScreen> {
  late double volume = widget.initialVolume.toDouble().clamp(30, 95);
  bool _saving = false;
  bool _showDollSettings = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateDeviceSettings(widget.deviceId, volume: volume.round());
      if (!mounted) return;
      _savedToast(context);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showDollSettings) {
      return DollSettingsScreen(deviceId: widget.deviceId);
    }

    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '인형 볼륨',
            onBack: () => setState(() => _showDollSettings = true),
            action: _saving ? '저장 중' : '저장',
            onAction: _saving ? null : _save,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  '${SessionStore.elderHonorific}이 편하게 들으실 수 있는 볼륨으로 맞춰주세요.',
                  style: _caption(),
                ),
                SizedBox(height: 22.h),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Text(
                        '${volume.round()}%',
                        style: const TextStyle(
                          fontSize: 48,
                          color: _brown,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Slider(
                        value: volume,
                        min: 30,
                        max: 95,
                        divisions: 65,
                        activeColor: _brown,
                        inactiveColor: _line,
                        onChanged: (v) => setState(() => volume = v),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                _Label('추천 볼륨'),
                for (final data in const [
                  (30, '작게', '조용한 새벽용'),
                  (60, '보통', '실내 거리에서'),
                  (80, '크게', '귀가 어두우신 분께'),
                  (95, '아주 크게', '먼 곳에서도 들리게'),
                ])
                  _VolumePreset(
                    percent: data.$1,
                    title: data.$2,
                    subtitle: data.$3,
                    onTap: () => setState(() => volume = data.$1.toDouble()),
                  ),
              ],
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

// ── 어르신 정보 ──────────────────────────────────────
class ElderInfoScreen extends StatefulWidget {
  const ElderInfoScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ElderInfoScreen> createState() => _ElderInfoScreenState();
}

class _ElderInfoScreenState extends State<ElderInfoScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<ElderUser>(
        load: () => _api.user(widget.userId),
        builder: (context, user, reload) => Column(
          children: [
            _TopHeader(
              title: '${user.name}님 정보',
              onBack: () => setState(() => _showSettings = true),
              action: '편집',
              onAction: () => _openAndReload(
                context,
                ElderInfoEditScreen(user: user),
                reload,
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        _Avatar(
                          label: _initial(user.name),
                          size: 62,
                          color: const Color(0xFFDCC7B6),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: _dark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  user.genderText,
                                  user.birthText,
                                  if (user.age != null) '만 ${user.age}세',
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  _Label('기본 정보'),
                  _InfoCard(
                    rows: [
                      ('이름', user.name),
                      ('성별', user.genderText),
                      ('생년월일', user.birthText),
                    ],
                  ),
                  if (user.note.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _Label('메모'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Text(user.note, style: _caption()),
                    ),
                  ],
                ],
              ),
            ),
            const _HomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class ElderInfoEditScreen extends StatefulWidget {
  const ElderInfoEditScreen({super.key, required this.user});

  final ElderUser user;

  @override
  State<ElderInfoEditScreen> createState() => _ElderInfoEditScreenState();
}

class _ElderInfoEditScreenState extends State<ElderInfoEditScreen> {
  late final TextEditingController name = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController note = TextEditingController(
    text: widget.user.note,
  );
  Uint8List? photoBytes;
  late String gender = widget.user.gender == 'male' ? '남성' : '여성';
  late int year = widget.user.birthDate?.year ?? 1950;
  late int month = widget.user.birthDate?.month ?? 1;
  late int day = widget.user.birthDate?.day ?? 1;
  bool _saving = false;

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      _toast(context, '이름을 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.updateUser(
        widget.user.userId,
        name: name.text.trim(),
        gender: gender == '남성' ? 'male' : 'female',
        // 말일이 없는 달을 고르면 DateTime이 다음 달로 넘어가므로 미리 맞춘다.
        birthDate: DateTime(
          year,
          month,
          day.clamp(1, _daysInMonth(year, month)),
        ),
        note: note.text.trim(),
      );
      if (!mounted) return;
      _savedToast(context);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '프로필 편집',
            action: _saving ? '저장 중' : '저장',
            onAction: _saving ? null : _save,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 10.h),
                Center(
                  child: _EditableProfilePhoto(
                    label: _initial(name.text),
                    imageBytes: photoBytes,
                    onChanged: (bytes) => setState(() => photoBytes = bytes),
                  ),
                ),
                SizedBox(height: 22.h),
                _InputField(label: '이름', controller: name),
                _Label('성별'),
                Row(
                  children: ['여성', '남성']
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _ChoiceChipButton(
                              text: item,
                              selected: gender == item,
                              onTap: () {
                                SessionStore.setElderGender(
                                  item == '남성' ? 'male' : 'female',
                                );
                                setState(() => gender = item);
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 14.h),
                _Label('생년월일'),
                _DateStepper(
                  year: year,
                  month: month,
                  day: day,
                  onYear: (value) => setState(() {
                    year = value;
                    day = day.clamp(1, _daysInMonth(year, month));
                  }),
                  onMonth: (value) => setState(() {
                    month = value;
                    day = day.clamp(1, _daysInMonth(year, month));
                  }),
                  onDay: (value) => setState(() => day = value),
                ),
                SizedBox(height: 16.h),
                _InputField(
                  label: '메모',
                  controller: note,
                  hint: '좋아하시는 것, 주의할 점 등',
                ),
              ],
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

int _daysInMonth(int year, int month) =>
    DateTime(year, month + 1, 0).day; // 다음 달 0일 = 이번 달 말일

// ── 가족 멤버 ────────────────────────────────────────
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key, required this.userId});

  final int userId;

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  bool _showSettings = false;

  Future<void> _remove(
    BuildContext context,
    FamilyMember member,
    Future<void> Function() reload,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bg,
        title: const Text(
          '가족 제거',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '${member.name}님을 가족에서 제거할까요?\n등록한 인형 목소리도 함께 지워져요.',
          style: _caption(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('제거', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.removeFamilyMember(member.protectorId);
      await reload();
    } catch (e) {
      if (context.mounted) _toast(context, _errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<FamilyMembers>(
        load: () => _api.familyMembers(widget.userId),
        builder: (context, family, reload) => Column(
          children: [
            _TopHeader(
              title: '가족 멤버',
              onBack: () => setState(() => _showSettings = true),
              iconAction: Icons.share_outlined,
              onAction: () => _push(context, const FamilyInviteScreen()),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    family.iAmPrimary
                        ? '함께 돌보는 가족이에요.\n가족을 길게 눌러 연결을 해제할 수 있어요.'
                        : '함께 돌보는 가족이에요.',
                    style: _caption(),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          title: '가족',
                          value: '${family.familyCount}명',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: '목소리',
                          value: '${family.voiceCount}개',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          title: '생성된 코드',
                          value: '${family.inviteCodeCount}개',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _SectionCard(
                    children: family.members
                        .map(
                          (member) => _FamilyRow(
                            name: member.name,
                            role: member.relation ?? '가족',
                            badges: member.badges,
                            // 주보호자만, 본인이 아닌 가족을 제거할 수 있다.
                            onLongPress:
                                family.iAmPrimary &&
                                    !member.isMe &&
                                    !member.isPrimary
                                ? () => _remove(context, member, reload)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 12.h),
                  ElevatedButton.icon(
                    onPressed: () => _push(context, const FamilyInviteScreen()),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('새 가족 초대하기'),
                    style: _primaryButtonStyle(),
                  ),
                ],
              ),
            ),
            const _HomeIndicator(),
          ],
        ),
      ),
    );
  }
}

/// 초대 코드 발급 API는 아직 없어서 화면만 유지한다(코드 플로우 붙일 때 연결).
class FamilyInviteScreen extends StatefulWidget {
  const FamilyInviteScreen({super.key});

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen> {
  bool copied = false;
  static const code = '7M92A4';

  Future<void> _copy() async {
    await Clipboard.setData(const ClipboardData(text: code));
    setState(() => copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          const _TopHeader(title: '가족 초대'),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 34.h),
                const Text(
                  '이 코드를 가족에게 공유해주세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 46.h),
                GestureDetector(
                  onTap: _copy,
                  child: Container(
                    padding: const EdgeInsets.all(26),
                    decoration: _cardDecoration(shadow: true),
                    child: Column(
                      children: [
                        Text('초대 코드', style: _tiny()),
                        SizedBox(height: 14.h),
                        const Text(
                          code,
                          style: TextStyle(
                            fontSize: 34,
                            color: _brown,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8EFE6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '48시간 동안 유효해요.\n가족이 ReMory 앱에서 이 코드를 입력하면 연결돼요.',
                            textAlign: TextAlign.center,
                            style: _tiny(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                if (copied)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _dark,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        '초대 코드를 복사했어요',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 18.h),
                ElevatedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy),
                  label: const Text('복사하기'),
                  style: _primaryButtonStyle(),
                ),
                SizedBox(height: 10.h),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('공유하기'),
                  style: _softButtonStyle(),
                ),
              ],
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

// ── 알림 설정 ────────────────────────────────────────
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<MyProfile>(
        load: _api.myProfile,
        builder: (context, profile, reload) => _NotificationSettingsBody(
          profile: profile,
          onBack: () => setState(() => _showSettings = true),
        ),
      ),
    );
  }
}

class _NotificationSettingsBody extends StatefulWidget {
  const _NotificationSettingsBody({
    required this.profile,
    required this.onBack,
  });

  final MyProfile profile;
  final VoidCallback onBack;

  @override
  State<_NotificationSettingsBody> createState() =>
      _NotificationSettingsBodyState();
}

class _NotificationSettingsBodyState extends State<_NotificationSettingsBody> {
  /// 화면 라벨 → 현재 값. 저장할 때 백엔드 필드명으로 바꿔 보낸다.
  late final Map<String, bool> values = {
    for (final entry in NotificationKeys.byLabel.entries)
      entry.key: widget.profile.notifications[entry.value] ?? false,
  };
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateNotificationSettings({
        for (final entry in NotificationKeys.byLabel.entries)
          entry.value: values[entry.key] ?? false,
      });
      if (!mounted) return;
      _savedToast(context);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopHeader(
          title: '알림 설정',
          onBack: widget.onBack,
          action: _saving ? '저장 중' : '저장',
          onAction: _saving ? null : _save,
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text('받고 싶은 알림만 켜두세요.\n종류별로 따로 설정할 수 있어요.', style: _caption()),
              SizedBox(height: 18.h),
              _NotificationGroup(
                title: '긴급',
                names: const ['감정 변화', '기기 연결 해제', '약 미복용'],
                values: values,
                onChanged: _setValue,
              ),
              _NotificationGroup(
                title: '일상',
                names: const ['어머님 음성 요청', '메시지 전달 완료', '목소리 학습 완료'],
                values: values,
                onChanged: _setValue,
              ),
              _NotificationGroup(
                title: '리포트',
                names: const ['데일리 리포트', '주간 리포트'],
                values: values,
                onChanged: _setValue,
              ),
              _NotificationGroup(
                title: '기타',
                names: const ['앱 업데이트'],
                values: values,
                onChanged: _setValue,
              ),
            ],
          ),
        ),
        const _HomeIndicator(),
      ],
    );
  }

  void _setValue(String name, bool value) =>
      setState(() => values[name] = value);
}

// ── 방해 금지 시간 ───────────────────────────────────
class QuietHoursScreen extends StatefulWidget {
  const QuietHoursScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  State<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends State<QuietHoursScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<DndSettings>(
        load: () => _api.dnd(widget.deviceId),
        builder: (context, dnd, reload) => _QuietHoursBody(
          deviceId: widget.deviceId,
          dnd: dnd,
          onBack: () => setState(() => _showSettings = true),
        ),
      ),
    );
  }
}

class _QuietHoursBody extends StatefulWidget {
  const _QuietHoursBody({
    required this.deviceId,
    required this.dnd,
    required this.onBack,
  });

  final int deviceId;
  final DndSettings dnd;
  final VoidCallback onBack;

  @override
  State<_QuietHoursBody> createState() => _QuietHoursBodyState();
}

class _QuietHoursBodyState extends State<_QuietHoursBody> {
  late bool enabled = widget.dnd.enabled;
  late bool urgent = widget.dnd.allowUrgentAlert;
  late bool wake = widget.dnd.allowWakeWord;
  late int start = widget.dnd.startHour;
  late int end = widget.dnd.endHour;
  bool _saving = false;

  Future<void> _save() async {
    if (start == end) {
      _toast(context, '시작과 끝 시각을 다르게 설정해 주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.updateDnd(
        widget.deviceId,
        enabled: enabled,
        startHour: start,
        endHour: end,
        allowUrgentAlert: urgent,
        allowWakeWord: wake,
      );
      if (!mounted) return;
      _savedToast(context);
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopHeader(
          title: '방해 금지 시간',
          onBack: widget.onBack,
          action: _saving ? '저장 중' : '저장',
          onAction: _saving ? null : _save,
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text('이 시간엔 인형이 먼저 말을 걸지 않아요.', style: _caption()),
              SizedBox(height: 18.h),
              _SectionCard(
                children: [
                  _SwitchLine(
                    icon: Icons.nightlight_round,
                    title: '방해 금지 사용',
                    subtitle: '${_hourText(start)} ~ ${_hourText(end)}',
                    value: enabled,
                    onChanged: (v) => setState(() => enabled = v),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              _Label('시간 설정'),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: Center(
                            child: Text(
                              '시작',
                              style: TextStyle(
                                fontSize: 11,
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '끝',
                              style: TextStyle(
                                fontSize: 11,
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _HourStepper(
                            hour: start,
                            onAdd: () =>
                                setState(() => start = (start + 1) % 24),
                            onSub: () =>
                                setState(() => start = (start + 23) % 24),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.arrow_forward,
                            color: _muted,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: _HourStepper(
                            hour: end,
                            onAdd: () => setState(() => end = (end + 1) % 24),
                            onSub: () => setState(() => end = (end + 23) % 24),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '${_hourText(start)}부터 다음날 ${_hourText(end)}까지',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _brown,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              _Label('예외'),
              _SectionCard(
                children: [
                  _SwitchLine(
                    title: '긴급 알림은 내게 받기',
                    subtitle: '급격한 감정 변화·기기 점검 알림은 받아요',
                    value: urgent,
                    onChanged: (v) => setState(() => urgent = v),
                  ),
                  _SwitchLine(
                    title: '${SessionStore.elderHonorific}이 "모리야" 부르시면 깨우기',
                    subtitle: '이 시간에도 부르시면 모리가 응답해드려요',
                    value: wake,
                    onChanged: (v) => setState(() => wake = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _HomeIndicator(),
      ],
    );
  }
}

// ── 약 복용 시간 ─────────────────────────────────────
class MedicationTimeScreen extends StatefulWidget {
  const MedicationTimeScreen({super.key, required this.deviceId});

  final int deviceId;

  @override
  State<MedicationTimeScreen> createState() => _MedicationTimeScreenState();
}

class _MedicationTimeScreenState extends State<MedicationTimeScreen> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    if (_showSettings) return const SettingsFlow();
    return _PhoneFrame(
      child: _AsyncView<MedicationList>(
        load: () => _api.medications(widget.deviceId),
        builder: (context, list, reload) => _MedicationBody(
          deviceId: widget.deviceId,
          list: list,
          reload: reload,
          onBack: () => setState(() => _showSettings = true),
        ),
      ),
    );
  }
}

class _MedicationBody extends StatefulWidget {
  const _MedicationBody({
    required this.deviceId,
    required this.list,
    required this.reload,
    required this.onBack,
  });

  final int deviceId;
  final MedicationList list;
  final Future<void> Function() reload;
  final VoidCallback onBack;

  @override
  State<_MedicationBody> createState() => _MedicationBodyState();
}

class _MedicationBodyState extends State<_MedicationBody> {
  late bool check = widget.list.medicationCheck;

  Future<void> _setCheck(bool value) async {
    final previous = check;
    setState(() => check = value);
    try {
      await _api.updateDeviceSettings(widget.deviceId, medicationCheck: value);
    } catch (e) {
      if (!mounted) return;
      setState(() => check = previous);
      _toast(context, _errorText(e));
    }
  }

  Future<void> _delete(Medication med) async {
    try {
      await _api.deleteMedication(med.medicationId);
      await widget.reload();
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    }
  }

  Future<void> _add() async {
    final draft = await showModalBottomSheet<_MedicationDraft>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddMedicationSheet(),
    );
    if (draft == null) return;
    try {
      await _api.addMedication(
        widget.deviceId,
        name: draft.name,
        time: draft.time,
        timing: draft.timing,
      );
      await widget.reload();
    } catch (e) {
      if (mounted) _toast(context, _errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.list.items;
    return Column(
      children: [
        _TopHeader(
          title: '약 복용 시간',
          onBack: widget.onBack,
          action: '저장',
          onAction: () => _savedToast(context),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Text('설정한 시간에 인형이 약 드실 시간이라고 말씀드려요.', style: _caption()),
              SizedBox(height: 28.h),
              _Label('오늘의 약'),
              if (meds.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Text('아직 등록한 약이 없어요.', style: _caption()),
                ),
              for (final med in meds)
                _MedicationTile(med: med, onDelete: () => _delete(med)),
              TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('약 추가하기'),
                style: TextButton.styleFrom(foregroundColor: _brown),
              ),
              SizedBox(height: 18.h),
              _Label('알림 방법'),
              _SectionCard(
                children: [
                  _SwitchLine(
                    title: '드셨는지 인형이 확인하기',
                    subtitle: '"약 드셨어요?" 라고 여쭤봐요',
                    value: check,
                    onChanged: _setCheck,
                  ),
                ],
              ),
            ],
          ),
        ),
        const _HomeIndicator(),
      ],
    );
  }
}

/// 시트에서 입력받은 값(저장은 호출한 화면이 한다).
class _MedicationDraft {
  _MedicationDraft(this.name, this.time, this.timing);

  final String name;
  final String time; // "HH:MM"
  final String timing;
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet();

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final name = TextEditingController();
  bool isAm = true;
  int hour = 8; // 1~12
  int minute = 0;
  String timing = '식후';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  /// 오전/오후 + 12시간 표기를 백엔드가 받는 24시간 "HH:MM"으로.
  String get _time24 {
    var h = hour % 12;
    if (!isAm) h += 12;
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = name.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 3,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            const Text(
              '새 약 추가',
              style: TextStyle(
                fontSize: 20,
                color: _dark,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 18.h),
            _InputField(
              label: '약 이름',
              controller: name,
              hint: '예: 혈압약',
              onChanged: (_) => setState(() {}),
            ),
            _Label('시간'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: _NumberStepper(
                      text: isAm ? '오전' : '오후',
                      onAdd: () => setState(() => isAm = !isAm),
                      onSub: () => setState(() => isAm = !isAm),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberStepper(
                      text: '${hour.toString().padLeft(2, '0')}시',
                      onAdd: () => setState(() => hour = (hour % 12) + 1),
                      onSub: () =>
                          setState(() => hour = hour == 1 ? 12 : hour - 1),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 20,
                        color: _brown,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _NumberStepper(
                      text: '${minute.toString().padLeft(2, '0')}분',
                      onAdd: () => setState(() => minute = (minute + 5) % 60),
                      onSub: () => setState(() => minute = (minute + 55) % 60),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            _Label('복용 시점'),
            Row(
              children: ['식전', '식후', '공복', '아무때나']
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ChoiceChipButton(
                          text: item,
                          selected: timing == item,
                          onTap: () => setState(() => timing = item),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: _softButtonStyle(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAdd
                        ? () => Navigator.pop(
                            context,
                            _MedicationDraft(name.text.trim(), _time24, timing),
                          )
                        : null,
                    style: _primaryButtonStyle(),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공용: 로딩/에러 처리 ─────────────────────────────
class _AsyncView<T> extends StatefulWidget {
  const _AsyncView({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;

  @override
  State<_AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<_AsyncView<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() async {
    setState(() => _future = widget.load());
    try {
      await _future;
    } catch (_) {
      // 에러는 FutureBuilder가 화면에 표시한다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: _brown, strokeWidth: 2.5),
          );
        }
        if (snapshot.hasError) {
          return _ErrorBox(
            message: _errorText(snapshot.error),
            onRetry: _reload,
          );
        }
        return widget.builder(context, snapshot.data as T, _reload);
      },
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: _muted, size: 30),
            SizedBox(height: 12.h),
            Text(message, textAlign: TextAlign.center, style: _caption()),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: _brown),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

String _errorText(Object? error) {
  if (error is ApiException) return error.message;
  return '연결에 실패했어요. 잠시 후 다시 시도해 주세요.';
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: _dark,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _savedToast(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    const SnackBar(
      content: Text(
        '저장되었습니다',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
      width: 150,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      duration: Duration(seconds: 3),
      backgroundColor: _dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
  Timer(const Duration(seconds: 3), messenger.removeCurrentSnackBar);
}

String _initial(String name) => name.trim().isEmpty ? '?' : name.trim()[0];

/// 하위 화면에서 값이 바뀌어 돌아오면 목록을 다시 불러온다.
Future<void> _openAndReload(
  BuildContext context,
  Widget page,
  Future<void> Function() reload,
) async {
  await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
  await reload();
}

void _push(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

void _replaceRoot(BuildContext context, Widget page) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (_) => false);
}

String _hourText(int hour) {
  final period = hour < 12 ? '오전' : '오후';
  final display = hour % 12 == 0 ? 12 : hour % 12;
  return '$period $display시';
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 402),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
    this.onBack,
    this.action,
    this.iconAction,
    this.onAction,
  });

  final String title;
  final VoidCallback? onBack;
  final String? action;
  final IconData? iconAction;
  final VoidCallback? onAction;

  void _goBack(BuildContext context) {
    _replaceRoot(context, const SettingsFlow());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
      child: Row(
        children: [
          IconButton(
            tooltip: '뒤로 가기',
            onPressed: onBack ?? () => _goBack(context),
            icon: const Icon(Icons.chevron_left, size: 28, color: _dark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: _dark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(54, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else if (iconAction != null)
            IconButton(
              onPressed: onAction,
              icon: Icon(iconAction, color: _brown, size: 20),
            )
          else
            const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(title),
        _SectionCard(children: children),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: _line, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _rowTitle()),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: _tiny()),
                  ],
                ],
              ),
            ),
            if (badge != null)
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _yellow,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: _brown,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsNavBar extends StatelessWidget {
  const _SettingsNavBar({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, '홈', false, 0),
      (Icons.chat_bubble_outline, '대화', false, 1),
      (Icons.image_outlined, '추억', false, 2),
      (Icons.settings_outlined, '설정', true, 3),
    ];

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(shadow: true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: item.$3 ? null : () => onSelected(item.$4),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 20,
                        color: item.$3 ? _yellow : _muted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 9,
                          color: item.$3 ? _brown : _muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Text(row.$1, style: _tiny()),
                  const Spacer(),
                  Text(
                    row.$2,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _dark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({required this.rows});
  final List<_SwitchData> rows;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      children: rows
          .map(
            (row) => _SwitchLine(
              title: row.title,
              subtitle: row.subtitle,
              value: row.value,
              onChanged: row.onChanged,
            ),
          )
          .toList(),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            _IconBox(icon: icon!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _rowTitle()),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: _tiny()),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _brown,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE2D8CE),
          ),
        ],
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.title,
    required this.names,
    required this.values,
    required this.onChanged,
  });
  final String title;
  final List<String> names;
  final Map<String, bool> values;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(title),
        _SectionCard(
          children: names
              .map(
                (name) => _SwitchLine(
                  icon: _notificationIcon(name),
                  title: _notificationDisplayName(name),
                  subtitle: _notificationSubtitle(name),
                  value: values[name] ?? false,
                  onChanged: (v) => onChanged(name, v),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }
}

IconData _notificationIcon(String name) {
  if (name.contains('리포트')) return Icons.show_chart;
  if (name.contains('약')) return Icons.medication_outlined;
  if (name.contains('연결')) return Icons.wifi_off;
  if (name.contains('음성') || name.contains('목소리')) return Icons.mic_none;
  if (name.contains('메시지')) return Icons.volume_up_outlined;
  return Icons.notifications_none;
}

String _notificationSubtitle(String name) {
  return switch (name) {
    '감정 변화' => '평소와 다른 부정 감정 1시간 이상',
    '기기 연결 해제' => '인형이 끊겼을 때',
    '약 미복용' => '알림 후 10분 내 확인 안 됨',
    '어머님 음성 요청' => '가족과 이야기하고 싶다고 하실 때',
    '메시지 전달 완료' => '인형이 ${SessionStore.elderHonorific}께 읽어드렸을 때',
    '목소리 학습 완료' => '내 목소리 클로닝이 끝났을 때',
    '데일리 리포트' => '매일 아침 7시',
    '주간 리포트' => '매주 월요일 아침',
    _ => '새 기능 안내',
  };
}

String _notificationDisplayName(String name) {
  if (name == '어머님 음성 요청') {
    return '${SessionStore.elderHonorific} 음성 요청';
  }
  return name;
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.trailing,
    this.onChanged,
    this.enabled = true,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          TextField(
            controller: controller,
            onChanged: onChanged,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              // 비활성 필드도 흰 배경/테두리를 유지한다.
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _line),
              ),
              suffixIcon: trailing == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: trailing,
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _brown),
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: _dark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8EFE8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _brown : _line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: selected ? _brown : _dark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DateStepper extends StatelessWidget {
  const _DateStepper({
    required this.year,
    required this.month,
    required this.day,
    required this.onYear,
    required this.onMonth,
    required this.onDay,
  });
  final int year;
  final int month;
  final int day;
  final ValueChanged<int> onYear;
  final ValueChanged<int> onMonth;
  final ValueChanged<int> onDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _DateWheelColumn(
            values: List.generate(
              DateTime.now().year - 1899,
              (index) => 1900 + index,
            ),
            selectedValue: year,
            suffix: '년',
            onChanged: onYear,
          ),
          const SizedBox(width: 8),
          _DateWheelColumn(
            values: List.generate(12, (index) => index + 1),
            selectedValue: month,
            suffix: '월',
            onChanged: onMonth,
          ),
          const SizedBox(width: 8),
          _DateWheelColumn(
            values: List.generate(
              _daysInMonth(year, month),
              (index) => index + 1,
            ),
            selectedValue: day,
            suffix: '일',
            onChanged: onDay,
          ),
        ],
      ),
    );
  }
}

class _DateWheelColumn extends StatefulWidget {
  const _DateWheelColumn({
    required this.values,
    required this.selectedValue,
    required this.suffix,
    required this.onChanged,
  });

  final List<int> values;
  final int selectedValue;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  State<_DateWheelColumn> createState() => _DateWheelColumnState();
}

class _DateWheelColumnState extends State<_DateWheelColumn> {
  late FixedExtentScrollController _controller;

  int get _selectedIndex => widget.values
      .indexOf(widget.selectedValue)
      .clamp(0, widget.values.length - 1);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant _DateWheelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.hasClients &&
        (oldWidget.selectedValue != widget.selectedValue ||
            oldWidget.values.length != widget.values.length)) {
      _controller.jumpToItem(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _moveBy(int offset) async {
    final target = (_selectedIndex + offset).clamp(0, widget.values.length - 1);
    if (target == _selectedIndex || !_controller.hasClients) return;
    await _controller.animateToItem(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: IconButton(
                tooltip: '이전 값',
                onPressed: _selectedIndex > 0 ? () => _moveBy(-1) : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                color: _brown,
                disabledColor: _line,
              ),
            ),
            Center(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EFE8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _line),
                ),
              ),
            ),
            Positioned.fill(
              top: 34,
              bottom: 34,
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 42,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                overAndUnderCenterOpacity: 0.4,
                onSelectedItemChanged: (index) {
                  widget.onChanged(widget.values[index]);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, index) => Center(
                    child: Text(
                      '${widget.values[index]}${widget.suffix}',
                      style: TextStyle(
                        fontSize: 16,
                        color: index == _selectedIndex
                            ? _brown
                            : const Color(0xFFC1ADA1),
                        fontWeight: index == _selectedIndex
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: IconButton(
                tooltip: '다음 값',
                onPressed: _selectedIndex < widget.values.length - 1
                    ? () => _moveBy(1)
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                color: _brown,
                disabledColor: _line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourStepper extends StatelessWidget {
  const _HourStepper({
    required this.hour,
    required this.onAdd,
    required this.onSub,
  });
  final int hour;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onSub,
          icon: const Icon(Icons.keyboard_arrow_up, color: _brown),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -100) {
              onAdd();
            } else if (velocity > 100) {
              onSub();
            }
          },
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _brown.withValues(alpha: .35)),
            ),
            child: Text(
              _hourText(hour),
              style: const TextStyle(
                fontSize: 14,
                color: _brown,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.keyboard_arrow_down, color: _brown),
        ),
      ],
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.text,
    required this.onAdd,
    required this.onSub,
  });
  final String text;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onSub,
          icon: const Icon(Icons.keyboard_arrow_up, color: _brown),
        ),
        Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8EFE8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _brown.withValues(alpha: .35)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: _brown,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.keyboard_arrow_down, color: _brown),
        ),
      ],
    );
  }
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.name,
    required this.subtitle,
    this.checked = false,
    this.progress,
    this.onTap,
  });
  final String name;
  final String subtitle;
  final bool checked;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconBox(
              icon: Icons.mic_none,
              fill: checked ? _brown : const Color(0xFFF8EFE8),
              iconColor: checked ? Colors.white : _brown,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: _rowTitle()),
                  Text(subtitle, style: _tiny()),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      color: _yellow,
                      backgroundColor: _line,
                    ),
                  ],
                ],
              ),
            ),
            if (checked) const Icon(Icons.check_circle, color: _brown),
          ],
        ),
      ),
    );
  }
}

class _VolumePreset extends StatelessWidget {
  const _VolumePreset({
    required this.percent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final int percent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EFE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$percent',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _brown,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _rowTitle()),
                  Text(subtitle, style: _tiny()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    required this.name,
    required this.role,
    this.badges = const [],
    this.onLongPress,
  });
  final String name;
  final String role;
  final List<String> badges;

  /// 주보호자가 이 가족을 제거할 수 있을 때만 지정된다.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _Avatar(label: _initial(name), size: 40, color: _brown),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: _rowTitle()),
                      const SizedBox(width: 6),
                      for (final badge in badges)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3D2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 8,
                                color: _brown,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(role, style: _tiny()),
                ],
              ),
            ),
            if (onLongPress != null)
              const Icon(Icons.chevron_right, color: _muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.med, required this.onDelete});
  final Medication med;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _IconBox(
            icon: Icons.medication_outlined,
            fill: const Color(0xFFFFF3D2),
            iconColor: _yellow,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: _rowTitle()),
                const SizedBox(height: 3),
                Text(
                  '${med.time} · ${med.timing}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _brown,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: _muted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      alignment: Alignment.center,
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: _tiny()),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              color: _brown,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableProfilePhoto extends StatelessWidget {
  const _EditableProfilePhoto({
    required this.label,
    required this.imageBytes,
    required this.onChanged,
  });

  final String label;
  final Uint8List? imageBytes;
  final ValueChanged<Uint8List> onChanged;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    onChanged(await picked.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 78,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _brown,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: imageBytes == null
                    ? Text(
                        label,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                        width: 78,
                        height: 78,
                      ),
              ),
              const Positioned(
                right: -2,
                bottom: -2,
                child: _SmallCircleButton(icon: Icons.image_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '사진 바꾸기',
            style: TextStyle(
              fontSize: 11,
              color: _brown,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.size, required this.color});
  final String label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * .42,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallCircleButton extends StatelessWidget {
  const _SmallCircleButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 13,
      backgroundColor: Colors.white,
      child: Icon(icon, color: _brown, size: 14),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    this.fill = const Color(0xFFF8EFE8),
    this.iconColor = _brown,
  });
  final IconData icon;
  final Color fill;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: _muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 3,
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFC7B8AE),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _SwitchData {
  const _SwitchData(this.title, this.subtitle, this.value, this.onChanged);
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

TextStyle _rowTitle() =>
    const TextStyle(fontSize: 13, color: _dark, fontWeight: FontWeight.w900);

TextStyle _caption() => const TextStyle(
  fontSize: 12,
  color: _muted,
  fontWeight: FontWeight.w700,
  height: 1.55,
);

TextStyle _tiny() => const TextStyle(
  fontSize: 10,
  color: _muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);

ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: _brown,
  foregroundColor: Colors.white,
  elevation: 0,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
);

ButtonStyle _softButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFF1E4D9),
  foregroundColor: _brown,
  elevation: 0,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
);

BoxDecoration _cardDecoration({
  Color color = Colors.white,
  bool shadow = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _line),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}
