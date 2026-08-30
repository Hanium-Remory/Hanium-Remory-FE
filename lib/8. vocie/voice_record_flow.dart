import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

import '../main_shell.dart';
import '../services/settings_api.dart';

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
  final SettingsApi _api = SettingsApi();

  int _step = 0;
  int _recordedSeconds = 0;

  /// 안내 문구에 쓸 어르신 이름. 못 받으면 문구에서 이름을 뺀다.
  String? _elderName;

  @override
  void initState() {
    super.initState();
    _loadElderName();
  }

  Future<void> _loadElderName() async {
    try {
      final elder = (await _api.myProfile()).mainUser;
      if (mounted) setState(() => _elderName = elder?.name);
    } catch (_) {
      // 이름이 없어도 녹음은 할 수 있다.
    }
  }

  // 실제 녹음(record 패키지)이 붙으면 이 경로가 채워진다. 지금은 항상 null 이라
  // 서버 업로드를 건너뛴다. 경로만 들어오면 아래 업로드→폴링이 그대로 동작한다.
  Uint8List? _recordedAudio;
  int? _voiceId;
  bool _busy = false;
  // 학습 상태: idle | training | ready | failed | timeout
  String _enroll = 'idle';
  String? _enrollError;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

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
    _poll?.cancel();
    setState(() {
      _step = 1;
      _enroll = 'idle';
      _enrollError = null;
      _voiceId = null;
    });
  }

  void _finishRecording(int seconds, Uint8List audio) {
    setState(() {
      _recordedSeconds = seconds;
      _recordedAudio = audio;
      _step = 2;
    });
  }

  // 확인 화면 '완료' → 녹음 파일을 백엔드에 업로드하고 학습 상태를 폴링한다.
  Future<void> _uploadAndPoll() async {
    if (_busy) return;
    final audio = _recordedAudio;
    if (audio == null || audio.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('녹음 파일이 없어요. 다시 녹음해 주세요.')));
      return;
    }
    setState(() => _busy = true);
    try {
      // 내 계정에 실제로 연결된 인형을 조회한다(deviceId 하드코딩 대신).
      final profile = await _api.myProfile();
      final deviceId = profile.mainUser?.deviceId;
      if (deviceId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결된 인형이 없어요. 인형을 먼저 등록해 주세요.')),
        );
        return;
      }
      final voice = await _api.registerVoiceBytes(
        deviceId,
        name: '가족 음성',
        bytes: audio,
      );
      if (!mounted) return;
      _voiceId = voice.voiceId;
      setState(() => _enroll = 'training');
      _next(); // 완료(학습 중) 화면으로
      _startPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('음성 등록 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('음성 등록 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 학습 상태를 5초마다 조회. ready/failed 면 멈추고, 10분이면 타임아웃 처리.
  void _startPolling() {
    _poll?.cancel();
    final started = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 5), (t) async {
      final id = _voiceId;
      if (id == null) {
        t.cancel();
        return;
      }
      if (DateTime.now().difference(started) > const Duration(minutes: 10)) {
        t.cancel();
        if (mounted) setState(() => _enroll = 'timeout');
        return;
      }
      try {
        final s = await _api.voiceStatus(id);
        if (!mounted) {
          t.cancel();
          return;
        }
        if (s.isReady) {
          t.cancel();
          setState(() => _enroll = 'ready');
        } else if (s.isFailed) {
          t.cancel();
          setState(() {
            _enroll = 'failed';
            _enrollError = s.errorMessage;
          });
        }
      } catch (_) {
        // 일시적 네트워크 오류는 다음 주기에 재시도.
      }
    });
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      VoiceIntroScreen(onStart: _next, elderName: _elderName),
      VoiceRecordingScreen(
        onBack: _back,
        onDone: _finishRecording,
        scriptIndex: 0,
      ),
      VoiceCheckScreen(
        onBack: _back,
        onRetry: _restartRecording,
        onComplete: _uploadAndPoll,
        durationSeconds: _recordedSeconds,
        audio: _recordedAudio ?? Uint8List(0),
      ),
      VoiceCompleteScreen(
        onBack: _back,
        onConfirm: _goHome,
        status: _enroll,
        errorMessage: _enrollError,
        onRetry: _restartRecording,
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: pages[_step],
    );
  }
}

class VoiceIntroScreen extends StatelessWidget {
  const VoiceIntroScreen({super.key, required this.onStart, this.elderName});

  final VoidCallback onStart;

