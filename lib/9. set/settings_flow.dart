import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../5. memory/memory_add_flow.dart';
import '../6. chat/family_chat_screen.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);
const Color _green = Color(0xFF5D9E41);

class SettingsFlow extends StatelessWidget {
  const SettingsFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsHubScreen();
  }
}

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          const Text(
            '설정',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _dark,
            ),
          ),
          SizedBox(height: 18.h),
          GestureDetector(
            onTap: () => _push(context, const MyProfileScreen()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const _Avatar(label: '김', size: 50, color: _brown),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '김지영',
                          style: TextStyle(
                            fontSize: 15,
                            color: _dark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '딸 · 010-1234-5678',
                          style: TextStyle(
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
          _Section(
            title: '돌봄',
            children: [
              _MenuRow(
                icon: Icons.sentiment_satisfied_alt,
                title: '모리 인형 설정',
                subtitle: '목소리, 볼륨, 베어링',
                onTap: () => _push(context, const DollSettingsScreen()),
              ),
              _MenuRow(
                icon: Icons.person_outline,
                title: '박순자님 정보',
                subtitle: '이름, 생년월일, 좋아하는 것들 등',
                onTap: () => _push(context, const ElderInfoScreen()),
              ),
              _MenuRow(
                icon: Icons.groups_outlined,
                title: '가족 멤버',
                subtitle: '3명 연결됨',
                badge: '3',
                onTap: () => _push(context, const FamilyMembersScreen()),
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
                onTap: () => _push(context, const NotificationSettingsScreen()),
              ),
              _MenuRow(
                icon: Icons.nightlight_round,
                title: '방해 금지 시간',
                subtitle: '오후 11시 ~ 오전 7시',
                onTap: () => _push(context, const QuietHoursScreen()),
              ),
              _MenuRow(
                icon: Icons.medication_outlined,
                title: '약 복용 시간',
                subtitle: '하루 2번',
                onTap: () => _push(context, const MedicationTimeScreen()),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _Section(
            title: '계정',
            children: const [
              _MenuRow(
                icon: Icons.shield_outlined,
                title: '개인정보 및 보안',
                subtitle: '',
              ),
              _MenuRow(
                icon: Icons.info_outline,
                title: 'ReMory 정보',
                subtitle: '버전 1.0.2',
              ),
            ],
          ),
          const Spacer(),
          const _SettingsNavBar(),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool urgent = true;
  bool daily = true;
  bool chat = true;
  bool marketing = false;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '내 프로필',
            action: '편집',
            onAction: () => _push(context, const MyProfileEditScreen()),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 22.h),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: const [
                      _Avatar(label: '김', size: 78, color: _brown),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: _SmallCircleButton(icon: Icons.add),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                const Text(
                  '김지영',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('박순자의 딸', textAlign: TextAlign.center, style: _tiny()),
                SizedBox(height: 28.h),
                _Label('기본 정보'),
                const _InfoCard(
                  rows: [('이름', '김지영'), ('전화번호', '010-1234-5678'), ('관계', '딸')],
                ),
                SizedBox(height: 16.h),
                _Label('내가 받는 알림'),
                _SwitchCard(
                  rows: [
                    _SwitchData(
                      '긴급 알림',
                      '감정 변화, 기기 연결 등',
                      urgent,
                      (v) => setState(() => urgent = v),
                    ),
                    _SwitchData(
                      '데일리 리포트',
                      '매일 아침 7시',
                      daily,
                      (v) => setState(() => daily = v),
                    ),
                    _SwitchData(
                      '대화 알림',
                      '박순자님이 말씀하실 때',
                      chat,
                      (v) => setState(() => chat = v),
                    ),
                    _SwitchData(
                      '마케팅 알림',
                      '신기능 안내',
                      marketing,
                      (v) => setState(() => marketing = v),
                    ),
                  ],
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

class MyProfileEditScreen extends StatefulWidget {
  const MyProfileEditScreen({super.key});

  @override
  State<MyProfileEditScreen> createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  final name = TextEditingController(text: '김지영');
  final phone = TextEditingController(text: '010-1234-5678');
  Uint8List? photoBytes;
  String relation = '딸';

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '프로필 편집',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 18.h),
                Center(
                  child: _EditableProfilePhoto(
                    label: '김',
                    imageBytes: photoBytes,
                    onChanged: (bytes) => setState(() => photoBytes = bytes),
                  ),
                ),
                SizedBox(height: 24.h),
                _InputField(label: '이름', controller: name),
                _InputField(
                  label: '전화번호',
                  controller: phone,
                  keyboardType: TextInputType.phone,
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
                  children: ['딸', '아들', '며느리', '사위', '손주', '기타'].map((item) {
                    return _ChoiceChipButton(
                      text: item,
                      selected: relation == item,
                      onTap: () => setState(() => relation = item),
                    );
                  }).toList(),
                ),
                SizedBox(height: 64.h),
                Center(
                  child: Text(
                    '회원 탈퇴',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

class DollSettingsScreen extends StatelessWidget {
  const DollSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          const _TopHeader(title: '인형 설정'),
          Expanded(
            child: ListView(
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
                        child: Icon(
                          Icons.smart_toy_outlined,
                          size: 56,
                          color: _brown,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      const Text(
                        '모리',
                        style: TextStyle(
                          fontSize: 18,
                          color: _dark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('2026.05.08', style: _tiny()),
                      SizedBox(height: 12.h),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F6D8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          '잘 연결되어 있어요',
                          style: TextStyle(
                            fontSize: 10,
                            color: _green,
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
                          const Text(
                            '78%',
                            style: TextStyle(
                              fontSize: 26,
                              color: _dark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text('약 14시간 남았어요', style: _tiny()),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: const LinearProgressIndicator(
                          value: .78,
                          minHeight: 8,
                          color: _green,
                          backgroundColor: Color(0xFFEAE1D8),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                _Label('인형 목소리'),
                _SectionCard(
                  children: const [
                    _VoiceRow(
                      name: '김지영',
                      subtitle: '딸 · 등록 완료',
                      checked: true,
                    ),
                    _VoiceRow(
                      name: '김민수',
                      subtitle: '아들 · 학습 중...',
                      progress: .52,
                    ),
                    _VoiceRow(name: '기본 목소리', subtitle: '아이 목소리'),
                  ],
                ),
                SizedBox(height: 10.h),
                OutlinedButton.icon(
                  onPressed: () {},
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
                      subtitle: '크게',
                      onTap: () => _push(context, const DollVolumeScreen()),
                    ),
                  ],
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

class DollVolumeScreen extends StatefulWidget {
  const DollVolumeScreen({super.key});

  @override
  State<DollVolumeScreen> createState() => _DollVolumeScreenState();
}

class _DollVolumeScreenState extends State<DollVolumeScreen> {
  double volume = 70;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '인형 볼륨',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text('어머님이 편하게 들으실 수 있는 볼륨으로 맞춰주세요.', style: _caption()),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          '지금 인형으로 들어보기',
                          style: TextStyle(
                            fontSize: 11,
                            color: _brown,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

class ElderInfoScreen extends StatelessWidget {
  const ElderInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '어머님 정보',
            action: '편집',
            onAction: () => _push(context, const ElderInfoEditScreen()),
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
                    children: const [
                      _Avatar(label: '박', size: 62, color: Color(0xFFDCC7B6)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '박순자',
                              style: TextStyle(
                                fontSize: 17,
                                color: _dark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '여성 · 1952년 3월 15일 (만 74세)',
                              style: TextStyle(
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
                const _InfoCard(
                  rows: [('이름', '박순자'), ('성별', '여성'), ('생년월일', '1952년 3월 15일')],
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

class ElderInfoEditScreen extends StatefulWidget {
  const ElderInfoEditScreen({super.key});

  @override
  State<ElderInfoEditScreen> createState() => _ElderInfoEditScreenState();
}

class _ElderInfoEditScreenState extends State<ElderInfoEditScreen> {
  final name = TextEditingController(text: '박순자');
  Uint8List? photoBytes;
  String gender = '여성';
  int year = 1952;
  int month = 3;
  int day = 15;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '프로필 편집',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: 10.h),
                Center(
                  child: _EditableProfilePhoto(
                    label: '박',
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
                              onTap: () => setState(() => gender = item),
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
                  onYear: (v) => setState(() => year += v),
                  onMonth: (v) =>
                      setState(() => month = (month + v).clamp(1, 12)),
                  onDay: (v) => setState(() => day = (day + v).clamp(1, 31)),
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

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '가족 멤버',
            iconAction: Icons.share_outlined,
            onAction: () => _push(context, const FamilyInviteScreen()),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  '박순자님을 함께 돌보는 가족이에요.\n새 가족 초대하기를 눌러 가족과 함께해주세요.',
                  style: _caption(),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: const [
                    Expanded(
                      child: _StatBox(title: '가족', value: '4명'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(title: '목소리', value: '1개'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(title: '생성된 코드', value: '1개'),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _SectionCard(
                  children: const [
                    _FamilyRow(name: '김지영', role: '딸', badges: ['나', '주보호자']),
                    _FamilyRow(name: '김민수', role: '아들'),
                    _FamilyRow(name: '박서연', role: '손녀'),
                    _FamilyRow(name: '김영호', role: '사위'),
                  ],
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
    );
  }
}

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

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final values = <String, bool>{
    '감정 변화': true,
    '기기 연결 해제': true,
    '약 미복용': true,
    '어머님 음성 요청': true,
    '메시지 전달 완료': false,
    '목소리 학습 완료': true,
    '데일리 리포트': true,
    '주간 리포트': true,
    '앱 업데이트': false,
  };

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '알림 설정',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
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
      ),
    );
  }

  void _setValue(String name, bool value) =>
      setState(() => values[name] = value);
}

class QuietHoursScreen extends StatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  State<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends State<QuietHoursScreen> {
  bool enabled = true;
  bool urgent = true;
  bool wake = true;
  int start = 23;
  int end = 7;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '방해 금지 시간',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
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
                      subtitle: '오후 11시 ~ 오전 7시',
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
                              onSub: () =>
                                  setState(() => end = (end + 23) % 24),
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
                      title: '어머님이 "모리야" 부르시면 깨우기',
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
      ),
    );
  }
}

class MedicationTimeScreen extends StatefulWidget {
  const MedicationTimeScreen({super.key});

  @override
  State<MedicationTimeScreen> createState() => _MedicationTimeScreenState();
}

class _MedicationTimeScreenState extends State<MedicationTimeScreen> {
  bool check = true;
  final meds = <_Medication>[
    _Medication('아침 혈압약', '08:00', '식후'),
    _Medication('저녁 영양제', '19:00', '식후'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopHeader(
            title: '약 복용 시간',
            action: '저장',
            onAction: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                Text('설정한 시간에 인형이 약 드실 시간이라고 말씀드려요.', style: _caption()),
                SizedBox(height: 28.h),
                _Label('오늘의 약'),
                for (final med in meds)
                  _MedicationTile(
                    med: med,
                    onDelete: () => setState(() => meds.remove(med)),
                  ),
                TextButton.icon(
                  onPressed: _showAddMedicine,
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
                      onChanged: (v) => setState(() => check = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }

  void _showAddMedicine() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _AddMedicationSheet(onAdd: (med) => setState(() => meds.add(med))),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  const _AddMedicationSheet({required this.onAdd});

  final ValueChanged<_Medication> onAdd;

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final name = TextEditingController();
  int hour = 8;
  int minute = 0;
  String timing = '식후';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = name.text.trim().isNotEmpty;

    return StatefulBuilder(
      builder: (context, setSheetState) {
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
                  onChanged: (_) => setSheetState(() {}),
                ),
                _Label('시간'),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NumberStepper(
                          text: '오전 ${hour.toString().padLeft(2, '0')}시',
                          onAdd: () =>
                              setSheetState(() => hour = (hour % 12) + 1),
                          onSub: () => setSheetState(
                            () => hour = hour == 1 ? 12 : hour - 1,
                          ),
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
                          onAdd: () =>
                              setSheetState(() => minute = (minute + 5) % 60),
                          onSub: () =>
                              setSheetState(() => minute = (minute + 55) % 60),
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
                              onTap: () => setSheetState(() => timing = item),
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
                            ? () {
                                widget.onAdd(
                                  _Medication(
                                    name.text.trim(),
                                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                                    timing,
                                  ),
                                );
                                Navigator.pop(context);
                              }
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
      },
    );
  }
}

void _push(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
    this.action,
    this.iconAction,
    this.onAction,
  });

  final String title;
  final String? action;
  final IconData? iconAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 30,
              height: 30,
              child: Icon(Icons.chevron_left, size: 24, color: _dark),
            ),
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
  const _SettingsNavBar();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, '홈', false),
      (Icons.chat_bubble_outline, '대화', false),
      (Icons.image_outlined, '추억', false),
      (Icons.settings_outlined, '설정', true),
    ];

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(shadow: true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (item.$2 == '홈') Navigator.maybePop(context);
                if (item.$2 == '대화') _push(context, const FamilyChatScreen());
                if (item.$2 == '추억') _push(context, const MemoryAddFlow());
              },
              child: SizedBox(
                width: 52,
                height: 54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$1, size: 20, color: item.$3 ? _yellow : _muted),
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
                  title: name,
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
    '메시지 전달 완료' => '인형이 어머님께 읽어드렸을 때',
    '목소리 학습 완료' => '내 목소리 클로닝이 끝났을 때',
    '데일리 리포트' => '매일 아침 7시',
    '주간 리포트' => '매주 월요일 아침',
    _ => '새 기능 안내',
  };
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.trailing,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

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
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
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
          _StepperColumn(
            value: '$year년',
            onAdd: () => onYear(1),
            onSub: () => onYear(-1),
          ),
          const SizedBox(width: 8),
          _StepperColumn(
            value: '$month월',
            onAdd: () => onMonth(1),
            onSub: () => onMonth(-1),
          ),
          const SizedBox(width: 8),
          _StepperColumn(
            value: '$day일',
            onAdd: () => onDay(1),
            onSub: () => onDay(-1),
          ),
        ],
      ),
    );
  }
}

class _StepperColumn extends StatelessWidget {
  const _StepperColumn({
    required this.value,
    required this.onAdd,
    required this.onSub,
  });
  final String value;
  final VoidCallback onAdd;
  final VoidCallback onSub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          IconButton(
            onPressed: onSub,
            icon: const Icon(Icons.keyboard_arrow_up, color: _brown),
          ),
          Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8EFE8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _line),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
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
        Container(
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
  });
  final String name;
  final String subtitle;
  final bool checked;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  });
  final String name;
  final String role;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          _Avatar(
            label: name.substring(0, 1),
            size: 40,
            color: name.contains('박') ? _green : _brown,
          ),
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
          const Icon(Icons.chevron_right, color: _muted, size: 18),
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({required this.med, required this.onDelete});
  final _Medication med;
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

class _Medication {
  _Medication(this.name, this.time, this.timing);
  final String name;
  final String time;
  final String timing;
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
