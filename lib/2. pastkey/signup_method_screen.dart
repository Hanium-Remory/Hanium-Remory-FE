import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../3. code/first_registration_flow.dart';
import '../3. code/invite_code_input_screen.dart';

const Color _background = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF9B674C);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellowSoft = Color(0xFFFFF2C9);

class SignupMethodScreen extends StatelessWidget {
  const SignupMethodScreen({super.key});

  void _openRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FirstRegistrationFlow()),
    );
  }

  void _openCodeInput(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InviteCodeInputScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 88.h),
                  Text(
                    '어떻게 시작할까요?',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '처음 이용하시면 사용자 정보를 등록하고,\n가족이 초대해주셨다면 코드만 입력하면 돼요.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13.sp,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 48.h),
                  _MethodCard(
                    icon: Icons.elderly_woman_rounded,
                    iconColor: Colors.white,
                    iconBackground: _brown,
                    title: '처음 시작해요',
                    description: '보호자 + 인형 사용자 정보 등록 후\n가족을 초대해요',
                    onTap: () => _openRegistration(context),
                  ),
                  SizedBox(height: 12.h),
                  _MethodCard(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFFD99C00),
                    iconBackground: _yellowSoft,
                    title: '코드를 받았어요',
                    description: '가족이 알려준 6자리코드\n이미 등록된 사용자와 연결돼요',
                    onTap: () => _openCodeInput(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 104.h),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 17.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(icon, color: iconColor, size: 29.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _dark,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      description,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11.sp,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
