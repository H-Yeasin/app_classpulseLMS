import 'package:flutter/material.dart';
import 'package:opalmer_education/teacher_role/profile_screen/language.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

class GroupChatMessageList extends StatelessWidget {
  const GroupChatMessageList({super.key});

  static const List<_MockGroupMessage> _messages = [
    _MockGroupMessage(text: 'Good Morning!', time: '17:47', isMe: true),
    _MockGroupMessage(
      text: 'Hey! How are you?',
      time: '17:47',
      isMe: false,
      imageUrl: 'https://i.pravatar.cc/150?u=sarah',
    ),
    _MockGroupMessage(
      text: 'He skips homework sometimes.',
      time: '17:47',
      isMe: true,
    ),
    _MockGroupMessage(
      text: 'Science is going well.',
      time: '17:47',
      isMe: false,
      imageUrl: 'https://i.pravatar.cc/150?u=teacher2',
    ),
    _MockGroupMessage(
      text: 'Any suggestions for home?',
      time: '17:47',
      isMe: false,
      imageUrl: 'https://i.pravatar.cc/150?u=parent1',
    ),
    _MockGroupMessage(
      text: "Short quizzes, fun learning. I'll share resources.",
      time: '17:47',
      isMe: true,
    ),
    _MockGroupMessage(
      text: 'Thank you very much.',
      time: '17:47',
      isMe: false,
      imageUrl: 'https://i.pravatar.cc/150?u=sarah',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: _messages
          .map((message) => _GroupChatMessageBubble(message: message))
          .toList(),
    );
  }
}

class _GroupChatMessageBubble extends StatelessWidget {
  final _MockGroupMessage message;

  const _GroupChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isMe && message.imageUrl != null) ...[
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(ApiConstants.buildImageUrl(message.imageUrl!)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: CustomPaint(
                  painter: _GroupBubblePainter(
                    isMe: message.isMe,
                    color: message.isMe
                        ? const Color(0xFFF1F0F0)
                        : const Color(0xFF871DAD),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: message.isMe
                                ? const Color(0xFF222222)
                                : Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.time,
                              style: TextStyle(
                                fontSize: 10,
                                color: message.isMe
                                    ? Colors.grey.shade400
                                    : Colors.white70,
                              ),
                            ),
                            if (message.isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all,
                                size: 14,
                                color: Color(0xFF4FA0F3),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!message.isMe) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      'Translate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: const Color(0xFF871DAD).withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupBubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  _GroupBubblePainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const r = 16.0;
    final w = size.width;
    final h = size.height;

    if (isMe) {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, h - 8);
      path.lineTo(w + 8, h);
      path.lineTo(w - r, h);
      path.quadraticBezierTo(w - r - 4, h, w - r - 4, h);
      path.lineTo(r, h);
      path.quadraticBezierTo(0, h, 0, h - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    } else {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, h - r);
      path.quadraticBezierTo(w, h, w - r, h);
      path.lineTo(r, h);
      path.lineTo(-8, h);
      path.lineTo(0, h - 8);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockGroupMessage {
  final String text;
  final String time;
  final bool isMe;
  final String? imageUrl;

  const _MockGroupMessage({
    required this.text,
    required this.time,
    required this.isMe,
    this.imageUrl,
  });
}
