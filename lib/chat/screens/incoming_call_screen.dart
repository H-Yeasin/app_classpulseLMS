import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/chat/providers/call_provider.dart';
import 'package:opalmer_education/chat/screens/call.dart';
import 'package:opalmer_education/chat/services/call_permission_service.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final IncomingCall call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _actionInProgress = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(callNotifierProvider, (previous, next) {
      if (_actionInProgress) return;

      final previousRoomId = previous?.incomingCall?.roomId;
      final currentRoomId = next.incomingCall?.roomId;
      if (previousRoomId == widget.call.roomId &&
          currentRoomId == null &&
          mounted) {
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 72,
                  backgroundColor: Colors.white10,
                  backgroundImage:
                      widget.call.callerAvatar != null &&
                          widget.call.callerAvatar!.isNotEmpty
                      ? NetworkImage(
                          ApiConstants.buildImageUrl(widget.call.callerAvatar!),
                        )
                      : null,
                  child:
                      (widget.call.callerAvatar == null ||
                          widget.call.callerAvatar!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 56,
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.call.callType == CallMediaType.video
                      ? 'Incoming video call'
                      : 'Incoming audio call',
                  // 'Incoming audio call',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      color: const Color(0xFFEA4335),
                      icon: Icons.call_end,
                      label: 'Decline',
                      onTap: _declineCall,
                    ),
                    const SizedBox(width: 24),
                    _ActionButton(
                      color: const Color(0xFF34A853),
                      icon: widget.call.callType == CallMediaType.video
                          ? Icons.videocam
                          : Icons.call,
                      // icon: Icons.call,
                      label: 'Accept',
                      onTap: _acceptCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _declineCall() async {
    _actionInProgress = true;
    await ref
        .read(callNotifierProvider.notifier)
        .declineIncomingCall(widget.call);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
    _actionInProgress = false;
  }

  Future<void> _acceptCall() async {
    _actionInProgress = true;
    final permissionsGranted =
        await CallPermissionService.ensureCallPermissions(
          context,
          callType: widget.call.callType,
        );
    if (!permissionsGranted || !mounted) {
      _actionInProgress = false;
      return;
    }

    if (widget.call.callLogId != null) {
      await ref
          .read(callNotifierProvider.notifier)
          .markCallAnswered(widget.call.callLogId!);
    }
    ref.read(callNotifierProvider.notifier).acceptIncomingCall(widget.call);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CallScreen(
          name: widget.call.callerName,
          imageUrl: widget.call.callerAvatar ?? '',
          roomId: widget.call.roomId,
          peerId: widget.call.callerId,
          isIncoming: true,
          callType: widget.call.callType,
          callLogId: widget.call.callLogId,
        ),
      ),
    );
    _actionInProgress = false;
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
