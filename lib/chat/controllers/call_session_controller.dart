import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/chat/services/call_socket_service.dart';

class CallSessionController {
  final CallSocketService _callSocketService;
  final String _roomId;
  final String _peerName;
  final bool _isCaller;
  final bool _isVideoCall;
  final RTCVideoRenderer _localRenderer;
  final RTCVideoRenderer _remoteRenderer;
  final void Function(String value) _onStatusChanged;
  final VoidCallback _onConnected;
  final Future<void> Function(String message) _onRemoteEnd;

  StreamSubscription<CallAcceptedEvent>? _callAcceptedSubscription;
  StreamSubscription<CallDeclinedEvent>? _callDeclinedSubscription;
  StreamSubscription<CallEndedEvent>? _callEndedSubscription;
  StreamSubscription<List<String>>? _allUsersSubscription;
  StreamSubscription<String>? _userJoinedSubscription;
  StreamSubscription<String>? _userLeftSubscription;
  StreamSubscription<CallSignalEvent>? _userSignalSubscription;
  StreamSubscription<CallSignalEvent>? _returnedSignalSubscription;

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  String? _peerSocketId;
  bool _connected = false;
  bool _listenersBound = false;
  bool _remoteEndHandled = false;

  CallSessionController({
    required CallSocketService callSocketService,
    required String roomId,
    required String peerName,
    required bool isCaller,
    required bool isVideoCall,
    required RTCVideoRenderer localRenderer,
    required RTCVideoRenderer remoteRenderer,
    required void Function(String value) onStatusChanged,
    required VoidCallback onConnected,
    required Future<void> Function(String message) onRemoteEnd,
  }) : _callSocketService = callSocketService,
       _roomId = roomId,
       _peerName = peerName,
       _isCaller = isCaller,
       _isVideoCall = isVideoCall,
       _localRenderer = localRenderer,
       _remoteRenderer = remoteRenderer,
       _onStatusChanged = onStatusChanged,
       _onConnected = onConnected,
       _onRemoteEnd = onRemoteEnd;

  bool get hasRemoteVideo => _remoteRenderer.srcObject != null && _isVideoCall;
  bool get hasLocalVideo => _localRenderer.srcObject != null && _isVideoCall;

