import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CallSocketService {
  CallSocketService._internal();

  static final CallSocketService _instance = CallSocketService._internal();

  factory CallSocketService() => _instance;

  io.Socket? _socket;

  final StreamController<IncomingCall> _incomingCallController =
      StreamController<IncomingCall>.broadcast();
  final StreamController<CallAcceptedEvent> _callAcceptedController =
      StreamController<CallAcceptedEvent>.broadcast();
  final StreamController<CallDeclinedEvent> _callDeclinedController =
      StreamController<CallDeclinedEvent>.broadcast();
  final StreamController<CallEndedEvent> _callEndedController =
      StreamController<CallEndedEvent>.broadcast();
  final StreamController<List<String>> _allUsersController =
      StreamController<List<String>>.broadcast();
  final StreamController<String> _userJoinedController =
      StreamController<String>.broadcast();
  final StreamController<String> _userLeftController =
      StreamController<String>.broadcast();
  final StreamController<CallSignalEvent> _userSignalController =
      StreamController<CallSignalEvent>.broadcast();
  final StreamController<CallSignalEvent> _returnedSignalController =
      StreamController<CallSignalEvent>.broadcast();

  Stream<IncomingCall> get incomingCalls => _incomingCallController.stream;
  Stream<CallAcceptedEvent> get callAccepted => _callAcceptedController.stream;
  Stream<CallDeclinedEvent> get callDeclined => _callDeclinedController.stream;
  Stream<CallEndedEvent> get callEnded => _callEndedController.stream;
  Stream<List<String>> get allUsers => _allUsersController.stream;
  Stream<String> get userJoined => _userJoinedController.stream;
  Stream<String> get userLeft => _userLeftController.stream;
  Stream<CallSignalEvent> get userSignal => _userSignalController.stream;
  Stream<CallSignalEvent> get returnedSignal =>
      _returnedSignalController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect({required String token}) {
    if (_socket?.connected == true) return;

    debugPrint('CallSocket: Attempting connection to ${ApiConstants.socketBaseUrl}');

    _socket ??= io.io(
      ApiConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNew() // Add forceNew
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _registerListeners();

    if (_socket?.connected != true) {
      _socket?.connect();
    }
  }

  void _registerListeners() {
    if (_socket == null) return;

    _socket!
      ..off('incoming-call')
      ..off('call-accepted')
      ..off('call-declined')
      ..off('call-ended')
      ..off('all-users')
      ..off('user-joined')
      ..off('user-left')
      ..off('user-signal')
      ..off('receiving-returned-signal');

    _socket!.onConnect((_) {
      debugPrint('CallSocket: connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('CallSocket: disconnected');
    });

    _socket!.on('incoming-call', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _incomingCallController.add(IncomingCall.fromJson(payload));
      }
    });

    _socket!.on('call-accepted', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _callAcceptedController.add(CallAcceptedEvent.fromJson(payload));
      }
    });

    _socket!.on('call-declined', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _callDeclinedController.add(CallDeclinedEvent.fromJson(payload));
      }
    });

    _socket!.on('call-ended', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _callEndedController.add(CallEndedEvent.fromJson(payload));
      }
    });

    _socket!.on('all-users', (data) {
      final users = (data as List<dynamic>? ?? const [])
          .map((userId) => userId.toString())
          .where((userId) => userId.isNotEmpty)
          .toList();
      _allUsersController.add(users);
    });

    _socket!.on('user-joined', (data) {
      final userId = data?.toString();
      if (userId != null && userId.isNotEmpty) {
        _userJoinedController.add(userId);
      }
    });

    _socket!.on('user-left', (data) {
      final userId = data?.toString();
      if (userId != null && userId.isNotEmpty) {
        _userLeftController.add(userId);
      }
    });

    _socket!.on('user-signal', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _userSignalController.add(
          CallSignalEvent(
            socketId: (payload['callerId'] ?? '').toString(),
            signal: _asMap(payload['signal']) ?? const {},
          ),
        );
      }
    });

    _socket!.on('receiving-returned-signal', (data) {
      final payload = _asMap(data);
      if (payload != null) {
        _returnedSignalController.add(
          CallSignalEvent(
            socketId: (payload['id'] ?? '').toString(),
            signal: _asMap(payload['signal']) ?? const {},
          ),
        );
      }
    });

    _socket!.onConnectError((error) {
      debugPrint('CallSocket: connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('CallSocket: error: $error');
    });
  }

  void placeCall({
    required String roomId,
    required String calleeId,
    required CallMediaType callType,
    String? callLogId,
  }) {
    if (_socket?.connected != true) {
      debugPrint('CallSocket: Cannot place call, socket is NOT connected');
      return;
    }

    final payload = {
      'roomId': roomId,
      'calleeId': calleeId,
      'callType': callMediaTypeValue(callType),
      ...?callLogId != null ? {'callLogId': callLogId} : null,
    };

    debugPrint('CallSocket: Placing call with payload: $payload');

    _socket?.emitWithAck('call-user', payload, ack: (data) {
      debugPrint('CallSocket: placeCall server ack: $data');
    });
  }

  void acceptCall({
    required String roomId,
    required String callerId,
    String? callLogId,
  }) {
    _socket?.emit('accept-call', {
      'roomId': roomId,
      'callerId': callerId,
      ...?callLogId != null ? {'callLogId': callLogId} : null,
    });
  }

  void declineCall({
    required String roomId,
    required String callerId,
    String? callLogId,
    String? reason,
  }) {
    _socket?.emit('decline-call', {
      'roomId': roomId,
      'callerId': callerId,
      ...?callLogId != null ? {'callLogId': callLogId} : null,
      ...?reason != null ? {'reason': reason} : null,
    });
  }

  void endCall({
    required String roomId,
    String? targetUserId,
    String? callLogId,
  }) {
    _socket?.emit('end-call', {
      'roomId': roomId,
      ...?targetUserId != null ? {'targetUserId': targetUserId} : null,
      ...?callLogId != null ? {'callLogId': callLogId} : null,
    });
  }

  void joinCallRoom(String roomId) {
    _socket?.emit('join', roomId);
  }

  void leaveCallRoom() {
    _socket?.emit('leave-call');
  }

  void sendSignal({
    required String targetSocketId,
    required Map<String, dynamic> signal,
    required bool isCaller,
  }) {
    if (isCaller) {
      _socket?.emit('sending-signal', {
        'userToSignal': targetSocketId,
        'callerId': _socket?.id,
        'signal': signal,
      });
      return;
    }

    _socket?.emit('returning-signal', {
      'callerId': targetSocketId,
      'signal': signal,
    });
  }

  void disconnect() {
    debugPrint('CallSocket: disconnect() called from:\n${StackTrace.current}');
    _socket?.disconnect();
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
