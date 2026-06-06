import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/widgets/chat_simple_app_bar.dart';
import 'package:opalmer_education/chat/widgets/compose_message_actions.dart';
import 'package:opalmer_education/chat/widgets/compose_message_form.dart';

import '../models/chat_role.dart';
import '../models/chat_session_model.dart';
import 'chat_dashboard.dart';
import 'chat_screen.dart';

class ComposeMessageScreen extends StatefulWidget {
  final ChatSessionModel session;
  final ChatRole role;

  const ComposeMessageScreen({
    super.key,
    required this.session,
    required this.role,
  });

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveAsDraft() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDashboard(initialTab: 1, role: widget.role),
      ),
      (route) => false,
    );
  }

  void _send() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(session: widget.session, role: widget.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ChatSimpleAppBar(title: 'Compose Message'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ComposeMessageForm(controller: _controller),
          const Spacer(),
          const SizedBox(height: 20),
          ComposeMessageActions(onSaveDraft: _saveAsDraft, onSend: _send),
        ],
      ),
    );
  }
}
