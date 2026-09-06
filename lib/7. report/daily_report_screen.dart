import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../4. home/home_and_alert_center.dart'
    show activityStyleOf, activityTitleOf, emotionHeightOf;
import '../main_shell.dart';
import '../services/settings_api.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);

/// 감정 그래프 아래 한 줄. 짚어 줄 것이 없으면 null 이라 칸 자체가 빠진다.
///
/// [emotions] 는 그 날 감정 기록을 오래된 순으로 늘어놓은 것이다.
String? moodCaptionOf(int conversationCount, List<EmotionPoint> emotions) {
  if (emotions.isEmpty) return null;

  // 감정은 표정으로도 읽히므로, 대화가 없어도 기록은 남는다.
  // 그 날을 대화로 설명할 수 없다는 것만 분명히 해 둔다.
  if (conversationCount == 0) {
    return '이 날은 인형과 이야기를 나누지 않으셨어요. 표정으로 읽은 감정만 담겼어요.';
  }

  var best = emotions.first;
  var allSame = true;
  for (final point in emotions) {
    final height = emotionHeightOf(point.emotion);
    if (height != emotionHeightOf(best.emotion)) allSame = false;
    if (height > emotionHeightOf(best.emotion)) best = point;
  }
  // 다 같은 값이면 '가장 좋았던 때' 를 아무 데나 짚는 셈이 된다.
  if (allSame) return '하루 종일 비슷한 상태로 지내셨어요.';

  final at = best.createdAt;
  if (at == null) return null;
  final period = at.hour < 12 ? '오전' : '오후';
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  return '$period $hour시 무렵 기분이 가장 좋으셨어요.';
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final SettingsApi _api = SettingsApi();

  String _name = '';
  DailyReportData? _report;
  /// 그 날의 감정 기록(오래된 순). 그래프도 아래 한 줄 설명도 여기서 나온다.
  List<EmotionPoint> _emotions = [];
  List<ActivityItem> _routine = [];
  bool _loading = true;
  String? _error;

  /// 0 이 가장 최근. 1 씩 늘릴수록 이전 리포트를 본다.
  int _offset = 0;
  int? _userId;

  /// 날짜 이동 중. 화면 전체를 로딩으로 갈아치우지 않으려고 따로 둔다.
  bool _stepping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = (await _api.myProfile()).mainUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = '연결된 어르신이 없어요.\n가족 연결을 먼저 마쳐주세요.';
        });
        return;
      }
      _userId = user.userId;
      final report = await _api.dailyReport(user.userId, offset: _offset);
      final emotions = await _emotionsFor(user.userId, report);
      final routine = await _routineFor(user.userId, report);
      if (!mounted) return;
      setState(() {
        _name = user.name;
        _report = report;
        _emotions = emotions;
        _routine = routine;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = '리포트를 불러오지 못했어요.'; });
      }
    }
  }

  /// 한 칸 이전(delta 1)/이후(delta -1) 리포트로 옮긴다.
  /// 더 없으면 알려주기만 하고 현재 화면을 유지한다.
  Future<void> _step(int delta) async {
    final userId = _userId;
    if (userId == null || _stepping) return;
    final next = _offset + delta;
    if (next < 0) return;

    setState(() => _stepping = true);
    try {
      final report = await _api.dailyReport(userId, offset: next);
      if (!mounted) return;
      if (report == null) {
        setState(() => _stepping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('더 이전 리포트가 없어요.')),
        );
        return;
      }
      final emotions = await _emotionsFor(userId, report);
      final routine = await _routineFor(userId, report);
      if (!mounted) return;
      setState(() {
        _offset = next;
        _report = report;
        _emotions = emotions;
        _routine = routine;
        _stepping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stepping = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('리포트를 불러오지 못했어요: $e')));
    }
  }

  /// 그 리포트가 다루는 날의 감정 기록(오래된 순).
  /// 날짜를 모르는(예전) 리포트는 비워 둔다 — 날짜 없이 받으면 오늘 것이
  /// 섞여 엉뚱한 날의 그래프가 그려진다.
  Future<List<EmotionPoint>> _emotionsFor(
    int userId,
    DailyReportData? report,
  ) async {
    final day = report?.reportDate;
    if (day == null) return [];
    try {
      // 서버가 최신순으로 주므로 그래프 순서에 맞게 뒤집는다.
      return (await _api.emotions(userId, date: day)).reversed.toList();
    } catch (_) {
      // 감정을 못 받아도 리포트 나머지는 보여준다.
      return [];
    }
  }

  /// 그 리포트가 다루는 날의 일과. 날짜를 모르는(예전) 리포트는 비워 둔다 —
  /// 날짜 없이 받으면 오늘 것이 섞여 엉뚱한 날에 붙는다.
  Future<List<ActivityItem>> _routineFor(int userId, DailyReportData? report) async {
    final day = report?.reportDate;
    if (day == null) return [];
    try {
      return await _api.activities(userId, date: day);
    } catch (_) {
      // 일과를 못 받아도 리포트 나머지는 보여준다.
      return [];
    }
  }

  /// 서버가 아직 주지 않는 값이라 자리만 알려준다.
  Widget _notReadyYet(String message) => Padding(
    padding: EdgeInsets.symmetric(vertical: 14.h),
    child: Text(
      message,
      style: TextStyle(fontSize: 12.sp, height: 1.5, color: _muted),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PhoneFrame(
        child: Center(child: CircularProgressIndicator(color: _brown)),
      );
    }
    if (_error != null) {
      return _PhoneFrame(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, height: 1.5, color: _muted),
            ),
          ),
        ),
      );
    }

    final report = _report;
    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          // 만들어진 시각이 아니라 '어느 날의 요약인지' 를 보여준다.
          _Header(
            name: _name,
            at: report?.reportDate ?? report?.createdAt,
            onOlder: () => _step(1),
            onNewer: () => _step(-1),
            canGoNewer: _offset > 0,
            isLatest: _offset == 0,
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: report == null
                ? Center(
                    child: Text(
                      '아직 리포트가 준비되지 않았어요.\n하루가 지나면 만들어져요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 14.h),
                    children: [
                      _SummaryCard(name: _name, report: report),
                      SizedBox(height: 14.h),
                      Text('하루 감정 흐름', style: _sectionTitle()),
                      SizedBox(height: 8.h),
                      if (_emotions.length >= 2)
                        _MoodFlowCard(
                          heights: [
                            for (final point in _emotions)
                              emotionHeightOf(point.emotion),
                          ],
                          caption: moodCaptionOf(
                            report.conversationCount,
                            _emotions,
                          ),
                        )
                      else
                        _notReadyYet('이 날은 기록된 감정이 없어요.'),
                      SizedBox(height: 14.h),
                      Text('오늘 나눈 이야기', style: _sectionTitle()),
                      if (report.excerpt.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        for (final turn in report.excerpt)
                          _StoryCard(turn: turn),
                      ] else
                        _notReadyYet('이 날은 옮겨 둘 이야기가 없어요.'),
                      SizedBox(height: 10.h),
                      Text('일과', style: _sectionTitle()),
                      if (_routine.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        _RoutineCard(items: _routine),
                      ] else
                        _notReadyYet('이 날은 남은 일과 기록이 없어요.'),
                      SizedBox(height: 14.h),
                      Text('제안', style: _sectionTitle()),
                      SizedBox(height: 8.h),
                      if ((report.suggestion ?? '').isNotEmpty)
                        _SuggestionCard(text: report.suggestion!)
                      else
                        _notReadyYet('오늘은 드릴 제안이 없어요.'),
                    ],
                  ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

/// 주간 리포트. 데일리 화면 헤더의 '주간' 에서 들어온다.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final SettingsApi _api = SettingsApi();

  String _name = '';
  WeeklyReportData? _report;
  bool _loading = true;
  String? _error;

  /// 0 이 가장 최근 주. 1 씩 늘릴수록 이전 주를 본다.
  int _offset = 0;
  int? _userId;
  bool _stepping = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = (await _api.myProfile()).mainUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = '연결된 어르신이 없어요.\n가족 연결을 먼저 마쳐주세요.';
        });
        return;
      }
      _userId = user.userId;
      final report = await _api.weeklyReport(user.userId, offset: _offset);
      if (!mounted) return;
      setState(() {
        _name = user.name;
        _report = report;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = '리포트를 불러오지 못했어요.'; });
      }
    }
  }

  /// 한 칸 이전(delta 1)/이후(delta -1) 주로 옮긴다.
  Future<void> _step(int delta) async {
    final userId = _userId;
    if (userId == null || _stepping) return;
    final next = _offset + delta;
    if (next < 0) return;

    setState(() => _stepping = true);
    try {
      final report = await _api.weeklyReport(userId, offset: next);
      if (!mounted) return;
      if (report == null) {
        setState(() => _stepping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('더 이전 주간 리포트가 없어요.')),
        );
        return;
      }
      setState(() {
        _offset = next;
        _report = report;
        _stepping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stepping = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('리포트를 불러오지 못했어요: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PhoneFrame(
        child: Center(child: CircularProgressIndicator(color: _brown)),
      );
    }
    if (_error != null) {
      return _PhoneFrame(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, height: 1.5, color: _muted),
            ),
          ),
        ),
      );
    }

    final report = _report;
    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          _WeeklyHeader(
            name: _name,
            weekStart: report?.weekStart,
            at: report?.createdAt,
            onOlder: () => _step(1),
            onNewer: () => _step(-1),
            canGoNewer: _offset > 0,
            isLatest: _offset == 0,
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: report == null
                ? Center(
                    child: Text(
                      '아직 주간 리포트가 준비되지 않았어요.\n일주일이 모이면 만들어져요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 14.h),
                    children: [
                      _WeeklySummaryCard(name: _name, report: report),
                      SizedBox(height: 14.h),
                      Text('이번 주 기록', style: _sectionTitle()),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _ScoreBox(
                              title: '전체 대화',
                              value: '${report.totalConversationCount}번',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ScoreBox(
                              title: '가족 소통',
                              value: '${report.familyInteractionCount}번',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ScoreBox(
                              title: '긴급 알림',
                              value: '${report.emergencyAlertCount}번',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Text('감정', style: _sectionTitle()),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.dominantEmotion ?? '기록된 감정이 아직 없어요.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: _dark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (report.avgEmotionScore != null) ...[
                              SizedBox(height: 8.h),
                              Text(
                                '평균 감정 점수 ${report.avgEmotionScore}점',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
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

class _WeeklyHeader extends StatelessWidget {
  const _WeeklyHeader({
    required this.name,
    this.weekStart,
    this.at,
    required this.onOlder,
    required this.onNewer,
    required this.canGoNewer,
    required this.isLatest,
  });

  final String name;

  /// 어느 주의 요약인지 — 그 주 월요일. 예전 리포트에는 없을 수 있다.
  final DateTime? weekStart;
  final DateTime? at;
  final VoidCallback onOlder;
  final VoidCallback onNewer;
  final bool canGoNewer;
  final bool isLatest;

  static const double _sideWidth = 44;

  @override
  Widget build(BuildContext context) {
    // 어느 주인지를 보여준다. 주 시작일이 없는(예전) 리포트만 만들어진
    // 날짜로 물러난다.
    final String dateText;
    if (weekStart != null) {
      final end = weekStart!.add(const Duration(days: 6));
      dateText =
          '${weekStart!.month}월 ${weekStart!.day}일 ~ ${end.month}월 ${end.day}일';
    } else if (at != null) {
      dateText = '${at!.month}월 ${at!.day}일 기준';
    } else {
      dateText = '';
    }

    return Row(
      children: [
        SizedBox(
          width: _sideWidth,
          child: IconButton(
            tooltip: '뒤로 가기',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, size: 28, color: _dark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                isLatest ? '이번 주 $name님' : '$name님의 주간 리포트',
                style: const TextStyle(
                  fontSize: 16,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepArrow(
                    icon: Icons.chevron_left,
                    tooltip: '이전 주',
                    onTap: onOlder,
                  ),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 9,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StepArrow(
                    icon: Icons.chevron_right,
                    tooltip: '다음 주',
                    onTap: canGoNewer ? onNewer : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: _sideWidth),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.name, required this.report});

  final String name;
  final WeeklyReportData report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(color: const Color(0xFFFFF4D8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(text: '이번 주 요약', color: Colors.white.withValues(alpha: 0.8)),
          SizedBox(height: 12.h),
          Text(
            report.weeklySummary ?? '이번 주 $name님의 요약이 아직 없어요.',
            style: const TextStyle(
              fontSize: 18,
              height: 1.28,
              color: _dark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
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
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    this.at,
    required this.onOlder,
    required this.onNewer,
    required this.canGoNewer,
    required this.isLatest,
  });

  final String name;
  final DateTime? at;

  /// 하루 전 리포트로.
  final VoidCallback onOlder;

  /// 하루 뒤 리포트로. 가장 최근이면 막힌다.
  final VoidCallback onNewer;
  final bool canGoNewer;

  /// 가장 최근 리포트인지(제목 문구가 달라진다).
  final bool isLatest;

  static const List<String> _weekdays = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일',
  ];

  /// 좌우 버튼 폭. 가운데 제목이 실제로 화면 중앙에 오도록 맞춘다.
  static const double _sideWidth = 44;

  @override
  Widget build(BuildContext context) {
    final day = at ?? DateTime.now();
    final dateText = '${day.month}월 ${day.day}일 (${_weekdays[day.weekday - 1]})';

    return Row(
      children: [
        SizedBox(
          width: _sideWidth,
          child: IconButton(
            tooltip: '뒤로 가기',
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (_) => false,
                ),
            icon: const Icon(Icons.chevron_left, size: 28, color: _dark),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                isLatest ? '오늘의 $name님' : '$name님의 리포트',
                style: const TextStyle(
                  fontSize: 16,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepArrow(
                    icon: Icons.chevron_left,
                    tooltip: '이전 리포트',
                    onTap: onOlder,
                  ),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 9,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StepArrow(
                    icon: Icons.chevron_right,
                    tooltip: '다음 리포트',
                    onTap: canGoNewer ? onNewer : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: _sideWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
            ),
            child: Center(child: Text('주간', style: _smallBrown())),
          ),
        ),
      ],
    );
  }
}

/// 날짜를 한 칸씩 옮기는 작은 화살표. onTap 이 null 이면 흐리게 보인다.
class _StepArrow extends StatelessWidget {
  const _StepArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: onTap == null ? _line : _muted),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.name, required this.report});

  final String name;
  final DailyReportData report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(color: const Color(0xFFFFF4D8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(text: '오늘의 요약', color: Colors.white.withValues(alpha: 0.8)),
          SizedBox(height: 12.h),
          Text(
            report.summary ?? '오늘 $name님의 요약이 아직 없어요.',
            style: const TextStyle(
              fontSize: 18,
              height: 1.28,
              color: _dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _ScoreBox(
                  title: '대화',
                  value: '${report.conversationCount}번',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBox(
                  title: '가족 소통',
                  value: '${report.familyInteractionCount}번',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScoreBox(
                  title: '감정',
                  value: report.emotionSummary ?? '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: _tiny()),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: _brown,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodFlowCard extends StatelessWidget {
  const _MoodFlowCard({required this.heights, this.caption});

  /// 0(바닥)~1(천장). 감정 기록을 오래된 순으로 늘어놓은 값.
  final List<double> heights;

  /// 그래프 아래 한 줄. 짚어 줄 것이 없으면 null 이고, 그러면 칸을 그리지 않는다.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 84.h,
            child: CustomPaint(
              painter: _MoodChartPainter(heights: heights),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('아침', style: _tiny()),
              Text('점심', style: _tiny()),
              Text('저녁', style: _tiny()),
            ],
          ),
          if (caption != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 7, color: _yellow),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(caption!, style: _tiny(color: _muted)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 아래 두 카드는 서버가 아직 주지 않는 값(대화 발췌·일과)을 위한 것이다.
// 리포트 응답에 필드가 생기면 바로 쓸 수 있게 디자인을 남겨 둔다.
// ignore: unused_element
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.turn});

  final ConversationTurn turn;

  /// 몇 시쯤 나눈 이야기인지. 분까지는 필요 없다.
  String get _time {
    final at = turn.at;
    if (at == null) return '';
    final period = at.hour < 12 ? '오전' : '오후';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$period $hour시쯤';
  }

  @override
  Widget build(BuildContext context) {
    final time = _time;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (time.isNotEmpty) ...[
            Text(time, style: _tiny(color: _muted)),
            SizedBox(height: 8.h),
          ],
          _SpokenLine(who: '어르신', text: turn.user, emphasised: true),
          if (turn.mori.isNotEmpty) ...[
            SizedBox(height: 7.h),
            _SpokenLine(who: '모리', text: turn.mori, emphasised: false),
          ],
        ],
      ),
    );
  }
}

/// 누가 한 말인지 앞에 두고 그 말을 잇는다. 어르신 말이 주인공이라 진하게 쓴다.
class _SpokenLine extends StatelessWidget {
  const _SpokenLine({
    required this.who,
    required this.text,
    required this.emphasised,
  });

  final String who;
  final String text;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38.w,
          child: Text(
            who,
            style: TextStyle(
              fontSize: 10.sp,
              height: 1.5,
              color: emphasised ? _brown : _muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.5,
              color: emphasised ? _dark : _muted,
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.items});

  /// 그날 남은 일과. 서버가 최신순으로 주므로 아침부터 보이게 뒤집어 그린다.
  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final ordered = items.reversed.toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < ordered.length; i++)
            _RoutineRow(item: ordered[i], last: i == ordered.length - 1),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.item, required this.last});

  final ActivityItem item;
  final bool last;

  /// 일과 한 줄의 시각. 홈 타임라인과 달리 한 줄에 들어가야 해서 짧게 쓴다.
  String get _time {
    final at = item.createdAt;
    if (at == null) return '';
    final period = at.hour < 12 ? '오전' : '오후';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$period $hour:${at.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final style = activityStyleOf(item.activityType);
    final subtitle = (item.content ?? '').trim();
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 12, top: last ? 2 : 0),
      margin: EdgeInsets.only(bottom: last ? 0 : 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: style.tint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(style.icon, color: _brown, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityTitleOf(item.activityType),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: _tiny(color: _muted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _time,
            style: const TextStyle(
              fontSize: 10,
              color: _brown,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: _yellow,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: _brown,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MoodChartPainter extends CustomPainter {
  const _MoodChartPainter({required this.heights});

  final List<double> heights;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1E8DE)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _yellow.withValues(alpha: 0.2),
          _yellow.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    final linePaint = Paint()
      ..color = const Color(0xFFE0A218)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (i + 1) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (heights.length < 2) return;

    final step = size.width / (heights.length - 1);
    final points = [
      for (var i = 0; i < heights.length; i++)
        Offset(step * i, size.height * (1 - heights[i].clamp(0.0, 1.0))),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 2.4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 1.8, Paint()..color = const Color(0xFFE0A218));
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) =>
      oldDelegate.heights != heights;
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

TextStyle _sectionTitle() {
  return const TextStyle(
    fontSize: 12,
    color: _dark,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _smallBrown() {
  return const TextStyle(
    fontSize: 10,
    color: _brown,
    fontWeight: FontWeight.w900,
  );
}

TextStyle _tiny({Color color = _muted}) {
  return TextStyle(
    fontSize: 9,
    color: color,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
}

BoxDecoration _cardDecoration({Color color = Colors.white}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _line),
  );
}