  /// 연결된 어르신 이름. 아직 못 받았으면 null.
  final String? elderName;

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
                          '어머! 우리 딸\n목소리네',
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
                  elderName == null
                      ? '이 목소리로 인형이\n이야기해요'
                      : '이 목소리로 인형이\n$elderName님과 이야기해요',
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
  final void Function(int seconds, Uint8List audio) onDone;
  final int scriptIndex;

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  // 스트리밍 녹음은 PCM 만 지원한다. WAV 로 요청하면 안드로이드 쪽에서
  // "Path not provided. Stream is not supported." 로 시작부터 실패한다.
  // 그래서 PCM 으로 받아 두고, 저장할 때 WAV 헤더를 직접 붙인다.
  static const _sampleRate = 44100;
  static const _numChannels = 1;

  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _audioBytes = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// 파형 막대에 쓰는 최근 입력 크기(0~1). 오래된 것부터 밀려난다.
  final List<double> _levels = [];
  Completer<void>? _audioDone;
  Timer? _timer;
  int _seconds = 0;
  int _scriptIndex = 0;
  bool _isRecording = false;
  bool _isStopping = false;
  String? _recordingError;

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
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSubscription?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    if (_isRecording) unawaited(_recorder.cancel());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final allowed = await _recorder.hasPermission();
      if (!allowed) {
        if (mounted) setState(() => _recordingError = '마이크 권한이 필요합니다.');
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _numChannels,
        ),
      );
      _audioDone = Completer<void>();
      _audioSubscription = stream.listen(
        _audioBytes.add,
        onError: (Object error) {
          if (!(_audioDone?.isCompleted ?? true)) _audioDone!.complete();
          if (mounted) setState(() => _recordingError = '녹음 중 오류가 발생했습니다.');
        },
        onDone: () {
          if (!(_audioDone?.isCompleted ?? true)) _audioDone!.complete();
        },
      );
      if (!mounted) return;
      setState(() => _isRecording = true);

      // 마이크로 들어오는 크기를 받아 파형을 실제로 움직인다.
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
            if (!mounted) return;
            // current 는 dBFS(-160~0). 사람 말소리는 대체로 -45dB 위에 걸린다.
            final level = ((amplitude.current + 45) / 45).clamp(0.0, 1.0);
            setState(() {
              _levels.add(level);
              if (_levels.length > kWaveformBars) _levels.removeAt(0);
            });
          });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= 300) _stopRecording();
      });
    } catch (error) {
      if (mounted) setState(() => _recordingError = '마이크를 시작할 수 없습니다: $error');
    }
  }

  /// 16비트 PCM 앞에 44바이트 WAV(RIFF) 헤더를 붙인다.
  Uint8List _wavFromPcm16(Uint8List pcm) {
    const headerSize = 44;
    const bitsPerSample = 16;
    final byteRate = _sampleRate * _numChannels * bitsPerSample ~/ 8;
    final blockAlign = _numChannels * bitsPerSample ~/ 8;

    final out = Uint8List(headerSize + pcm.length);
    final view = ByteData.view(out.buffer);

    void ascii(int offset, String tag) {
      for (var i = 0; i < tag.length; i++) {
        out[offset + i] = tag.codeUnitAt(i);
      }
    }

    ascii(0, 'RIFF');
    view.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    view.setUint32(16, 16, Endian.little); // fmt 청크 길이
    view.setUint16(20, 1, Endian.little); // 1 = PCM
    view.setUint16(22, _numChannels, Endian.little);
    view.setUint32(24, _sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, blockAlign, Endian.little);
    view.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    view.setUint32(40, pcm.length, Endian.little);

    out.setRange(headerSize, out.length, pcm);
    return out;
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isStopping) return;
    setState(() => _isStopping = true);
    _timer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
      await _audioDone?.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _audioSubscription?.cancel();
      final audio = _audioBytes.takeBytes();
      if (!mounted) return;
      if (audio.isEmpty) {
        setState(() {
          _isStopping = false;
          _recordingError = '녹음된 소리가 없어요. 다시 시도해 주세요.';
        });
        return;
      }
      _isRecording = false;
      // 서버에는 .wav 로 올라간다. 헤더 없는 PCM 을 그대로 보내면 못 읽는다.
      widget.onDone(_seconds, _wavFromPcm16(audio));
    } catch (error) {
      if (mounted) {
        setState(() {
          _isStopping = false;
          _recordingError = '녹음을 저장하지 못했습니다: $error';
        });
      }
    }
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
              if (_recordingError != null) ...[
                Text(
                  _recordingError!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: _Waveform(
                      active: _isRecording,
                      levels: _levels,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    height: 54.h,
                    child: ElevatedButton.icon(
                      onPressed: _isRecording && !_isStopping
                          ? _stopRecording
                          : null,
                      icon: Icon(Icons.stop, size: 13.sp),
                      label: Text(_isStopping ? '저장 중' : '끝내기'),
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
    required this.audio,
  });

  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onComplete;
  final int durationSeconds;

  /// 방금 녹음한 WAV. 여기서 그대로 재생한다.
  final Uint8List audio;

  @override
  State<VoiceCheckScreen> createState() => _VoiceCheckScreenState();
}

class _VoiceCheckScreenState extends State<VoiceCheckScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // 끝까지 재생되면 버튼을 다시 '재생' 으로 돌린다.
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    unawaited(_completeSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.audio.isEmpty) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
      // 멈춘 지점부터 이어 듣고, 처음이거나 끝났으면 새로 재생한다.
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(BytesSource(widget.audio));
      }
      if (mounted) setState(() => _isPlaying = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재생하지 못했어요: $error')),
      );
    }
  }

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
                      onTap: _togglePlay,
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
                          _Waveform(active: _isPlaying),
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
                      child: const Text(
                        '다시 녹음',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
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
    this.status = 'idle',
    this.errorMessage,
    this.onRetry,
  });

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  /// 학습 상태: idle | training | ready | failed | timeout
  final String status;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = status == 'failed';
    final ready = status == 'ready';
    final timeout = status == 'timeout';

    final title = failed
        ? '학습에 실패했어요'
        : ready
        ? '학습이 끝났어요'
        : '잘 보냈어요';

    final body = failed
        ? (errorMessage != null && errorMessage!.isNotEmpty
              ? errorMessage!
              : '다시 한 번 녹음해 주세요.')
        : ready
        ? '이제 인형이 이 목소리로 이야기해요.'
        : timeout
        ? '학습이 아직 진행 중이에요.\n조금 뒤 인형 앱에서 확인해 주세요.'
        : '내 목소리를 인형이 학습하는 데 몇 분 정도가 걸려요.\n다 끝나면 인형 앱으로 알려드릴게요.';

    final chip = failed
        ? '다시 녹음이 필요해요'
        : ready
        ? '내 목소리 준비 완료'
        : timeout
        ? '학습이 진행 중이에요'
        : '이제 내 목소리를 배우는 중이에요';

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
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(body, textAlign: TextAlign.center, style: _body()),
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
                  child: Text(chip, style: _tiny(color: _brown)),
                ),
              ),
              const Spacer(),
              if (failed && onRetry != null) ...[
                _BottomButton(text: '다시 녹음하기', onTap: onRetry!),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: onConfirm,
                  child: Text('나중에 할게요', style: _tiny(color: _muted)),
                ),
              ] else
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
          IconButton(
            tooltip: '뒤로 가기',
            onPressed:
                onBack ??
                () => Navigator.of(context, rootNavigator: true)
                    .pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainShell(),
                      ),
                      (_) => false,
                    ),
            icon: Icon(Icons.chevron_left, size: 28.sp, color: _dark),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 44.w, minHeight: 40.h),
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

