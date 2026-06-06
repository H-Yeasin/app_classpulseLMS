import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/widgets/block_user_form.dart';
import 'package:opalmer_education/chat/widgets/chat_simple_app_bar.dart';

class BlockUserScreen extends StatefulWidget {
  final String userName;

  const BlockUserScreen({super.key, required this.userName});

  @override
  State<BlockUserScreen> createState() => _BlockUserScreenState();
}

class _BlockUserScreenState extends State<BlockUserScreen> {
  String _selectedReason = 'Other';
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _selectReason(String reason) {
    setState(() {
      _selectedReason = reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ChatSimpleAppBar(title: 'Block'),
      body: BlockUserForm(
        userName: widget.userName,
        selectedReason: _selectedReason,
        reasonController: _reasonController,
        onReasonSelected: _selectReason,
        onBlock: () {},
      ),
    );
  }
}
