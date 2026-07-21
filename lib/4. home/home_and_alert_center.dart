import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../5. memory/memory_add_flow.dart';
import '../6. chat/family_chat_screen.dart';
import '../7. report/daily_report_screen.dart';
import '../8. vocie/voice_record_flow.dart';
import '../9. set/settings_flow.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);

class HomeAndAlertPreview extends StatefulWidget {
  const HomeAndAlertPreview({super.key});

  @override
  State<HomeAndAlertPreview> createState() => _HomeAndAlertPreviewState();
}

class _HomeAndAlertPreviewState extends State<HomeAndAlertPreview> {
  bool _showAlerts = false;

  @override
  Widget build(BuildContext context) {
    return _showAlerts
        ? AlertCenterScreen(onBack: () => setState(() => _showAlerts = false))
        : HomeScreen(onOpenAlerts: () => setState(() => _showAlerts = true));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  _TopBar(onOpenAlerts: onOpenAlerts),
                  SizedBox(height: 12.h),
                  Text('5월 19일 오전 9시 14분', style: _caption()),
                  SizedBox(height: 4.h),
                  Text('오늘 박순자님은 잘 지내고 계세요', style: _headline()),
                  SizedBox(height: 12.h),
                  const _StatusCard(),
                  SizedBox(height: 10.h),
                  const _MoodCard(),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickTile(
                          title: '추억 추가',
                          subtitle: '사진과 글',
                          icon: Icons.image_outlined,
                          color: _brown,
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MemoryAddFlow(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickTile(
                          title: '내 목소리 등록',
                          subtitle: '인형이 내 목소리로',
                          icon: Icons.mic_none,
                          color: _yellow,
                          textColor: _dark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VoiceRecordFlow(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickTile(
                          title: '가족 대화',
                          subtitle: '새 메시지 3',
                          icon: Icons.chat_bubble_outline,
                          color: Colors.white,
                          textColor: _dark,
                          badge: '3',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FamilyChatScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickTile(
                          title: '오늘의 리포트',
                          subtitle: '대화, 활동, 감정',
                          icon: Icons.show_chart,
                          color: Colors.white,
                          textColor: _dark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DailyReportScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text('오늘 박순자님이 이렇게 지내셨어요', style: _sectionTitle()),
                  SizedBox(height: 8.h),
                  const _TimelineItem(
                    icon: Icons.chat_bubble_outline,
                    title: '인형과 3분 대화',
                    subtitle: '손주, 감정 이야기',
                    time: '오전\n9시 14분',
                    tint: Color(0xFFE7F6D8),
                  ),
                  const _TimelineItem(
                    icon: Icons.schedule,
                    title: '인형이 먼저 안부를 여쭈었어요',
                    subtitle: '아침 8시 30분 알림 시간',
                    time: '오전\n8시 30분',
                    tint: Color(0xFFFFF3C8),
                  ),
                  const _TimelineItem(
                    icon: Icons.meeting_room_outlined,
                    title: '아침 약 복용 시간이예요',
                    subtitle: '아침 약물이 남았어요',
                    time: '오전\n8시 00분',
                    tint: Color(0xFFFFE8C9),
                  ),
                  const _TimelineItem(
                    icon: Icons.mic_none,
                    title: '며느리한테 안부 전해달라 하셨어요',
                    subtitle: '대화방에서 확인해보세요',
                    time: '오전\n7시 50분',
                    tint: Color(0xFFF6E6D6),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
          const _HomeNavBar(),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class AlertCenterScreen extends StatefulWidget {
  const AlertCenterScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen> {
  String _selectedTab = '전체';

  @override
  Widget build(BuildContext context) {
    final alerts = <Widget>[
      const _AlertCard(
        icon: Icons.warning_amber_rounded,
        label: '긴급',
        title: '어머니의 감정이 평소와 달라요',
        body: '한 시간째 슬픔과 불안이 이어지고 있어요. 직접 전화 한 통 드려보시는 건 어떨까요?',
        action: '바로 전화하기',
        urgent: true,
      ),
      _AlertCard(
        icon: Icons.show_chart,
        label: '리포트',
        title: '오늘의 데일리 리포트가 준비됐어요',
        body: '대화 5번, 활동도 72%, 감정 흐름이 평온하게 유지되었어요.',
        action: '리포트 열어보기',
        warm: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReportScreen()),
          );
        },
      ),
      const _AlertCard(
        icon: Icons.chat_bubble_outline,
        title: '어머님이 가족들과 이야기하고 싶다고 하셨어요',
        body: '"우리 손주들은 크고 있나. 요새 잘 지내나 모르겠어..."',
        action: '대화방 열기',
      ),
      const _AlertCard(
        icon: Icons.warning_amber_rounded,
        title: '인형 연결이 잠시 끊겼어요',
        body: '14분 만에 다시 연결되었어요. 와이파이 신호를 확인해보세요.',
        action: '연결 설정',
      ),
      const _AlertCard(
        icon: Icons.mic_none,
        title: '어머님이 녹음하신 목소리를 들으셨어요',
        body: '목소리를 두 번 들으셨어요.',
      ),
    ];

    final visibleAlerts = _selectedTab == '전체'
        ? alerts
        : alerts.where((alert) {
            final card = alert as _AlertCard;
            return card.label == _selectedTab;
          }).toList();

    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.chevron_left, size: 24, color: _dark),
                ),
              ),
              Expanded(
                child: Text(
                  '알림',
                  textAlign: TextAlign.center,
                  style: _navTitle(),
                ),
              ),
              Text('모두 읽음', style: _caption()),
            ],
          ),
          SizedBox(height: 14.h),
          _AlertTabs(
            selected: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: visibleAlerts,
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
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '9:41',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onOpenAlerts,
          child: Stack(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _line),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 18,
                  color: _dark,
                ),
              ),
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD55045),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(color: const Color(0xFFFFF3D2)),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFEFD6C5),
            child: Icon(Icons.elderly_woman, color: _brown, size: 30),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6D9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '안정적',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4C8B3D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                const Text(
                  '지금 박순자님과\n이야기 중이에요.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    const Icon(
                      Icons.battery_full,
                      size: 13,
                      color: Color(0xFF5D9E41),
                    ),
                    SizedBox(width: 3.w),
                    Text('78%', style: _caption()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFFFF2C3),
                child: Icon(
                  Icons.sentiment_satisfied_alt,
                  color: _yellow,
                  size: 22,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지금 감정', style: _caption()),
                    const Text(
                      '평온해요',
                      style: TextStyle(
                        fontSize: 15,
                        color: _dark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text('오늘의 흐름', style: _caption()),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 34.h,
            child: CustomPaint(
              painter: _MoodLinePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('아침', style: _tiny()),
              Text('점심', style: _tiny()),
              Text('오후', style: _tiny()),
              Text('지금', style: _tiny()),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = color == Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 86,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(color: color),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: isLight ? _brown : textColor, size: 20),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: isLight ? _muted : textColor.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: const Color(0xFFC9564D),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _brown),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _listTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: _caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(time, textAlign: TextAlign.right, style: _tiny()),
        ],
      ),
    );
  }
}

