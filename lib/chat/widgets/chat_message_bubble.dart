import 'package:flutter/material.dart';

import '../models/message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final MessageDeliveryStatus status;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: CustomPaint(
              painter: UnifiedBubblePainter(
                isMe: isMe,
                color: isMe ? const Color(0xFFF1F0F0) : const Color(0xFF871DAD),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? const Color(0xFF222222) : Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.grey.shade400 : Colors.white70,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            status == MessageDeliveryStatus.read
                                ? Icons.done_all
                                : Icons.done,
                            size: 14,
                            color: status == MessageDeliveryStatus.read
                                ? const Color(0xFF4FA0F3)
                                : Colors.grey.shade400,
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
    );
  }
}

class UnifiedBubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  UnifiedBubblePainter({required this.isMe, required this.color});

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
