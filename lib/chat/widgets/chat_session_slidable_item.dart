import 'package:flutter/material.dart';
import 'package:opalmer_education/chat/screens/chat_screen.dart';

import 'package:opalmer_education/core/constants/api_constants.dart';

import '../models/chat_role.dart';
import '../models/chat_session_model.dart';

class ChatSessionAction {
  final Color color;
  final IconData icon;
  final String label;

  ChatSessionAction({
    required this.color,
    required this.icon,
    required this.label,
  });
}

class ChatSessionSlidableItem extends StatefulWidget {
  final int index;
  final int tab;
  final int? openedIndex;
  final void Function(int tab, int index) onSlide;
  final ChatSessionModel session;
  final ChatRole role;
  final List<ChatSessionAction> actions;
  final VoidCallback? onTap;

  const ChatSessionSlidableItem({
    super.key,
    required this.index,
    required this.tab,
    required this.openedIndex,
    required this.onSlide,
    required this.session,
    required this.role,
    required this.actions,
    this.onTap,
  });

  @override
  State<ChatSessionSlidableItem> createState() =>
      _ChatSessionSlidableItemState();
}

class _ChatSessionSlidableItemState extends State<ChatSessionSlidableItem>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  final double _actionWidth = 70.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = _controller.drive(Tween<double>(begin: 0, end: 1));
    _controller.addListener(() {
      setState(() {
        _dragExtent = _animation.value;
      });
    });
  }

  @override
  void didUpdateWidget(ChatSessionSlidableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uniqueId = widget.tab * 1000 + widget.index;
    if (widget.openedIndex != uniqueId && _dragExtent != 0) {
      _animateTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxExtent => -(_actionWidth * widget.actions.length);
  bool get _canSlide => widget.actions.isNotEmpty;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_canSlide) return;
    if (details.primaryDelta! < 0 && _dragExtent == 0) {
      widget.onSlide(widget.tab, widget.index);
    }
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < _maxExtent) _dragExtent = _maxExtent;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_canSlide) return;
    if (_dragExtent < _maxExtent / 2) {
      _animateTo(_maxExtent);
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target) {
    _controller.stop();
    _animation = _controller.drive(
      Tween<double>(begin: _dragExtent, end: target),
    );
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actions
                  .map(
                    (action) => Container(
                      width: _actionWidth,
                      color: action.color,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: Colors.white),
                          Text(
                            action.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _canSlide ? _onHorizontalDragUpdate : null,
            onHorizontalDragEnd: _canSlide ? _onHorizontalDragEnd : null,
            onTap:
                widget.onTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(session: session, role: widget.role),
                    ),
                  );
                },
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    if (session.avatarUrl != null &&
                        session.avatarUrl!.isNotEmpty)
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                            ApiConstants.buildImageUrl(session.avatarUrl!)),
                      )
                    else
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF871DAD).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _sessionIcon(session),
                          color: const Color(0xFF871DAD),
                          size: 28,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                session.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              Text(
                                session.displayDate,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (session.previewType !=
                                  MessagePreviewType.text) ...[
                                Icon(
                                  _previewIcon(session.previewType),
                                  size: 16,
                                  color: const Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 4),
                              ],
                              if (session.showReadReceipt) ...[
                                const Icon(
                                  Icons.done_all,
                                  size: 16,
                                  color: Color(0xFF4FA0F3),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  session.subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  IconData _sessionIcon(ChatSessionModel session) {
    switch (session.type) {
      case ChatSessionType.draft:
        return Icons.description_outlined;
      case ChatSessionType.group:
        return widget.role == ChatRole.parent
            ? Icons.co_present_outlined
            : Icons.school_outlined;
      case ChatSessionType.direct:
        return Icons.person_outline;
    }
  }

  IconData? _previewIcon(MessagePreviewType previewType) {
    switch (previewType) {
      case MessagePreviewType.voice:
        return Icons.mic_none_outlined;
      case MessagePreviewType.photo:
        return Icons.camera_alt_outlined;
      case MessagePreviewType.text:
        return null;
    }
  }
}