class _HomeNavBar extends StatelessWidget {
  const _HomeNavBar();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, '홈', true),
      (Icons.chat_bubble_outline, '대화', false),
      (Icons.image_outlined, '추억', false),
      (Icons.settings_outlined, '설정', false),
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
                if (item.$2 == '대화') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyChatScreen()),
                  );
                }

                if (item.$2 == '추억') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemoryAddFlow()),
                  );
                }

                if (item.$2 == '설정') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsFlow()),
                  );
                }
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

class _AlertTabs extends StatelessWidget {
  const _AlertTabs({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3D8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final tab in const ['전체', '긴급', '리포트'])
            _TabItem(
              text: tab,
              selected: selected == tab,
              onTap: () => onSelected(tab),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.text,
    required this.onTap,
    this.selected = false,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected ? _brown : _muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.title,
    required this.body,
    this.label,
    this.action,
    this.urgent = false,
    this.warm = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? label;
  final String? action;
  final bool urgent;
  final bool warm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = warm ? const Color(0xFFFFF8E7) : Colors.white;
    final borderColor = urgent
        ? const Color(0xFFE56A61)
        : warm
        ? const Color(0xFFF1C967)
        : _line;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: urgent
                    ? const Color(0xFFFFE3E0)
                    : const Color(0xFFF4E4D5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: urgent ? const Color(0xFFE56A61) : _brown,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _brown.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: _brown,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dark,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _muted,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      '$action  >',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _brown,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF0E8DF)
      ..strokeWidth = 1;
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
      Offset(0, size.height * .58),
      Offset(size.width * .15, size.height * .62),
      Offset(size.width * .28, size.height * .52),
      Offset(size.width * .43, size.height * .66),
      Offset(size.width * .58, size.height * .45),
      Offset(size.width * .74, size.height * .50),
      Offset(size.width * .88, size.height * .45),
      Offset(size.width, size.height * .44),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
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

TextStyle _headline() {
  return const TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w900,
    color: _dark,
  );
}

TextStyle _sectionTitle() {
  return const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: _dark,
  );
}

TextStyle _navTitle() {
  return const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: _dark,
  );
}

TextStyle _listTitle() {
  return const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: _dark,
  );
}

TextStyle _caption() {
  return const TextStyle(
    fontSize: 10,
    color: _muted,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
}

TextStyle _tiny() {
  return const TextStyle(
    fontSize: 9,
    color: _muted,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}

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
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : null,
  );
}
