import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../5. memory/memory_add_flow.dart';

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
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      sender: '인형',
      time: '오전 9시 14분',
      text: '어머니가 가족들과 이야기하고 싶다고 하셨어요',
      kind: _MessageKind.notice,
    ),
    const _ChatMessage(
      sender: '박',
      time: '박순자님 오전 9:14',
      text: '우리 손주들 보고 싶네.\n요새 잘 지내나 모르겠어.',
    ),
    const _ChatMessage(
      sender: '나',
      time: '9:15',
      text: '엄마 저 잘 지내요.\n다음 주말에 갈게요.',
      mine: true,
    ),
    const _ChatMessage(
      sender: '민',
      time: '김민수 오전 9:16',
      text: '어머니 저도요.\n사진 한 장 보내드릴게요.',
    ),
    const _ChatMessage(
      sender: '민',
      time: '',
      text: '',
      kind: _MessageKind.photo,
    ),
    const _ChatMessage(sender: '민', time: '', text: '저번 주말 손주랑 찍은 거예요'),
    const _ChatMessage(
      sender: '인형',
      time: '',
      text: '인형 화면으로 사진을 보여드리는 중이에요',
      kind: _MessageKind.notice,
    ),
    const _ChatMessage(
      sender: '박',
      time: '박순자님 오전 9:18',
      text: '아이고, 많이 컸네\n우리 예쁜 강아지.',
    ),
    const _ChatMessage(
      sender: '박',
      time: '박순자님 오전 9:30',
      text: '',
      kind: _MessageKind.photo,
    ),
    const _ChatMessage(sender: '서', time: '', text: '할머니-저예요. 사랑해요.'),
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_hasText == hasText) return;
    setState(() => _hasText = hasText);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(sender: '나', time: _formatNow(), text: text, mine: true),
      );
      _messageController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatNow() {
    final now = DateTime.now();
    final period = now.hour < 12 ? '오전' : '오후';
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          SizedBox(height: 12.h),
          const _Header(),
          SizedBox(height: 12.h),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 12.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _MessageRow(message: _messages[index]),
            ),
          ),
          _InputBar(
            controller: _messageController,
            canSend: _hasText,
            onSend: _sendMessage,
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
        child: const _PhotoBubble(),
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
  const _PhotoBubble();

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
          child: CustomPaint(painter: _PhotoPainter()),
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
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

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
            onTap: () {},
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
              decoration: const InputDecoration(
                isDense: true,
                hintText: '어머님께 전할 말을 입력하세요',
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
                if (item.$2 == '홈') {
                  Navigator.maybePop(context);
                }
                if (item.$2 == '추억') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemoryAddFlow()),
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
    required this.sender,
    required this.time,
    required this.text,
    this.mine = false,
    this.kind = _MessageKind.text,
  });

  final String sender;
  final String time;
  final String text;
  final bool mine;
  final _MessageKind kind;
}
