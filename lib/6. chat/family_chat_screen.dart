import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../4. home/home_and_alert_center.dart';
import '../5. memory/memory_add_flow.dart';
import '../9. set/settings_flow.dart';
import '../services/session_store.dart';
import '../services/settings_api.dart';

const Color _bg = Color(0xFFFBF6EE);
const Color _brown = Color(0xFF936249);
const Color _dark = Color(0xFF2F2521);
const Color _muted = Color(0xFF7C6B61);
const Color _line = Color(0xFFE8DCD2);
const Color _yellow = Color(0xFFF6C43D);

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key});

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;
  final SettingsApi _api = SettingsApi();

  /// 10초마다 다시 받아온다. 서버에 실시간 채널이 없어서 폴링뿐이다.
  static const Duration _pollInterval = Duration(seconds: 10);

  List<_ChatMessage> _messages = [];
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;
  bool _refreshing = false;
  String? _error;

  int? _userId;
  int? _myProtectorId;
  String _elderInitial = '';
  final Map<int, String> _memberInitials = {};

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _messageController.removeListener(_handleTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 대화방을 열 때 한 번: 어르신·가족 이름을 챙기고 첫 목록을 받는다.
  /// 이름은 말풍선 옆 한 글자 표시에만 쓰므로 실패해도 대화는 보여준다.
  Future<void> _bootstrap() async {
    try {
      final profile = await _api.myProfile();
      final user = profile.mainUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _error = '연결된 어르신이 없어요.\n가족 연결을 먼저 마쳐주세요.';
        });
        return;
      }
      _userId = user.userId;
      _elderInitial = user.name.isEmpty ? '' : user.name.substring(0, 1);
      _myProtectorId = await SessionStore.protectorId();

      try {
        final family = await _api.familyMembers(user.userId);
        for (final m in family.members) {
          _memberInitials[m.protectorId] =
              m.name.isEmpty ? '' : m.name.substring(0, 1);
        }
      } catch (_) {
        // 이름을 못 받아도 '가족' 으로 보여주면 된다.
      }

      await _refresh();
      if (!mounted) return;
      setState(() => _loading = false);
      _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    } on ApiException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = '대화를 불러오지 못했어요.'; });
      }
    }
  }

  /// 목록을 다시 받아 화면에 반영한다.
  ///
  /// 이미 갖고 있는 메시지는 그대로 둔다. 사진 URL 이 조회할 때마다 새로
  /// 서명돼서 내려오는데, 그대로 갈아끼우면 10초마다 같은 사진을 다시
  /// 내려받고 깜빡인다.
  Future<void> _refresh() async {
    final userId = _userId;
    if (userId == null || _refreshing) return;
    _refreshing = true;
    try {
      final fetched = await _api.chatMessages(userId);
      if (!mounted) return;
      final existing = {for (final m in _messages) m.messageId: m};
      final merged = [
        for (final m in fetched) existing[m.messageId] ?? _toDisplay(m),
      ];
      final grew = merged.length > _messages.length;
      setState(() => _messages = merged);
      if (grew) _scrollToBottom();
    } catch (_) {
      // 폴링 실패는 조용히 넘긴다. 다음 주기에 다시 시도한다.
    } finally {
      _refreshing = false;
    }
  }

  /// 서버 메시지를 말풍선이 쓰는 형태로 바꾼다.
  _ChatMessage _toDisplay(ChatMessage m) {
    final mine = m.senderType == 'protector' && m.senderId == _myProtectorId;
    final String sender;
    if (mine) {
      sender = '나';
    } else if (m.senderType == 'user') {
      sender = _elderInitial;
    } else {
      sender = _memberInitials[m.senderId] ?? '가족';
    }

    final _MessageKind kind;
    if (m.isSystem) {
      kind = _MessageKind.notice;
    } else if (m.hasPhoto) {
      kind = _MessageKind.photo;
    } else {
      kind = _MessageKind.text;
    }

    return _ChatMessage(
      messageId: m.messageId,
      sender: sender,
      time: _formatTime(m.createdAt),
      text: m.content ?? '',
      mine: mine,
      kind: kind,
      imageUrl: m.imageUrl,
    );
  }

  void _handleTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_hasText == hasText) return;
    setState(() => _hasText = hasText);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _sendMessage() async {
    final userId = _userId;
    final text = _messageController.text.trim();
    if (userId == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _api.sendChatMessage(userId, content: text);
      _messageController.clear();
      await _refresh();
      _scrollToBottom();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('메시지를 보내지 못했어요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// 사진은 먼저 올리고, 받은 URL 로 메시지를 보낸다.
  Future<void> _pickAndSendPhoto() async {
    final userId = _userId;
    if (userId == null || _sending) return;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() => _sending = true);
    try {
      final imageUrl = await _api.uploadImage(
        bytes: bytes,
        // 서버가 확장자로 이미지 종류를 가리므로 원본 이름을 그대로 넘긴다.
        filename: picked.name,
        userId: userId,
      );
      await _api.sendChatMessage(userId, imageUrl: imageUrl);
      await _refresh();
      _scrollToBottom();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('사진을 보내지 못했어요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime? at) {
    if (at == null) return '';
    final period = at.hour < 12 ? '오전' : '오후';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  Widget _buildMessages() {
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
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          '아직 나눈 이야기가 없어요.\n첫 인사를 남겨보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, height: 1.5, color: _muted),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 12.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _MessageRow(message: _messages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          const _Header(),
          SizedBox(height: 12.h),
          Expanded(child: _buildMessages()),
          _InputBar(
            controller: _messageController,
            canSend: _hasText && !_sending && _userId != null,
            onSend: _sendMessage,
            onPhoto: _pickAndSendPhoto,
          ),
          const SizedBox(height: 10),
          const _ChatNavBar(),
          SizedBox(height: 8.h),
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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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
        const Text(
          '가족 대화방',
          style: TextStyle(
            fontSize: 17,
            color: _dark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TinyMember(color: Color(0xFFBD8A5F), label: '박'),
              _TinyMember(color: Color(0xFFD9AA22), label: '민'),
              _TinyMember(color: Color(0xFF5D9E41), label: '서'),
              SizedBox(width: 3),
              Text(
                '4명',
                style: TextStyle(
                  fontSize: 9,
                  color: _muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TinyMember extends StatelessWidget {
  const _TinyMember({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      margin: const EdgeInsets.only(right: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 7,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.kind == _MessageKind.notice) {
      return _NoticeBubble(text: message.text, time: message.time);
    }

    if (message.kind == _MessageKind.photo) {
      return _ChatBubbleShell(
        sender: message.sender,
        time: message.time,
        mine: message.mine,
        child: _PhotoBubble(imageUrl: message.imageUrl),
      );
    }

    return _ChatBubbleShell(
      sender: message.sender,
      time: message.time,
      mine: message.mine,
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 13,
          height: 1.35,
          color: message.mine ? Colors.white : _dark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChatBubbleShell extends StatelessWidget {
  const _ChatBubbleShell({
    required this.sender,
    required this.time,
    required this.mine,
    required this.child,
  });

  final String sender;
  final String time;
  final bool mine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: mine ? 230.w : 244.w),
      padding: EdgeInsets.symmetric(horizontal: mine ? 15 : 13, vertical: 11),
      decoration: BoxDecoration(
        color: mine ? _brown : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 4),
          bottomRight: Radius.circular(mine ? 4 : 14),
        ),
        border: mine ? null : Border.all(color: _line),
      ),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine) _Avatar(label: sender),
          if (!mine) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 8,
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                bubble,
              ],
            ),
          ),
          if (mine && time.isNotEmpty) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 8,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = label == '박'
        ? const Color(0xFFAF8067)
        : label == '민'
        ? const Color(0xFFD6A828)
        : const Color(0xFF6AA642);

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoticeBubble extends StatelessWidget {
  const _NoticeBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_outlined,
              color: _brown,
              size: 12,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                time.isEmpty ? text : '$time\n$text',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  color: _muted,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoBubble extends StatelessWidget {
  const _PhotoBubble({this.imageUrl});

  /// 서버가 준 조회용 URL. 만료되므로 목록을 다시 받으면 새로 발급된다.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 174.w,
          height: 112.h,
          decoration: BoxDecoration(
            color: const Color(0xFFC48F70),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? CustomPaint(painter: _PhotoPainter())
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  // 서명이 만료됐거나 네트워크가 끊겼을 때 빈 칸 대신 보여준다.
                  errorBuilder: (_, _, _) =>
                      CustomPaint(painter: _PhotoPainter()),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _dark.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              '인형 화면에 표시',
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.canSend,
    required this.onSend,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhoto,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.add, color: _brown, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (canSend) onSend();
              },
              decoration: InputDecoration(
                isDense: true,
                hintText: '${SessionStore.elderHonorific}께 전할 말을 입력하세요',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB8AAA0),
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: _dark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? onSend : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: canSend ? _brown : const Color(0xFFE6D7CB),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Icon(Icons.near_me, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatNavBar extends StatelessWidget {
  const _ChatNavBar();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, '홈', false),
      (Icons.chat_bubble_outline, '대화', true),
      (Icons.image_outlined, '추억', false),
      (Icons.settings_outlined, '설정', false),
    ];

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
          for (final item in items)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final Widget? screen = switch (item.$2) {
                  '홈' => const HomeAndAlertPreview(),
                  '추억' => const MemoryAddFlow(),
                  '설정' => const SettingsFlow(),
                  _ => null,
                };
                if (screen == null) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                );
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

class _PhotoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()..color = const Color(0xFF9F6F55);
    final foregroundPaint = Paint()..color = const Color(0xFF8A624E);
    final sunPaint = Paint()..color = const Color(0xFFFFF1D2);

    final backPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.36, size.height * 0.46)
      ..lineTo(size.width * 0.62, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final frontPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.43, size.height * 0.58)
      ..lineTo(size.width * 0.73, size.height * 0.82)
      ..lineTo(size.width, size.height * 0.63)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.2),
      16,
      sunPaint,
    );
    canvas.drawPath(backPath, mountainPaint);
    canvas.drawPath(frontPath, foregroundPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.86),
        width: 34,
        height: 10,
      ),
      Paint()..color = const Color(0xFF6E4C3A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _MessageKind { text, notice, photo }

class _ChatMessage {
  const _ChatMessage({
    required this.messageId,
    required this.sender,
    required this.time,
    required this.text,
    this.mine = false,
    this.kind = _MessageKind.text,
    this.imageUrl,
  });

  final int messageId;

  /// 말풍선 옆에 보여줄 한 글자(내 메시지는 '나').
  final String sender;
  final String time;
  final String text;
  final bool mine;
  final _MessageKind kind;
  final String? imageUrl;
}
