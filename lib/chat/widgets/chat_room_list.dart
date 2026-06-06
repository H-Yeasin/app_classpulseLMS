import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/models/chat_role.dart';
import 'package:opalmer_education/chat/models/chat_session_model.dart';

import 'chat_session_slidable_item.dart';

class ChatRoomList extends StatelessWidget {
  final List<ChatSessionModel> sessions;
  final int tab;
  final ChatRole role;
  final int? openedIndex;
  final void Function(int tab, int index) onSlide;
  final String? emptyLabel;
  final void Function(ChatSessionModel session)? onSessionTap;
  final List<ChatSessionAction> Function(ChatSessionModel session)?
  actionsBuilder;

  const ChatRoomList({
    super.key,
    required this.sessions,
    required this.tab,
    required this.role,
    required this.openedIndex,
    required this.onSlide,
    this.emptyLabel,
    this.onSessionTap,
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          emptyLabel ?? _emptyLabel,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: sessions.length,
      itemBuilder: (context, index) => ChatSessionSlidableItem(
        index: index,
        tab: tab,
        openedIndex: openedIndex,
        onSlide: onSlide,
        session: sessions[index],
        role: role,
        onTap: onSessionTap == null
            ? null
            : () => onSessionTap!(sessions[index]),
        actions:
            actionsBuilder?.call(sessions[index]) ??
            _actionsForSession(sessions[index]),
      ),
    );
  }

  String get _emptyLabel {
    switch (tab) {
      case 0:
        return 'No chats found';
      case 1:
        return 'No drafts found';
      default:
        return role == ChatRole.parent
            ? 'No teachers found'
            : 'No groups found';
    }
  }

  List<ChatSessionAction> _actionsForSession(ChatSessionModel session) {
    if (session.type == ChatSessionType.direct) {
      return [
        ChatSessionAction(
          color: const Color(0xFFC4C4C4),
          icon: Icons.more_horiz,
          label: 'More',
        ),
        ChatSessionAction(
          color: const Color(0xFFEA4335),
          icon: Icons.delete_outline,
          label: 'Delete',
        ),
      ];
    }

    return [
      ChatSessionAction(
        color: const Color(0xFFEA4335),
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
    ];
  }
}
