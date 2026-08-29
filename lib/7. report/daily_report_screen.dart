import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../4. home/home_and_alert_center.dart';
import '../services/settings_api.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);
const Color _green = Color(0xFF5D9E41);

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final SettingsApi _api = SettingsApi();

  String _name = '';
  DailyReportData? _report;
  List<double> _moodHeights = [];
  bool _loading = true;
  String? _error;

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
      final report = await _api.dailyReport(user.userId);
      // 감정 흐름은 리포트에 없어서 홈이 주는 감정 기록을 그대로 쓴다.
      final home = await _api.home(user.userId);
      if (!mounted) return;
      setState(() {
        _name = user.name;
        _report = report;
        _moodHeights = [
          for (final point in home.emotionTrend)
            emotionHeightOf(point.emotion),
        ];
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
          _Header(name: _name, at: report?.reportDate ?? report?.createdAt),
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
                      if (_moodHeights.length >= 2)
                        _MoodFlowCard(heights: _moodHeights)
                      else
                        _notReadyYet('아직 기록된 감정이 없어요.'),
                      SizedBox(height: 14.h),
                      Text('오늘 나눈 이야기', style: _sectionTitle()),
                      _notReadyYet('대화 발췌는 아직 제공되지 않아요.'),
                      SizedBox(height: 10.h),
                      Text('일과', style: _sectionTitle()),
                      _notReadyYet('일과 기록은 아직 제공되지 않아요.'),
                      SizedBox(height: 14.h),
                      Text('제안', style: _sectionTitle()),
                      _notReadyYet('제안은 아직 제공되지 않아요.'),
                    ],
                  ),
          ),
          const _HomeIndicator(),
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
  const _Header({required this.name, this.at});

  final String name;
  final DateTime? at;

  static const List<String> _weekdays = [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일',
  ];

  @override
  Widget build(BuildContext context) {
    final day = at ?? DateTime.now();
    final dateText = '${day.month}월 ${day.day}일 (${_weekdays[day.weekday - 1]})';
    return Row(
      children: [
        IconButton(
          tooltip: '뒤로 가기',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
                (_) => false,
              ),
          icon: const Icon(Icons.chevron_left, size: 28, color: _dark),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '오늘의 $name님',
                style: const TextStyle(
                  fontSize: 16,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 9,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text('주간', style: _smallBrown()),
      ],
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
  const _MoodFlowCard({required this.heights});

  /// 0(바닥)~1(천장). 감정 기록을 오래된 순으로 늘어놓은 값.
  final List<double> heights;

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
                  child: Text(
                    '오후 5시 손녀와의 대화 후 가장 좋아지셨어요.',
                    style: _tiny(color: _muted),
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

// 아래 세 카드는 서버가 아직 주지 않는 값(대화 발췌·일과·제안)을 위한 것이다.
// 리포트 응답에 필드가 생기면 바로 쓸 수 있게 디자인을 남겨 둔다.
// ignore: unused_element
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.time,
    required this.label,
    required this.title,
    required this.tags,
  });

  final String time;
  final String label;
  final String title;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(time, style: _tiny(color: _muted)),
              const Spacer(),
              _Pill(text: label, color: const Color(0xFFF9EBD9)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 9.h),
          Wrap(
            spacing: 6,
            children: [
              for (final tag in tags)
                _Pill(text: tag, color: const Color(0xFFF6EFE8)),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _RoutineCard extends StatelessWidget {
  const _RoutineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: const [
          _RoutineRow(
            icon: Icons.wb_sunny_outlined,
            title: '아침 인사',
            subtitle: '오전 8:30 인형이 먼저',
            trailing: Icons.check,
            trailingColor: _green,
          ),
          _RoutineRow(
            icon: Icons.medication_outlined,
            title: '혈압약 복용',
            subtitle: '아침 식후',
            trailingText: '9:12',
            trailingColor: _green,
          ),
          _RoutineRow(
            icon: Icons.restaurant_outlined,
            title: '식사',
            subtitle: '아침 · 점심',
            trailingText: '2 / 3',
            trailingColor: _brown,
          ),
          _RoutineRow(
            icon: Icons.nightlight_round,
            title: '잠 자라는 인사',
            subtitle: '오후 9:00',
            trailingText: '-',
            trailingColor: _muted,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingColor,
    this.trailing,
    this.trailingText,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final String? trailingText;
  final Color trailingColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFFFFF3D2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _brown, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: _tiny(color: _muted)),
              ],
            ),
          ),
          if (trailing != null)
            Icon(trailing, size: 14, color: trailingColor)
          else
            Text(
              trailingText ?? '',
              style: TextStyle(
                fontSize: 10,
                color: trailingColor,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

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
                const Text(
                  '저녁 식사 시간이 지나도록 식사 확인이 안 되었어요',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: _dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text('안부 전화 한 통 드려보시는 건 어떨까요?', style: _tiny()),
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
