import 'package:flutter/material.dart';

class ComposeMessageForm extends StatelessWidget {
  final TextEditingController controller;

  const ComposeMessageForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Message',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF222222),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
