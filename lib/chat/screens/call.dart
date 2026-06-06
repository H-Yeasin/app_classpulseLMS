import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:opalmer_education/chat/controllers/call_session_controller.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/chat/providers/call_provider.dart';
import 'package:opalmer_education/chat/services/call_permission_service.dart';
import 'package:opalmer_education/chat/services/call_socket_service.dart';
import 'package:opalmer_education/chat/widgets/call_screen_body.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String name;
  final String imageUrl;
  final String? roomId;
  final String? peerId;
  final bool isIncoming;
  final CallMediaType callType;
  final String? callLogId;

  const CallScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    this.roomId,
    this.peerId,
    this.isIncoming = false,
    this.callType = CallMediaType.audio,
    this.callLogId,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final CallSocketService _callSocketService = CallSocketService();

  CallSessionController? _sessionController;
  Timer? _durationTimer;
  Timer? _ringTimeoutTimer;
  String? _callLogId;
  DateTime? _connectedAt;
  String _statusText = 'Preparing call...';
  bool _isLoading = true;
  bool _isMuted = false;
  bool _connected = false;
  bool _isEnding = false;

  bool get _isVideoCall => widget.callType == CallMediaType.video;
  bool get _isLiveCall => widget.roomId != null && widget.peerId != null;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_isLiveCall) {
      setState(() {
        _isLoading = false;
        _statusText =
            'This call shortcut is not connected to live calling yet.';
      });
      return;
    }

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _buildSessionController();

    final permissionsGranted = await _requestPermissions();
    if (!permissionsGranted || !mounted) {
      setState(() {
        _isLoading = false;
        _statusText = 'Camera or microphone permission is required.';
      });
      return;
    }

    await _sessionController!.prepareLocalMedia();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (widget.isIncoming) {
      _callLogId = widget.callLogId;
      ref
          .read(callNotifierProvider.notifier)
          .registerActiveCall(roomId: widget.roomId!, callLogId: _callLogId);
      _updateStatus('Connecting...');
      _sessionController!.joinCallRoom();
      return;
    }

    try {
      _updateStatus('Calling ${widget.name}...');
      _callLogId = await ref
          .read(callNotifierProvider.notifier)
          .startOutgoingCall(
            roomId: widget.roomId!,
            receiverId: widget.peerId!,
            callType: widget.callType,
          );
      _startOutgoingTimeout();
      _sessionController!.joinCallRoom();
    } catch (_) {
      if (!mounted) return;
      _updateStatus('Unable to start the call.');
    }
  }

  void _buildSessionController() {
    _sessionController = CallSessionController(
      callSocketService: _callSocketService,
      roomId: widget.roomId!,
      peerName: widget.name,
      isCaller: !widget.isIncoming,
      isVideoCall: _isVideoCall,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
      onStatusChanged: _updateStatus,
      onConnected: _markConnected,
      onRemoteEnd: _handleRemoteEnd,
    )..bindSocketListeners();
  }

  Future<bool> _requestPermissions() async {
    return CallPermissionService.ensureCallPermissions(
      context,
      callType: widget.callType,
    );
  }

  void _markConnected() {
    if (_connected) return;

    _connected = true;
    _connectedAt = DateTime.now();
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _handleRemoteEnd(String message) async {
    if (_isEnding) return;

    _isEnding = true;
    _updateStatus(message);
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    _sessionController?.leaveCallRoom();

    await ref
        .read(callNotifierProvider.notifier)
        .finalizeCallLog(
          connected: _connected,
          status: _connected ? 'completed' : 'cancelled',
          callLogId: _callLogId,
          durationSeconds: _connectedAt == null
              ? null
              : DateTime.now().difference(_connectedAt!).inSeconds,
        );

    ref.read(callNotifierProvider.notifier).clearActiveCall();

    await _disposeCallResources();

    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    _ringTimeoutTimer?.cancel();

    if (_isLiveCall) {
      final durationSeconds = _connectedAt == null
          ? null
          : DateTime.now().difference(_connectedAt!).inSeconds;
      await ref
          .read(callNotifierProvider.notifier)
          .finishCall(
            roomId: widget.roomId!,
            connected: _connected,
            status: _connected ? 'completed' : 'cancelled',
            targetUserId: widget.peerId,
            callLogId: _callLogId,
            durationSeconds: durationSeconds,
          );
      _sessionController?.leaveCallRoom();
    }

    await _disposeCallResources();

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _disposeCallResources() async {
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    await _sessionController?.dispose();
    // _localRenderer.srcObject = null;
    // _remoteRenderer.srcObject = null;
  }

  void _startOutgoingTimeout() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = Timer(const Duration(seconds: 35), () async {
      if (!mounted || _connected || _isEnding) return;

      _isEnding = true;
      _updateStatus('${widget.name} did not answer.');
      await ref
          .read(callNotifierProvider.notifier)
          .finishCall(
            roomId: widget.roomId!,
            connected: false,
            status: 'missed',
            targetUserId: widget.peerId,
            callLogId: _callLogId,
          );
      _sessionController?.leaveCallRoom();
      await _disposeCallResources();
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  void _toggleMute() {
    final nextMuted = !_isMuted;
    _sessionController?.setMuted(nextMuted);
    setState(() {
      _isMuted = nextMuted;
    });
  }

  Future<void> _switchCamera() async {
    await _sessionController?.switchCamera();
  }

  void _updateStatus(String value) {
    if (!mounted) return;
    setState(() {
      _statusText = value;
    });
  }

  String get _statusLabel {
    if (_connectedAt == null) return _statusText;

    final elapsed = DateTime.now().difference(_connectedAt!);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _ringTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    _sessionController?.leaveCallRoom();
    unawaited(_disposeCallResources());
    unawaited(_localRenderer.dispose());
    unawaited(_remoteRenderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = _sessionController;

    return CallScreenBody(
      name: widget.name,
      imageUrl: widget.imageUrl,
      statusLabel: _statusLabel,
      isLoading: _isLoading,
      isMuted: _isMuted,
      isVideoCall: _isVideoCall,
      hasRemoteVideo: sessionController?.hasRemoteVideo ?? false,
      hasLocalVideo: sessionController?.hasLocalVideo ?? false,
      localRenderer: _localRenderer,
      remoteRenderer: _remoteRenderer,
      onToggleMute: _toggleMute,
      onSwitchCamera: _switchCamera,
      onEndCall: _endCall,
    );
  }
}