  Future<void> prepareLocalMedia() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': _isVideoCall ? <String, dynamic>{'facingMode': 'user'} : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (_isVideoCall) {
      _localRenderer.srcObject = _localStream;
    }
  }

  void bindSocketListeners() {
    if (_listenersBound) return;
    _listenersBound = true;

    _callAcceptedSubscription = _callSocketService.callAccepted.listen((event) {
      if (event.roomId != _roomId || !_isCaller) return;
      _onStatusChanged('Connecting...');
    });

    _callDeclinedSubscription = _callSocketService.callDeclined.listen((event) {
      if (event.roomId != _roomId) return;
      final message = switch (event.reason) {
        'busy' => '$_peerName is busy right now.',
        _ => '${event.declinedByName} declined the call.',
      };
      unawaited(_handleRemoteEnd(message));
    });

    _callEndedSubscription = _callSocketService.callEnded.listen((event) {
      if (event.roomId != _roomId) return;
      unawaited(_handleRemoteEnd('${event.endedByName} ended the call.'));
    });

    _allUsersSubscription = _callSocketService.allUsers.listen((users) {
      if (!_isCaller || users.isEmpty) return;
      unawaited(_createOffer(users.first));
    });

    _userJoinedSubscription = _callSocketService.userJoined.listen((socketId) {
      if (!_isCaller) return;
      unawaited(_createOffer(socketId));
    });

    _userLeftSubscription = _callSocketService.userLeft.listen((socketId) {
      if (_peerSocketId == socketId) {
        unawaited(_handleRemoteEnd('$_peerName left the call.'));
      }
    });

    _userSignalSubscription = _callSocketService.userSignal.listen((event) {
      if (_isCaller) return;
      unawaited(_handleSignal(event.socketId, event.signal));
    });

    _returnedSignalSubscription = _callSocketService.returnedSignal.listen((
      event,
    ) {
      if (!_isCaller) return;
      unawaited(_handleSignal(event.socketId, event.signal));
    });
  }

  void joinCallRoom() {
    _callSocketService.joinCallRoom(_roomId);
  }

  void leaveCallRoom() {
    _callSocketService.leaveCallRoom();
  }

  void setMuted(bool muted) {
    final stream = _localStream;
    if (stream == null) return;

    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  Future<void> switchCamera() async {
    if (!_isVideoCall || _localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isEmpty) return;

    Helper.switchCamera(videoTracks.first);
  }

  Future<RTCPeerConnection> _ensurePeerConnection(String remoteSocketId) async {
    if (_peerConnection != null && _peerSocketId == remoteSocketId) {
      return _peerConnection!;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final peerConnection = await createPeerConnection(configuration);
    _peerSocketId = remoteSocketId;

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await peerConnection.addTrack(track, stream);
      }
    }

    peerConnection.onIceCandidate = (candidate) {
      final candidateValue = candidate.candidate;
      if (candidateValue == null ||
          candidateValue.isEmpty ||
          _peerSocketId == null) {
        return;
      }

      _callSocketService.sendSignal(
        targetSocketId: _peerSocketId!,
        isCaller: _isCaller,
        signal: {
          'type': 'candidate',
          'candidate': candidateValue,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    peerConnection.onTrack = (event) {
      if (event.streams.isEmpty) return;
      if (_isVideoCall) {
        _remoteRenderer.srcObject = event.streams.first;
      }
      _markConnected();
    };

    peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _markConnected();
      }

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (_connected) {
          unawaited(_handleRemoteEnd('$_peerName disconnected.'));
        }
      }
    };

    _peerConnection = peerConnection;
    return peerConnection;
  }

  Future<void> _createOffer(String remoteSocketId) async {
    if (_peerSocketId == remoteSocketId && _connected) return;

    final peerConnection = await _ensurePeerConnection(remoteSocketId);
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    _callSocketService.sendSignal(
      targetSocketId: remoteSocketId,
      isCaller: true,
      signal: {'type': 'offer', 'sdp': offer.sdp},
    );

    _onStatusChanged('Ringing...');
  }

  Future<void> _handleSignal(
    String remoteSocketId,
    Map<String, dynamic> signal,
  ) async {
    if (signal.isEmpty) return;

    final peerConnection = await _ensurePeerConnection(remoteSocketId);
    final type = signal['type']?.toString();

    switch (type) {
      case 'offer':
        await peerConnection.setRemoteDescription(
          RTCSessionDescription(signal['sdp']?.toString(), 'offer'),
        );
        final answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        _callSocketService.sendSignal(
          targetSocketId: remoteSocketId,
          isCaller: false,
          signal: {'type': 'answer', 'sdp': answer.sdp},
        );
        _onStatusChanged('Connecting...');
        break;
      case 'answer':
        await peerConnection.setRemoteDescription(
          RTCSessionDescription(signal['sdp']?.toString(), 'answer'),
        );
        _onStatusChanged('Connecting...');
        break;
      case 'candidate':
        final candidateIndex = signal['sdpMLineIndex'];
        final lineIndex = candidateIndex is int
            ? candidateIndex
            : int.tryParse(candidateIndex?.toString() ?? '');

        await peerConnection.addCandidate(
          RTCIceCandidate(
            signal['candidate']?.toString(),
            signal['sdpMid']?.toString(),
            lineIndex,
          ),
        );
        break;
    }
  }

  void _markConnected() {
    if (_connected) return;

    _connected = true;
    _remoteEndHandled = false;
    _onStatusChanged('Connected');
    _onConnected();
  }

  Future<void> _handleRemoteEnd(String message) async {
    if (_remoteEndHandled) return;
    _remoteEndHandled = true;
    await _onRemoteEnd(message);
  }

  Future<void> dispose() async {
    await _callAcceptedSubscription?.cancel();
    await _callDeclinedSubscription?.cancel();
    await _callEndedSubscription?.cancel();
    await _allUsersSubscription?.cancel();
    await _userJoinedSubscription?.cancel();
    await _userLeftSubscription?.cancel();
    await _userSignalSubscription?.cancel();
    await _returnedSignalSubscription?.cancel();

    await _peerConnection?.close();
    _peerConnection = null;

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
    }
    _localStream = null;

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
  }
}
