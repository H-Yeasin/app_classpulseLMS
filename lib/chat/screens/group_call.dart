import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/widgets/chat_message_input_bar.dart';
import 'package:opalmer_education/chat/widgets/chat_simple_app_bar.dart';
import 'package:opalmer_education/chat/widgets/group_chat_message_list.dart';
import 'package:opalmer_education/teacher_role/profile_screen/language.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupName;

  const GroupChatScreen({super.key, required this.groupName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatSimpleAppBar(
        title: widget.groupName,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF871DAD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Expanded(child: GroupChatMessageList()),
          ChatMessageInputBar(controller: _messageController, onSend: () {}),
        ],
      ),
    );
  }
}
