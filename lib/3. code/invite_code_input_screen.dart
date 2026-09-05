import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../main_shell.dart';
import '../services/session_store.dart';
import '../services/settings_api.dart';
import 'first_registration_flow.dart';

const Color _background = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF9B674C);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _soft = Color(0xFFF5E9DF);

class InviteCodeInputScreen extends StatefulWidget {
  const InviteCodeInputScreen({
    super.key,
    this.onBack,
    this.onConnected,
  });

  final VoidCallback? onBack;
  final ValueChanged<String>? onConnected;

  @override
  State<InviteCodeInputScreen> createState() => _InviteCodeInputScreenState();
}

class _InviteCodeInputScreenState extends State<InviteCodeInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SettingsApi _api = SettingsApi();

  bool _busy = false;

  String get _code => _controller.text;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// 코드를 확인한다. 없는 코드·이미 쓴 코드·기한 지난 코드는 서버가 사유를 알려준다.
  ///
  /// 아직 가입 전이라면(토큰 없음) 코드가 쓸 수 있는지만 확인하고 가입 흐름으로
  /// 넘긴다. 합류는 전화번호 인증이 끝나는 순간 서버가 함께 처리한다.
  /// 이미 로그인한 사람이 이 화면에 오면 예전처럼 바로 연결한다.
  Future<void> _connect() async {
    if (_code.length != 6 || _busy) return;

    setState(() => _busy = true);
    try {
      final token = await SessionStore.accessToken();
      if (token == null || token.isEmpty) {
        final preview = await _api.checkInviteCode(_code);
        if (!mounted) return;
        if (widget.onConnected != null) {
          widget.onConnected!(_code);
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FirstRegistrationFlow(
              inviteCode: _code,
              elderName: preview.userName,
            ),
          ),
        );
        return;
      }

      final linked = await _api.acceptInviteCode(_code);
      if (!mounted) return;
      _snack('${linked.name}님의 가족으로 연결되었어요.');
      if (widget.onConnected != null) {
        widget.onConnected!(_code);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
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
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.chevron_left, color: _dark),
                      ),
                      Text(
                        '코드 입력',
                        style: TextStyle(
                          color: _dark,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    '1 / 2 단계',
                    style: TextStyle(
                      color: _brown,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '가족이 알려준 6자리 코드를 입력하세요',
                    style: TextStyle(
                      color: _dark,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '대소문자 구분 없어요',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 130.h),
                  GestureDetector(
                    onTap: _focusNode.requestFocus,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final value = index < _code.length
                                ? _code[index]
                                : '';
                            return Container(
                              width: 39.w,
                              height: 52.h,
                              margin: EdgeInsets.symmetric(horizontal: 4.w),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: value.isEmpty ? Colors.white : _soft,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: value.isEmpty ? _line : _brown,
                                ),
                              ),
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: _brown,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          }),
                        ),
                        Opacity(
                          opacity: 0.01,
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            textCapitalization: TextCapitalization.characters,
                            keyboardType: TextInputType.visiblePassword,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(6),
                              _UpperCaseTextFormatter(),
                            ],
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _connect(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _code.length == 6 && !_busy ? _connect : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _brown,
                        disabledBackgroundColor: const Color(0xFFD2C5BC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                      ),
                      child: Text(
                        '가족으로 연결할게요',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
