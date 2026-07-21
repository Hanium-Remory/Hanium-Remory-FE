import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);
const Color _green = Color(0xFF5D9E41);

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          const _Header(),
          SizedBox(height: 10.h),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 14.h),
              children: [
                const _SummaryCard(),
                SizedBox(height: 14.h),
                Text('하루 감정 흐름', style: _sectionTitle()),
                SizedBox(height: 8.h),
                const _MoodFlowCard(),
                SizedBox(height: 14.h),
                Text('오늘 나눈 이야기', style: _sectionTitle()),
                SizedBox(height: 8.h),
                const _StoryCard(
                  time: '오전 9:14 · 3분',
                  label: '가족',
                  title: '"우리 손주 보고 싶네. 요새 잘 지내는지 모르겠어."',
                  tags: ['방문', '애정', '성취'],
                ),
                const _StoryCard(
                  time: '오전 12:40 · 1분',
                  label: '식사',
                  title: '"오늘 점심은 미역국이었어. 따뜻하게 잘 먹었지."',
                  tags: ['식사', '평온'],
                ),
                const _StoryCard(
                  time: '오후 5:02 · 6분',
                  label: '추억',
                  title: '"우리 서연이가 그림 공부를 잘한다네. 기특하지."',
                  tags: ['생일', '대화', '정서'],
                ),
                SizedBox(height: 10.h),
                Text('일과', style: _sectionTitle()),
                SizedBox(height: 8.h),
                const _RoutineCard(),
                SizedBox(height: 14.h),
                Text('제안', style: _sectionTitle()),
                SizedBox(height: 8.h),
                const _SuggestionCard(),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Column(
            children: const [
              Text(
                '오늘의 박순자님',
                style: TextStyle(
                  fontSize: 16,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '5월 19일 (월요일)',
                style: TextStyle(
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
  const _SummaryCard();

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
          const Text(
            '오늘은 박순자님이 평소보다\n조금 더 활기차게 지내셨어요.',
            style: TextStyle(
              fontSize: 18,
              height: 1.28,
              color: _dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: const [
              Expanded(
                child: _ScoreBox(title: '대화', value: '5번'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ScoreBox(title: '활동도', value: '72%'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ScoreBox(title: '활동', value: '보통'),
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
  const _MoodFlowCard();

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
              painter: _MoodChartPainter(),
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

    final points = [
      Offset(0, size.height * .63),
      Offset(size.width * .12, size.height * .5),
      Offset(size.width * .24, size.height * .42),
      Offset(size.width * .38, size.height * .51),
      Offset(size.width * .52, size.height * .48),
      Offset(size.width * .66, size.height * .61),
      Offset(size.width * .82, size.height * .38),
      Offset(size.width, size.height * .47),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
