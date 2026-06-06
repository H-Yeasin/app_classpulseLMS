import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/chat/widgets/chat_message_input_bar.dart';
import 'package:opalmer_education/chat/widgets/chat_messages_panel.dart';
import 'package:opalmer_education/chat/widgets/chat_screen_app_bar.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/teacher_role/profile_screen/language.dart';

import '../models/chat_role.dart';
import '../models/chat_session_model.dart';
import '../providers/chat_provider.dart';
import '../services/call_permission_service.dart';
import 'block_user.dart';
import 'call.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatSessionModel session;
  final ChatRole role;

  const ChatScreen({super.key, required this.session, required this.role});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatNotifierProvider.notifier).loadMessages(widget.session.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatNotifierProvider.notifier)
        .sendMessage(widget.session.id, text);
    _messageController.clear();

    Timer(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startCall({
    required BuildContext context,
    required String? currentUserId,
    required CallMediaType callType,
  }) async {
    if (widget.session.type != ChatSessionType.direct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group calling is not available in this build yet.'),
        ),
      );
      return;
    }

    final peerId = widget.session.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (peerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to determine who to call in this room.'),
        ),
      );
      return;
    }

    final permissionsGranted =
        await CallPermissionService.ensureCallPermissions(
          context,
          callType: callType,
        );
    if (!permissionsGranted || !context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          name: widget.session.title,
          imageUrl: widget.session.avatarUrl ?? '',
          roomId: widget.session.id,
          peerId: peerId,
          callType: callType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.session.id));
    final currentUser = ref.watch(authStateProvider);
    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatScreenAppBar(
        title: widget.session.title,
        avatarUrl: widget.session.avatarUrl,
        showActions: widget.session.type == ChatSessionType.direct,
        onBack: () => Navigator.pop(context),
        onOpenProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BlockUserScreen(userName: widget.session.title),
            ),
          );
        },
        onOpenLanguage: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LanguageScreen()),
          );
        },
        onStartAudioCall: () {
          _startCall(
            context: context,
            currentUserId: currentUser?.id,
            callType: CallMediaType.audio,
          );
        },
        onStartVideoCall: () {
          _startCall(
            context: context,
            currentUserId: currentUser?.id,
            callType: CallMediaType.video,
          );
        },
        // onStartVideoCall: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesPanel(
              isLoading: chatState.isLoading,
              error: chatState.error,
              messages: messages,
              currentUserId: currentUser?.id,
              scrollController: _scrollController,
            ),
          ),
          ChatMessageInputBar(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
