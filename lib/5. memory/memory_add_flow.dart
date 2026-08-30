import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../services/session_store.dart';
import '../main_shell.dart';
import '../services/settings_api.dart';

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

/// 입력 화면이 모아 넘겨주는 값. 저장은 흐름(Flow) 쪽에서 한다.
typedef MemorySubmit =
    Future<void> Function({
      required Uint8List photo,
      required String filename,
      required String title,
      required String period,
      required String description,
    });

class _MemoryAddFlowState extends State<MemoryAddFlow> {
  final SettingsApi _api = SettingsApi();
  bool _saved = false;

  /// 연결된 어르신. 화면 문구와 저장에 모두 쓰므로 들어올 때 한 번만 받는다.
  LinkedUser? _elder;

  @override
  void initState() {
    super.initState();
    _loadElder();
  }

  Future<void> _loadElder() async {
    try {
      final elder = (await _api.myProfile()).mainUser;
      if (mounted) setState(() => _elder = elder);
    } catch (_) {
      // 이름을 못 받아도 입력은 할 수 있게 둔다. 저장할 때 다시 확인한다.
    }
  }

  /// 사진을 먼저 올리고, 받은 URL 로 추억을 등록한다.
  /// 실패하면 예외를 그대로 올려 입력 화면이 사유를 보여주게 한다.
  Future<void> _saveMemory({
    required Uint8List photo,
    required String filename,
    required String title,
    required String period,
    required String description,
  }) async {
    final user = _elder ?? (await _api.myProfile()).mainUser;
    if (user == null) {
      throw ApiException('연결된 어르신이 없어요. 가족 연결을 먼저 마쳐주세요.', 400);
    }
    final imageUrl = await _api.uploadImage(
      bytes: photo,
      filename: filename,
      userId: user.userId,
    );
    await _api.createMemory(
      userId: user.userId,
      imageUrl: imageUrl,
      title: title,
      period: period,
      description: description,
    );
    if (mounted) setState(() => _saved = true);
  }

  void _backToForm() {
    setState(() => _saved = false);
  }

  void _goHome() {
    MainShellScope.maybeOf(context)?.selectTab(AppTab.home);
  }

  @override
  Widget build(BuildContext context) {
    return _saved
        ? MemorySavedScreen(onBack: _backToForm, onConfirm: _goHome)
        : MemoryAddScreen(onSave: _saveMemory, elderName: _elder?.name);
  }
}

class MemoryAddScreen extends StatefulWidget {
  const MemoryAddScreen({super.key, required this.onSave, this.elderName});

  final MemorySubmit onSave;

  /// 연결된 어르신 이름. 아직 못 받았으면 null.
  final String? elderName;

  @override
  State<MemoryAddScreen> createState() => _MemoryAddScreenState();
}

class _MemoryAddScreenState extends State<MemoryAddScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  Uint8List? _selectedPhoto;
  String _selectedPhotoName = '';
  int _selectedWhen = 0;
  bool _busy = false;

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
    setState(() {
      _selectedPhoto = bytes;
      _selectedPhotoName = picked.name;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// 저장 버튼. 사진과 제목은 서버에서도 필수라 올리기 전에 먼저 확인한다.
  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final photo = _selectedPhoto;
    if (photo == null) {
      _snack('사진을 한 장 골라주세요.');
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _snack('한 줄 제목을 적어주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.onSave(
        photo: photo,
        filename: _selectedPhotoName,
        title: title,
        period: _whenOptions[_selectedWhen],
        description: _storyController.text.trim(),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      // 성공하면 이 화면이 사라지므로 mounted 를 확인한다.
      if (mounted) setState(() => _busy = false);
    }
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
              _Header(
                title: '새 추억',
                actionText: _busy ? '저장 중…' : '저장',
                onAction: _busy ? null : _submit,
              ),
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
                      _Label(
                        widget.elderName == null
                            ? '나눌 이야기'
                            : '${widget.elderName}님과 나눌 이야기',
                      ),
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
                () => MainShellScope.maybeOf(context)?.selectTab(AppTab.home),
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

TextStyle _caption() {
  return TextStyle(
    fontSize: 11.sp,
    color: _muted,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
}
