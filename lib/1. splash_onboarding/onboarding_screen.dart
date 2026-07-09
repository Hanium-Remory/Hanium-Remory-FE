import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../2. pastkey/signup_method_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();

  int currentPage = 0;

  final List<OnboardingData> pages = [
    OnboardingData(
      icon: Icons.sentiment_satisfied_alt,
      title: '메모리가\n매일 곁에',
      subtitle: '직접 가지 않아도 사랑하는 가족의 하루를\n이어가며 따뜻하게 돌봐드려요.',
      buttonText: '다음으로',
    ),
    OnboardingData(
      icon: Icons.record_voice_over,
      title: '가족 목소리로\n말 거는 인형',
      subtitle: '가족의 따뜻한 목소리를 인형이 그대로 들려줘요.\n곁에 있는 듯 편안하게.',
      buttonText: '다음으로',
    ),
    OnboardingData(
      icon: Icons.photo,
      title: '추억을\n함께 나누어요',
      subtitle: '사진과 짧은 이야기로\n어르신의 기억을 다시 따뜻하게 연결해요.',
      buttonText: '시작하기',
    ),
  ];

  void startRegistration() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupMethodScreen()),
    );
  }

  void nextPage() {
    if (currentPage < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      startRegistration();
    }
  }

  void skipOnboarding() {
    startRegistration();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      body: SafeArea(
        child: PageView.builder(
          controller: pageController,
          itemCount: pages.length,
          onPageChanged: (index) {
            setState(() {
              currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.w),
              child: Column(
                children: [
                  SizedBox(height: 28.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: skipOnboarding,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF6D5A50),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 34.r,
                    backgroundColor: const Color(0xFFF1DED4),
                    child: Icon(
                      pages[index].icon,
                      size: 40.sp,
                      color: const Color(0xFF936249),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    pages[index].title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2F2521),
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    pages[index].subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF6D5A50),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (dotIndex) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        width: currentPage == dotIndex ? 14.w : 5.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: currentPage == dotIndex
                              ? const Color(0xFF936249)
                              : const Color(0xFFD8C5BA),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 42.h,
                    child: ElevatedButton(
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF936249),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        pages[index].buttonText,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });
}
