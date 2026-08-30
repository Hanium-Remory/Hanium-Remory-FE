// 하단 네비게이션을 가진 메인 셸.
//
// 홈·대화·추억·설정은 서로를 라우트로 밀지 않고 여기 탭으로 들어간다.
// 전에는 네 화면이 저마다 네비바를 복사해 갖고 있어서 모양이 달랐고
// (추억만 높이·모서리가 달랐다), 화면을 옮길 때마다 바가 새로 그려졌다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '4. home/home_and_alert_center.dart';
import '5. memory/memory_add_flow.dart';
import '6. chat/family_chat_screen.dart';
import '9. set/settings_flow.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);

/// 탭 순서. 네비바와 IndexedStack 이 이 순서를 공유한다.
enum AppTab { home, chat, memory, settings }

/// 하위 화면이 탭을 바꿀 수 있게 해준다.
/// (홈의 바로가기 카드, 설정의 '홈으로 돌아가기' 등)
class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(AppTab tab) selectTab;

  static MainShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialTab.index;

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return MainShellScope(
      selectTab: (tab) => _select(tab.index),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // IndexedStack 이라 탭을 오가도 각 화면의 상태(스크롤·입력)가 남는다.
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    HomeAndAlertPreview(),
                    FamilyChatScreen(),
                    MemoryAddFlow(),
                    SettingsFlow(),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 402),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: AppNavBar(current: _index, onSelected: _select),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final int current;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, '홈'),
    (Icons.chat_bubble_outline, '대화'),
    (Icons.image_outlined, '추억'),
    (Icons.settings_outlined, '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _items.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(i),
              child: SizedBox(
                width: 52,
                height: 54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _items[i].$1,
                      size: 20,
                      color: i == current ? _yellow : _muted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].$2,
                      style: TextStyle(
                        fontSize: 9,
                        color: i == current ? _brown : _muted,
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
