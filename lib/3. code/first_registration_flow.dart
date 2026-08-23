import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../4. home/home_and_alert_center.dart';
import '../services/auth_api.dart';
import '../services/session_store.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _soft = Color(0xFFF5E9DF);

// TODO: 백엔드 Passkey/OTP 연동이 준비되면 false로 변경한다.
const bool kBypassPasskeyForDevelopment = false;

class FirstRegistrationFlow extends StatefulWidget {
  const FirstRegistrationFlow({super.key});

  @override
  State<FirstRegistrationFlow> createState() => _FirstRegistrationFlowState();
}

class _FirstRegistrationFlowState extends State<FirstRegistrationFlow> {
  int _page = 0;
  final _inviteCode = '7M92A4';

  final _api = AuthApi();
  bool _busy = false;
  String _busyMsg = '';
  String? _onboardingToken; // Face ID 등록 후 발급, 번호 연결에 사용

  void _next() {
    if (_page < 4) {
      setState(() => _page++);
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() => _page--);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
    );
  }

  void _setBusy(bool busy, [String msg = '']) {
    if (!mounted) return;
    setState(() {
      _busy = busy;
      _busyMsg = msg;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// 1단계: "Face ID로 시작하기" → 번호 없이 패스키 먼저 등록(생체인증).
  /// 성공하면 onboardingToken 저장 후 보호자 정보(전화번호) 페이지로.
  Future<void> _onFaceIdStart() async {
    if (_busy) return;
    if (kBypassPasskeyForDevelopment) {
      _onboardingToken = 'development-bypass';
      _snack('개발 모드: Face ID 등록을 건너뛰었습니다.');
      _next();
      return;
    }
    try {
      _setBusy(true, 'Face ID로 패스키 등록 중…\n생체인증을 진행하세요');
      _onboardingToken = await _api.registerPasskeyFirst(displayName: '보호자');
      _setBusy(false);
      _snack('패스키(Face ID) 등록 완료! 전화번호를 인증해 주세요.');
      _next();
    } catch (e) {
      _setBusy(false);
      _snack('Face ID 등록 실패: $e');
    }
  }

  /// 2단계: 보호자 정보(전화번호) → 인증번호 발송·확인 → 패스키 계정에 번호 연결.
  /// 성공하면 세션 저장(자동 로그인) 후 다음 페이지로.
  Future<void> _onGuardianNext(String phone) async {
    if (_busy) return;
    if (_onboardingToken == null) {
      _snack('먼저 Face ID 등록을 완료해 주세요.');
      return;
    }
    if (phone.trim().length < 9) {
      _snack('전화번호를 확인해 주세요.');
      return;
    }
    if (kBypassPasskeyForDevelopment) {
      _snack('개발 모드: 전화번호 인증을 건너뛰었습니다.');
      _next();
      return;
    }
    try {
      _setBusy(true, '인증번호 발송 중…');
      await _api.sendCode(phone);
      _setBusy(false);

      final code = await _promptOtp(phone);
      if (code == null || code.trim().isEmpty) return; // 취소

      _setBusy(true, '인증번호 확인 중…');
      final result = await _api.attachPhone(
        onboardingToken: _onboardingToken!,
        phone: phone,
        code: code.trim(),
      );
      await SessionStore.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        protectorId: result.protectorId,
      );
      _setBusy(false);
      _snack('전화번호 인증 완료! 가입이 끝났어요.');
      _next();
    } catch (e) {
      _setBusy(false);
      _snack('실패: $e');
    }
  }

  /// 인증번호 입력 다이얼로그. mock SMS는 서버 로그/────/dev 엔드포인트로 확인.
  Future<String?> _promptOtp(String phone) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          '인증번호 입력',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$phone 로 보낸 6자리 번호를 입력하세요.',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              '확인',
              style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _FaceSignupPage(onNext: _onFaceIdStart),
      _GuardianInfoPage(onBack: _back, onNext: _onGuardianNext),
      _PatientInfoPage(onBack: _back, onNext: _next),
      _FamilyConnectPage(onBack: _back, onNext: _next),
      _InviteCodeCreatePage(
        code: _inviteCode,
        onBack: _back,
        onNext: _goToHome,
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: pages[_page],
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    if (_busyMsg.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        _busyMsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhoneScreen extends StatelessWidget {
  const _PhoneScreen({
    required this.child,
    this.title,
    this.onBack,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 34.w),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            SizedBox(
              height: 32.h,
              child: Row(
                children: [
                  if (onBack != null)
                    _IconTap(icon: Icons.chevron_left, onTap: onBack!)
                  else
                    SizedBox(width: 28.w),
                  Expanded(
                    child: Text(
                      title ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                  ),
                  SizedBox(width: 28.w, child: trailing),
                ],
              ),
            ),
            Expanded(child: child),
            Container(
              width: 58.w,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFC7B8AE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceSignupPage extends StatelessWidget {
  const _FaceSignupPage({required this.onNext});

  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          Text('비밀번호 없이\n한 번만 기억해요', style: _titleStyle()),
          SizedBox(height: 10.h),
          Text(
            'Face ID로 안전하게 기억하고,\n다음부터는 자동으로 로그인해요.\n비밀번호를 기억하지 않으셔도 돼요.',
            style: _bodyStyle(),
          ),
          const Spacer(),
          Center(
            child: Icon(Icons.center_focus_weak, size: 70.sp, color: _brown),
          ),
          SizedBox(height: 34.h),
          Center(child: Text('Face ID 버튼을 눌러 시작하세요', style: _smallStyle())),
          const Spacer(),
          _BottomButton(text: 'Face ID로 시작하기', onTap: onNext),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _GuardianInfoPage extends StatefulWidget {
  const _GuardianInfoPage({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final Future<void> Function(String phone) onNext;

  @override
  State<_GuardianInfoPage> createState() => _GuardianInfoPageState();
}

class _GuardianInfoPageState extends State<_GuardianInfoPage> {
  final _nameController = TextEditingController(text: '김기억');
  final _phoneController = TextEditingController(text: '010-1234-5678');
  String _selectedRelation = '딸';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      title: '보호자 정보',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          _StepText(current: 1, total: 2),
          SizedBox(height: 6.h),
          Text('먼저 본인 소개부터 해주세요', style: _sectionTitle()),
          SizedBox(height: 22.h),
          _Label('이름'),
          _TextBox(controller: _nameController, hintText: '이름을 입력하세요'),
          SizedBox(height: 14.h),
          _Label('전화번호'),
          _TextBox(
            controller: _phoneController,
            hintText: '전화번호를 입력하세요',
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 14.h),
          _Label('보호자와의 관계'),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ['딸', '아들', '며느리', '사위', '손주', '기타'].map((relation) {
              return _Choice(
                text: relation,
                selected: _selectedRelation == relation,
                onTap: () => setState(() => _selectedRelation = relation),
              );
            }).toList(),
          ),
          const Spacer(),
          _BottomButton(
            text: '인증하고 계속하기',
            onTap: () => widget.onNext(_phoneController.text),
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _PatientInfoPage extends StatefulWidget {
  const _PatientInfoPage({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_PatientInfoPage> createState() => _PatientInfoPageState();
}

class _PatientInfoPageState extends State<_PatientInfoPage> {
  final _nameController = TextEditingController(text: '박순자');
  String _selectedGender = '여성';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      title: '인형 사용자 정보',
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          _StepText(current: 2, total: 2),
          SizedBox(height: 6.h),
          Text('보호자에 대해 알려주세요', style: _sectionTitle()),
          SizedBox(height: 22.h),
          _Label('이름'),
          _TextBox(controller: _nameController, hintText: '이름을 입력하세요'),
          SizedBox(height: 14.h),
          _Label('성별'),
          Row(
            children: [
              Expanded(
                child: _WideChoice(
                  text: '여성',
                  selected: _selectedGender == '여성',
                  onTap: () {
                    SessionStore.setElderGender('female');
                    setState(() => _selectedGender = '여성');
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _WideChoice(
                  text: '남성',
                  selected: _selectedGender == '남성',
                  onTap: () {
                    SessionStore.setElderGender('male');
                    setState(() => _selectedGender = '남성');
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _Label('생년월일'),
          Container(
            height: 130.h,
            decoration: _boxDecoration(),
            child: Row(
              children: [
                _ScrollDateColumn(
                  values: List.generate(90, (index) => '${1935 + index}년'),
                  initialIndex: 17,
                ),
                _ScrollDateColumn(
                  values: List.generate(12, (index) => '${index + 1}월'),
                  initialIndex: 2,
                ),
                _ScrollDateColumn(
                  values: List.generate(31, (index) => '${index + 1}일'),
                  initialIndex: 14,
                ),
              ],
            ),
          ),
          const Spacer(),
          _BottomButton(text: '다음으로', onTap: widget.onNext),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }
}

class _FamilyConnectPage extends StatelessWidget {
  const _FamilyConnectPage({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  void _goHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      title: '가족 연결',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.h),
          _StepText(current: 3, total: 3),
          SizedBox(height: 6.h),
          Text('가족과 함께 돌봐요', style: _sectionTitle()),
          SizedBox(height: 8.h),
          Text('형제, 자매, 배우자도 함께 사용자의 일상을 챙길 수 있어요.', style: _bodyStyle()),
          SizedBox(height: 30.h),
          _ActionCard(
            icon: Icons.person_add_alt_1,
            title: '내가 가족을 초대할게요',
            subtitle: '초대 코드를 만들어 공유해요',
            onTap: onNext,
          ),
          SizedBox(height: 12.h),
          _ActionCard(
            icon: Icons.home_outlined,
            title: '다음에 할게요',
            subtitle: '나중에 가족들을 초대할게요',
            onTap: () => _goHome(context),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCreatePage extends StatefulWidget {
  const _InviteCodeCreatePage({
    required this.code,
    required this.onBack,
    required this.onNext,
  });

  final String code;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_InviteCodeCreatePage> createState() => _InviteCodeCreatePageState();
}

class _InviteCodeCreatePageState extends State<_InviteCodeCreatePage> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      title: '가족 초대',
      onBack: widget.onBack,
      trailing: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
          );
        },
        child: Text('홈으로', style: _smallStyle()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 88.h),
          Text('이 코드를 가족에게 공유해주세요', style: _sectionTitle()),
          SizedBox(height: 44.h),
          Center(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 28.h),
              decoration: _boxDecoration(shadow: true),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26.r,
                    backgroundColor: const Color(0xFFD9EAF4),
                    child: Text(
                      '이슬',
                      style: TextStyle(
                        color: const Color(0xFF3C7894),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: _copyCode,
                    child: Text(
                      widget.code,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        color: _brown,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    '4시간 동안 유효해요.\n가족이 ReMory 앱에서 이 코드를 입력하면 연결돼요.',
                    textAlign: TextAlign.center,
                    style: _smallStyle(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 44.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _copied
                ? Center(
                    key: const ValueKey('copied'),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 22.w,
                        vertical: 9.h,
                      ),
                      decoration: BoxDecoration(
                        color: _dark,
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        '✓ 초대 코드를 복사했어요',
                        style: _buttonTextStyle(10.sp),
                      ),
                    ),
                  )
                : SizedBox(key: const ValueKey('hidden'), height: 32.h),
          ),
          SizedBox(height: 10.h),
          _BottomButton(text: '복사하기', icon: Icons.copy, onTap: _copyCode),
          SizedBox(height: 10.h),
          _BottomButton(
            text: '공유하기',
            icon: Icons.ios_share,
            pale: true,
            onTap: widget.onNext,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$current / $total 단계',
      style: TextStyle(
        fontSize: 10.sp,
        color: _brown,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: _dark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        cursorColor: _brown,
        style: TextStyle(
          fontSize: 12.sp,
          color: _dark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 12.sp,
            color: const Color(0xFFB9ACA2),
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: _brown),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88.w,
      child: _WideChoice(text: text, selected: selected, onTap: onTap),
    );
  }
}

class _WideChoice extends StatelessWidget {
  const _WideChoice({
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _soft : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: selected ? _brown : _line),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: selected ? _brown : _dark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ScrollDateColumn extends StatefulWidget {
  const _ScrollDateColumn({required this.values, required this.initialIndex});

  final List<String> values;
  final int initialIndex;

  @override
  State<_ScrollDateColumn> createState() => _ScrollDateColumnState();
}

class _ScrollDateColumnState extends State<_ScrollDateColumn> {
  late final FixedExtentScrollController _controller;
  late int _selectedIndex;

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
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 130.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: IconButton(
                tooltip: '이전 값',
                onPressed: _selectedIndex > 0 ? () => _moveBy(-1) : null,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 44.w, height: 28.h),
                icon: Icon(Icons.keyboard_arrow_up, size: 18.sp),
                color: _brown,
                disabledColor: _line,
              ),
            ),
            Center(
              child: Container(
                height: 30.h,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            Positioned.fill(
              top: 22.h,
              bottom: 22.h,
              child: ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 30.h,
                diameterRatio: 1.5,
                overAndUnderCenterOpacity: 0.45,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.values.length,
                  builder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    return Center(
                      child: Text(
                        widget.values[index],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected ? _brown : const Color(0xFFC1ADA1),
                        ),
                      ),
                    );
                  },
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
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 44.w, height: 28.h),
                icon: Icon(Icons.keyboard_arrow_down, size: 18.sp),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: _boxDecoration(shadow: true),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: _brown, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _cardTitle()),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: _smallStyle()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.text,
    required this.onTap,
    this.icon,
    this.pale = false,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool pale;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled
              ? (pale ? const Color(0xFFF1E4D9) : _brown)
              : const Color(0xFFD2C5BC),
          foregroundColor: pale ? _brown : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16.sp),
              SizedBox(width: 5.w),
            ],
            Text(
              text,
              style: pale
                  ? TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: _brown,
                    )
                  : _buttonTextStyle(12.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 28.w,
        height: 28.w,
        child: Icon(icon, color: _dark, size: 21.sp),
      ),
    );
  }
}

TextStyle _titleStyle() {
  return TextStyle(
    fontSize: 23.sp,
    height: 1.25,
    color: _dark,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _sectionTitle() {
  return TextStyle(
    fontSize: 16.sp,
    height: 1.35,
    color: _dark,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _bodyStyle() {
  return TextStyle(
    fontSize: 11.sp,
    height: 1.55,
    color: _muted,
    fontWeight: FontWeight.w500,
  );
}

TextStyle _smallStyle() {
  return TextStyle(
    fontSize: 9.sp,
    height: 1.35,
    color: _muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _cardTitle() {
  return TextStyle(fontSize: 12.sp, color: _dark, fontWeight: FontWeight.w800);
}

TextStyle _buttonTextStyle(double size) {
  return TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
}

BoxDecoration _boxDecoration({bool shadow = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10.r),
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
