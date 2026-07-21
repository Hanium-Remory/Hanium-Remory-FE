import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../4. home/home_and_alert_center.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _softYellow = Color(0xFFFFF3D2);

class VoiceRecordFlow extends StatefulWidget {
  const VoiceRecordFlow({super.key});

  @override
  State<VoiceRecordFlow> createState() => _VoiceRecordFlowState();
}

class _VoiceRecordFlowState extends State<VoiceRecordFlow> {
  int _step = 0;
  int _recordedSeconds = 0;

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _restartRecording() {
    setState(() => _step = 1);
  }

  void _finishRecording(int seconds) {
    setState(() {
      _recordedSeconds = seconds;
      _step = 2;
    });
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      VoiceIntroScreen(onStart: _next),
      VoiceRecordingScreen(
        onBack: _back,
        onDone: _finishRecording,
        scriptIndex: 0,
      ),
      VoiceCheckScreen(
        onBack: _back,
        onRetry: _restartRecording,
        onComplete: _next,
        durationSeconds: _recordedSeconds,
      ),
      VoiceCompleteScreen(onBack: _back, onConfirm: _goHome),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: pages[_step],
    );
  }
}

class VoiceIntroScreen extends StatelessWidget {
  const VoiceIntroScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _PhonePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              const _Header(title: '내 목소리 등록'),
              const Spacer(),
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 48.r,
                      backgroundColor: const Color(0xFFEFD6C5),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        size: 48.sp,
                        color: _brown,
                      ),
                    ),
                    Positioned(
                      right: -46.w,
                      top: -8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          '아빠! 우리 딸\n목소리네',
                          style: TextStyle(
                            fontSize: 10.sp,
                            height: 1.35,
                            color: _brown,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 42.h),
              Center(
                child: Text(
                  '이 목소리로 인형이\n박순자님과 이야기해요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21.sp,
                    height: 1.28,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Center(
                child: Text(
                  '예시 문장을 읽어주시면 인형이 내 목소리를 학습해서,\n가족들과 골라서 대화하는 것처럼 들려드려요.',
                  textAlign: TextAlign.center,
                  style: _body(),
                ),
              ),
              const Spacer(),
              _TipBox(),
              SizedBox(height: 22.h),
              _BottomButton(text: '녹음 시작하기', onTap: onStart),
              SizedBox(height: 28.h),
              const _HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({
    super.key,
    required this.onBack,
    required this.onDone,
    required this.scriptIndex,
  });

  final VoidCallback onBack;
  final ValueChanged<int> onDone;
  final int scriptIndex;

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  late Timer _timer;
  int _seconds = 0;
  int _scriptIndex = 0;

  static const _scripts = [
    '엄마, 저예요. 오늘은 어떻게 보내셨어요? 점심은 뭐 드셨고요? 따뜻하게 드셔야 해요. 어제 보내드린 영양제는 잘 챙겨 드시고 계시죠? 잊지 마시고요. 저는 오늘 회사에서 회의가 많아서 좀 정신이 없었어요. 점심엔 김치찌개를 먹었는데, 엄마가 끓여주시던 그 맛이 자꾸 생각나더라고요. 다음 주말에 가면 손주도 데려갈게요. 사랑해요, 엄마.',
    '엄마, 작년 가을에 우리 같이 갔던 그 공원 기억나세요? 단풍이 정말 예뻤잖아요. 거기서 도시락도 먹고 사진도 많이 찍었었지요. 엄마가 싸 주신 김밥을 손주가 다섯 개나 먹었잖아요. 햇살이 따뜻하고 바람도 살랑살랑 불어서 참 좋았어요.',
    '엄마, 오늘 아침에는 날씨가 참 맑았어요. 창문을 열어 놓으니 시원한 바람이 들어오더라고요. 엄마도 식사 잘 챙겨 드시고 잠깐 산책해 보세요. 무리하지 마시고 천천히 다녀오세요.',
    '엄마, 이번 주말에는 가족들이 함께 찾아갈게요. 맛있는 것도 준비하고 옛날 사진도 같이 볼까요? 손주가 할머니께 보여드릴 그림을 열심히 그리고 있어요. 곧 만나서 즐겁게 이야기 나눠요.',
  ];

  static const _scriptTitles = ['일상 안부', '옛 추억', '아침 인사', '가족 약속'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final script = _scripts[_scriptIndex];
    final progress = (_seconds / 300).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _PhonePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              _Header(title: '내 목소리 등록', onBack: widget.onBack),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Text('최소 60초까지', style: _caption()),
                  const Spacer(),
                  Text(
                    '${_time(_seconds)} / 05:00',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _brown,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(99.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5.h,
                  backgroundColor: const Color(0xFFE5D7CB),
                  valueColor: const AlwaysStoppedAnimation(_brown),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Text('예시 ${_scriptIndex + 1} / 4', style: _label()),
                  SizedBox(width: 8.w),
                  Text(_scriptTitles[_scriptIndex], style: _label(size: 13.sp)),
                  Container(
                    margin: EdgeInsets.only(left: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: _softYellow,
                      borderRadius: BorderRadius.circular(99.r),
                    ),
                    child: Text('약 2분', style: _tiny(color: _brown)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _scriptIndex = (_scriptIndex + 1) % _scripts.length;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99.r),
                        border: Border.all(color: _line),
                      ),
                      child: Text('다음 글  >', style: _tiny(color: _muted)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _line),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      script,
                      style: TextStyle(
                        fontSize: 17.sp,
                        height: 1.72,
                        color: _dark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _Waveform(active: true)),
                  SizedBox(width: 10.w),
                  SizedBox(
                    height: 54.h,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onDone(_seconds),
                      icon: Icon(Icons.stop, size: 13.sp),
                      label: const Text('끝내기'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE8DCCF),
                        foregroundColor: _brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        textStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              const _HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  String _time(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }
}

class VoiceCheckScreen extends StatefulWidget {
  const VoiceCheckScreen({
    super.key,
    required this.onBack,
    required this.onRetry,
    required this.onComplete,
    required this.durationSeconds,
  });

  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onComplete;
  final int durationSeconds;

  @override
  State<VoiceCheckScreen> createState() => _VoiceCheckScreenState();
}

class _VoiceCheckScreenState extends State<VoiceCheckScreen> {
  bool _isPlaying = false;

  String _time(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _PhonePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              _Header(title: '확인', onBack: widget.onBack),
              SizedBox(height: 42.h),
              Text(
                '잘 녹음되었어요',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_time(widget.durationSeconds)} 동안 녹음됐어요.\n'
                '들어보고 마음에 드시면 인형에게 목소리를 가르쳐주세요.',
                style: _body(),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: _brown,
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 26.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('내 목소리 녹음', style: _label(size: 13.sp)),
                          SizedBox(height: 2.h),
                          Text(
                            '${_time(widget.durationSeconds)} · 방금 전',
                            style: _caption(),
                          ),
                          SizedBox(height: 12.h),
                          _Waveform(active: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 36.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onRetry,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(56.h),
                        foregroundColor: _brown,
                        side: const BorderSide(color: _line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('다시 녹음'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: _BottomButton(
                      text: '이 목소리로\n인형이 말하게 하기',
                      onTap: widget.onComplete,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              const _HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class VoiceCompleteScreen extends StatelessWidget {
  const VoiceCompleteScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _PhonePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              _Header(title: '내 목소리 등록', onBack: onBack),
              const Spacer(),
              Center(child: _SuccessMark()),
              SizedBox(height: 34.h),
              Center(
                child: Text(
                  '잘 보냈어요',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  '내 목소리를 인형이 학습하는 데 몇 분 정도가 걸려요.\n다 끝나면 인형 앱으로 알려드릴게요.',
                  textAlign: TextAlign.center,
                  style: _body(),
                ),
              ),
              SizedBox(height: 18.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99.r),
                    border: Border.all(color: _line),
                  ),
                  child: Text(
                    '이제 내 목소리를 배우는 중이에요',
                    style: _tiny(color: _brown),
                  ),
                ),
              ),
              const Spacer(),
              _BottomButton(text: '알겠어요', onTap: onConfirm),
              SizedBox(height: 22.h),
              const _HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhonePadding extends StatelessWidget {
  const _PhonePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.w),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: SizedBox(
              width: 34.w,
              height: 34.w,
              child: Icon(Icons.chevron_left, size: 25.sp, color: _dark),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
          ),
          SizedBox(width: 34.w),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = ['조용한 곳에서 녹음해주세요', '천천히 또박또박 읽어주세요', '1~3분 정도면 충분해요'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: List.generate(tips.length, (index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13.r,
                  backgroundColor: _softYellow,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _brown,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  tips[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final bars = [
      16.0,
      26.0,
      12.0,
      30.0,
      20.0,
      34.0,
      18.0,
      24.0,
      38.0,
      22.0,
      14.0,
      31.0,
      20.0,
      28.0,
      16.0,
      35.0,
      21.0,
      27.0,
      13.0,
      30.0,
      18.0,
      25.0,
    ];

    return SizedBox(
      height: 48.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < bars.length; i++)
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 3.w,
                  height: bars[i].h,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  decoration: BoxDecoration(
                    color: active || i < 11 ? _brown : const Color(0xFFE9DED3),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132.w,
      height: 132.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFE9B0).withValues(alpha: 0.45),
      ),
      child: Center(
        child: Container(
          width: 106.w,
          height: 106.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFE9B0).withValues(alpha: 0.75),
          ),
          child: Center(
            child: Container(
              width: 84.w,
              height: 84.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF4CF),
              ),
              child: Icon(Icons.check, size: 46.sp, color: _brown),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _brown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 58.w,
        height: 3.h,
        margin: EdgeInsets.only(bottom: 5.h),
        decoration: BoxDecoration(
          color: const Color(0xFFC7B8AE),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

TextStyle _body() {
  return TextStyle(
    fontSize: 12.sp,
    height: 1.55,
    color: _muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _caption() {
  return TextStyle(
    fontSize: 10.sp,
    height: 1.35,
    color: _muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _label({double? size}) {
  return TextStyle(
    fontSize: size ?? 11.sp,
    color: _dark,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _tiny({required Color color}) {
  return TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w800);
}
