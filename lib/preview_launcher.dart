import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '3. code/first_registration_flow.dart';
import '4. home/home_and_alert_center.dart';
import '5. memory/memory_add_flow.dart';
import '8. vocie/voice_record_flow.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;

    return ScreenUtilInit(
      designSize: logicalSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => _PhoneViewport(child: child),
          theme: ThemeData(
            scaffoldBackgroundColor: _bg,
            fontFamily: 'Pretendard',
          ),
          home: child,
        );
      },
      child: const PreviewLauncher(),
    );
  }
}

class _PhoneViewport extends StatelessWidget {
  const _PhoneViewport({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 402
              ? 402.0
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class PreviewLauncher extends StatelessWidget {
  const PreviewLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PreviewItem(
        title: '최초 정보등록 및 코드 입력',
        subtitle: 'Face ID, 보호자 정보, 가족 연결, 초대 코드',
        page: const FirstRegistrationFlow(),
      ),
      _PreviewItem(
        title: '홈 / 알림 센터',
        subtitle: '홈 화면에서 알림 아이콘을 누르면 알림 센터로 이동',
        page: const HomeAndAlertPreview(),
      ),
      _PreviewItem(
        title: '추억 추가',
        subtitle: '작성 후 저장을 누르면 저장 완료 화면으로 이동',
        page: const MemoryAddFlow(),
      ),
      _PreviewItem(
        title: '내 목소리 등록',
        subtitle: '녹음 안내, 녹음 중, 확인, 완료 화면',
        page: const VoiceRecordFlow(),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 28.h),
              Text(
                '화면 전체보기',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: _dark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '확인할 화면 묶음을 선택하세요.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 22.h),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: pages.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = pages[index];
                    return _PreviewCard(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.item});

  final _PreviewItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page),
        );
      },
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: _dark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      height: 1.4,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: const Color(0xFFF1E4D9),
              child: Icon(Icons.chevron_right, color: _brown, size: 22.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewItem {
  const _PreviewItem({
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final String title;
  final String subtitle;
  final Widget page;
}