/// 파형 막대 개수. 녹음 화면이 이 개수만큼만 최근 값을 들고 있는다.
const int kWaveformBars = 22;

class _Waveform extends StatefulWidget {
  const _Waveform({required this.active, this.levels});

  /// 녹음 중이거나 재생 중이면 true.
  final bool active;

  /// 0~1 로 정규화된 최근 입력 크기. 비어 있으면 스스로 움직인다.
  final List<double>? levels;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  /// 막대마다 다른 높이를 주기 위한 기준 높이.
  static const List<double> _idle = [
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

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 마이크 값이 없는데 재생 중이면 파형을 시간에 따라 흔든다.
  bool get _shouldAnimate =>
      widget.active && (widget.levels == null || widget.levels!.isEmpty);

  @override
  void initState() {
    super.initState();
    if (_shouldAnimate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 막대를 왼쪽에서 오른쪽으로 흐르는 파도처럼 만든다.
  double _animated(int i, double t) {
    final wave = (math.sin((t - i * 0.06) * 2 * math.pi) + 1) / 2;
    return 4.0 + (_idle[i] - 4.0) * (0.25 + 0.75 * wave);
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.levels;
    final hasLive = live != null && live.isNotEmpty;

    return SizedBox(
      height: 48.h,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // 녹음 중이면 실제 입력 크기로, 재생 중이면 파도로, 아니면 고정 막대로 그린다.
          final bars = hasLive
              ? [
                  // 최근 값이 오른쪽에 오도록 왼쪽을 낮은 값으로 채운다.
                  for (var i = 0; i < kWaveformBars - live.length; i++) 4.0,
                  for (final level in live) 4.0 + level * 36.0,
                ]
              : [
                  for (var i = 0; i < kWaveformBars; i++)
                    _shouldAnimate ? _animated(i, _controller.value) : _idle[i],
                ];

          return Row(
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
                        color: widget.active || i < 11
                            ? _brown
                            : const Color(0xFFE9DED3),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
