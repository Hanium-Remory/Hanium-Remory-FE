import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../7. report/daily_report_screen.dart';
import '../8. vocie/voice_record_flow.dart';
import '../main_shell.dart';
import '../services/settings_api.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);

/// 서버가 주는 감정 코드를 화면 문구로 바꾼다.
const Map<String, String> _emotionLabels = {
  'happy': '기뻐요',
  'calm': '평온해요',
  'sad': '슬퍼요',
  'angry': '화나요',
  'anxious': '불안해요',
  'lonely': '외로워요',
};

/// 감정 추이 선의 높이(0=바닥, 1=천장). 점수 컬럼이 없어서 감정별로 정해 둔다.
const Map<String, double> _emotionHeights = {
  'happy': 0.85,
  'calm': 0.65,
  'lonely': 0.40,
  'anxious': 0.32,
  'sad': 0.25,
  'angry': 0.20,
};

String _emotionLabelOf(String? emotion) =>
    _emotionLabels[emotion] ?? '아직 기록이 없어요';

/// 감정 코드 → 그래프 높이. 리포트 화면도 같은 기준을 써야 해서 공개한다.
double emotionHeightOf(String? emotion) => _emotionHeights[emotion] ?? 0.5;

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenAlerts});

  final VoidCallback onOpenAlerts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SettingsApi _api = SettingsApi();

  HomeSummary? _summary;
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
      final summary = await _api.home(user.userId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = '홈 정보를 불러오지 못했어요.'; });
      }
    }
  }

  /// 활동 코드에 맞는 아이콘·배경색. 모르는 코드는 기본값으로 보여준다.
  ({IconData icon, Color tint}) _activityStyle(String type) {
    final t = type.toUpperCase();
    if (t.contains('CONVERSATION') || t.contains('CHAT')) {
      return (icon: Icons.chat_bubble_outline, tint: const Color(0xFFE7F6D8));
    }
    if (t.contains('MEDICATION')) {
      return (icon: Icons.medication_outlined, tint: const Color(0xFFFFE8C9));
    }
    if (t.contains('VOICE')) {
      return (icon: Icons.mic_none, tint: const Color(0xFFF6E6D6));
    }
    return (icon: Icons.schedule, tint: const Color(0xFFFFF3C8));
  }

  String _activityTitle(ActivityItem a) {
    switch (a.activityType.toUpperCase()) {
      case 'DAILY_CONVERSATION':
        return '인형과 대화했어요';
      case 'MEDICATION':
        return '약 복용 시간이었어요';
      case 'VOICE_PLAY':
        return '가족 목소리를 들으셨어요';
      default:
        // 모르는 코드는 감추지 말고 그대로 보여준다.
        return a.activityType;
    }
  }

  String _timelineTime(DateTime? at) {
    if (at == null) return '';
    final period = at.hour < 12 ? '오전' : '오후';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$period\n$hour시 ${at.minute.toString().padLeft(2, '0')}분';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PhoneFrame(
        child: Center(child: CircularProgressIndicator(color: _brown)),
      );
    }
    final summary = _summary;
    if (summary == null) {
      return _PhoneFrame(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? '홈 정보를 불러오지 못했어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, height: 1.5, color: _muted),
            ),
          ),
        ),
      );
    }
    final name = summary.userName;
    final onOpenAlerts = widget.onOpenAlerts;

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
                  _TopBar(
                    onOpenAlerts: onOpenAlerts,
                    hasUnread: summary.unreadNotificationCount > 0,
                  ),
                  SizedBox(height: 12.h),
                  Text('오늘 $name님은 잘 지내고 계세요', style: _headline()),
                  SizedBox(height: 12.h),
                  _StatusCard(name: name, device: summary.device),
                  SizedBox(height: 10.h),
                  _MoodCard(
                    emotion: summary.currentEmotion?.emotion,
                    trend: summary.emotionTrend,
                  ),
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
                          // 탭으로 옮긴다. 라우트로 밀면 네비바가 가려진다.
                          onTap: () => MainShellScope.maybeOf(
                            context,
                          )?.selectTab(AppTab.memory),
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
                          subtitle: summary.unreadChatCount > 0
                              ? '새 메시지 ${summary.unreadChatCount}'
                              : '가족과 이야기해요',
                          icon: Icons.chat_bubble_outline,
                          color: Colors.white,
                          textColor: _dark,
                          badge: summary.unreadChatCount > 0
                              ? '${summary.unreadChatCount}'
                              : null,
                          onTap: () => MainShellScope.maybeOf(
                            context,
                          )?.selectTab(AppTab.chat),
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
                  Text('오늘 $name님이 이렇게 지내셨어요', style: _sectionTitle()),
                  SizedBox(height: 8.h),
                  if (summary.activities.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      child: Text(
                        '아직 오늘 기록이 없어요.',
                        style: TextStyle(fontSize: 13.sp, color: _muted),
                      ),
                    )
                  else
                    for (final activity in summary.activities)
                      _TimelineItem(
                        icon: _activityStyle(activity.activityType).icon,
                        title: _activityTitle(activity),
                        subtitle: activity.content ?? '',
                        time: _timelineTime(activity.createdAt),
                        tint: _activityStyle(activity.activityType).tint,
                      ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
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
  final SettingsApi _api = SettingsApi();

  String _selectedTab = '전체';
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.notifications();
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = '알림을 불러오지 못했어요.'; });
      }
    }
  }

  /// 안 읽은 것만 읽음 처리한다. 서버에 일괄 처리가 없어 한 건씩 부른다.
  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    try {
      for (final n in unread) {
        await _api.markNotificationRead(n.notificationId);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('읽음 처리에 실패했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _labelOf(AppNotification n) {
    if (n.isUrgent) return '긴급';
    if (n.isReport) return '리포트';
    return null;
  }

  Widget _card(AppNotification n) {
    return _AlertCard(
      icon: n.isUrgent
          ? Icons.warning_amber_rounded
          : n.isReport
          ? Icons.show_chart
          : Icons.notifications_none,
      label: _labelOf(n),
      title: n.title ?? '알림',
      body: n.content ?? '',
      action: n.isReport ? '리포트 열어보기' : null,
      urgent: n.isUrgent,
      warm: n.isReport,
      onTap: n.isReport
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyReportScreen()),
              );
            }
          : null,
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, height: 1.5, color: _muted),
          ),
        ),
      );
    }
    final visible = _selectedTab == '전체'
        ? _notifications
        : _notifications.where((n) => _labelOf(n) == _selectedTab).toList();
    if (visible.isEmpty) {
      return Center(
        child: Text(
          '아직 알림이 없어요.',
          style: TextStyle(fontSize: 13.sp, color: _muted),
        ),
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [for (final n in visible) _card(n)],
    );
  }

  @override
  Widget build(BuildContext context) {
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
              GestureDetector(
                onTap: _markAllRead,
                child: Text('모두 읽음', style: _caption()),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _AlertTabs(
            selected: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          SizedBox(height: 10.h),
          Expanded(child: _buildList()),
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
  const _TopBar({required this.onOpenAlerts, required this.hasUnread});

  final VoidCallback onOpenAlerts;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              if (hasUnread)
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
  const _StatusCard({required this.name, this.device});

  final String name;

  /// 인형을 아직 연결하지 않았으면 null.
  final HomeDevice? device;

  @override
  Widget build(BuildContext context) {
    final connected = device?.connected == true;
    final String badge;
    final Color badgeBg;
    final Color badgeFg;
    if (device == null) {
      badge = '연결 전';
      badgeBg = const Color(0xFFF0E8DF);
      badgeFg = _muted;
    } else if (connected) {
      badge = '안정적';
      badgeBg = const Color(0xFFE8F6D9);
      badgeFg = const Color(0xFF4C8B3D);
    } else {
      badge = '연결 끊김';
      badgeBg = const Color(0xFFFBE3E1);
      badgeFg = const Color(0xFFD55045);
    }

    final String headline;
    if (device == null) {
      headline = '인형을 아직\n연결하지 않았어요.';
    } else if (connected) {
      headline = '지금 $name님과\n이야기 중이에요.';
    } else {
      headline = '$name님의 인형이\n연결되어 있지 않아요.';
    }

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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      color: badgeFg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                    height: 1.25,
                  ),
                ),
                if (device != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      const Icon(
                        Icons.battery_full,
                        size: 13,
                        color: Color(0xFF5D9E41),
                      ),
                      SizedBox(width: 3.w),
                      Text('${device!.batteryLevel}%', style: _caption()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({this.emotion, required this.trend});

  /// 가장 최근 감정 코드. 기록이 없으면 null.
  final String? emotion;
  final List<EmotionPoint> trend;

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
                    Text(
                      _emotionLabelOf(emotion),
                      style: const TextStyle(
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
              painter: _MoodLinePainter(
                heights: [
                  for (final point in trend)
                    _emotionHeights[point.emotion] ?? 0.5,
                ],
              ),
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
  const _MoodLinePainter({required this.heights});

  /// 0(바닥)~1(천장). 기록이 없으면 선을 그리지 않는다.
  final List<double> heights;

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
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MoodLinePainter oldDelegate) =>
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
