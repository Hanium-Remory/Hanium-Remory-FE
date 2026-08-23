import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../4. home/home_and_alert_center.dart';
import '../6. chat/family_chat_screen.dart';
import '../9. set/settings_flow.dart';
import '../services/session_store.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _softYellow = Color(0xFFFFF3D2);
const Color _yellow = Color(0xFFF6C43D);

class MemoryAddFlow extends StatefulWidget {
  const MemoryAddFlow({super.key});

  @override
  State<MemoryAddFlow> createState() => _MemoryAddFlowState();
}

class _MemoryAddFlowState extends State<MemoryAddFlow> {
  bool _saved = false;

  void _saveMemory() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saved = true);
  }

  void _backToForm() {
    setState(() => _saved = false);
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeAndAlertPreview()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _saved
        ? MemorySavedScreen(onBack: _backToForm, onConfirm: _goHome)
        : MemoryAddScreen(onSave: _saveMemory);
  }
}

class MemoryAddScreen extends StatefulWidget {
  const MemoryAddScreen({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  State<MemoryAddScreen> createState() => _MemoryAddScreenState();
}

class _MemoryAddScreenState extends State<MemoryAddScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  Uint8List? _selectedPhoto;
  int _selectedWhen = 0;

  final List<String> _whenOptions = ['오늘', '최근', '몇 년 전', '오래된 추억'];

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _selectedPhoto = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _Header(title: '새 추억', actionText: '저장', onAction: widget.onSave),
              SizedBox(height: 14.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoUploadBox(
                        imageBytes: _selectedPhoto,
                        onTap: _pickPhoto,
                      ),
                      SizedBox(height: 18.h),
                      _Label('한 줄 제목'),
                      _TextFieldBox(
                        controller: _titleController,
                        hintText: '예: 손주 운동회',
                        maxLines: 1,
                      ),
                      SizedBox(height: 18.h),
                      _Label('언제 기억인가요'),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: List.generate(_whenOptions.length, (index) {
                          return _ChipButton(
                            text: _whenOptions[index],
                            selected: _selectedWhen == index,
                            onTap: () => setState(() => _selectedWhen = index),
                          );
                        }),
                      ),
                      SizedBox(height: 18.h),
                      _Label('박순자님과 나눌 이야기'),
                      _TextFieldBox(
                        controller: _storyController,
                        hintText:
                            '예: 작년 가을 손주 운동회 때 ${SessionStore.elderHonorific}이 도시락 만들어주신 날이에요. 날씨가 엄청 좋았는데, 서연이가 달리기 1등했었어요.',
                        maxLines: 6,
                      ),
                      SizedBox(height: 8.h),
                      Text('0 / 300자 - 짧고 따뜻하게 써주세요', style: _caption()),
                      SizedBox(height: 14.h),
                      _GuideBox(),
                    ],
                  ),
                ),
              ),
              const _MemoryNavBar(),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class MemorySavedScreen extends StatelessWidget {
  const MemorySavedScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _Header(title: '새 추억 등록', onBack: onBack),
              const Spacer(),
              _SuccessMark(),
              SizedBox(height: 34.h),
              Text(
                '잘 보냈어요',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                ),
              ),
              SizedBox(height: 22.h),
              Text(
                '새로운 추억을 인형이 저장하는 데 몇 분 정도가 걸려요.\n저장된 이후에 새로운 추억에 대해 이야기할게요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.55,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '알겠어요',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Container(
                width: 58.w,
                height: 3.h,
                margin: EdgeInsets.only(bottom: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7B8AE),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.actionText,
    this.onAction,
    this.onBack,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;
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
                        builder: (_) => const HomeAndAlertPreview(),
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
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
          ),
          if (actionText != null)
            SizedBox(
              height: 36.h,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            SizedBox(width: 42.w),
        ],
      ),
    );
  }
}

class _PhotoUploadBox extends StatelessWidget {
  const _PhotoUploadBox({required this.imageBytes, required this.onTap});

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 150.h,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 32.sp, color: _brown),
                  SizedBox(height: 12.h),
                  Text(
                    '사진을 한 장 골라주세요',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: _brown,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text('가족, 풍경, 음식 모두 좋아요', style: _caption()),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    right: 10.w,
                    bottom: 10.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: _dark.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                      child: Text(
                        '사진 바꾸기',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          color: _dark,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.controller,
    required this.hintText,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines,
      cursorColor: _brown,
      style: TextStyle(
        fontSize: 14.sp,
        color: _dark,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: const Color(0xFFB9ACA2),
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: _brown),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _brown : Colors.white,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: selected ? _brown : _line),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: selected ? Colors.white : _dark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _GuideBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _softYellow,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: _yellow),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '인형은 이 추억을 자연스러운 대화로 ${SessionStore.elderHonorific}께 들려드려요.\n정확한 단어는 다르게 표현될 수 있어요.',
              style: TextStyle(
                fontSize: 11.sp,
                color: _muted,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

class _MemoryNavBar extends StatelessWidget {
  const _MemoryNavBar();

  void _openTab(BuildContext context, String label) {
    final Widget? screen = switch (label) {
      '홈' => const HomeAndAlertPreview(),
      '대화' => const FamilyChatScreen(),
      '설정' => const SettingsFlow(),
      _ => null,
    };

    if (screen == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, '홈', false),
      (Icons.chat_bubble_outline, '대화', false),
      (Icons.image_outlined, '추억', true),
      (Icons.settings_outlined, '설정', false),
    ];

    return Container(
      height: 72.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in items)
            InkWell(
              onTap: item.$3 ? null : () => _openTab(context, item.$2),
              borderRadius: BorderRadius.circular(14.r),
              child: SizedBox(
                width: 58.w,
                height: 62.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 22.sp,
                      color: item.$3 ? _yellow : _muted,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: item.$3 ? _brown : _muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: BoxDecoration(
                        color: item.$3 ? _yellow : Colors.transparent,
                        shape: BoxShape.circle,
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

TextStyle _caption() {
  return TextStyle(
    fontSize: 11.sp,
    color: _muted,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
}
