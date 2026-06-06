import 'package:flutter/material.dart';

import '../models/message_model.dart';
import 'chat_message_bubble.dart';

class ChatMessagesPanel extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<MessageModel> messages;
  final String? currentUserId;
  final ScrollController scrollController;

  const ChatMessagesPanel({
    super.key,
    required this.isLoading,
    required this.error,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && messages.isEmpty) {
      return Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final isMe = message.senderId == currentUserId;
        return ChatMessageBubble(
          text: message.text,
          time:
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
          isMe: isMe,
          status: message.deliveryStatus,
        );
      },
    );
  }
}
