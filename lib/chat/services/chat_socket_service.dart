import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message_model.dart';

enum ChatSocketConnectionStatus { disconnected, connecting, connected }

class ChatSocketService {
  ChatSocketService._internal();
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;

  io.Socket? _socket;
  final StreamController<MessageModel> _messageController = StreamController<MessageModel>.broadcast();
  final StreamController<ChatSocketConnectionStatus> _statusController = StreamController<ChatSocketConnectionStatus>.broadcast();
  
  ChatSocketConnectionStatus _status = ChatSocketConnectionStatus.disconnected;

  ChatSocketConnectionStatus get status => _status;
  Stream<MessageModel> get messages => _messageController.stream;
  Stream<ChatSocketConnectionStatus> get statusStream => _statusController.stream;

  void connect({required String token}) {
    if (_socket?.connected == true) return;

    _status = ChatSocketConnectionStatus.connecting;
    _statusController.add(_status);

    debugPrint('ChatSocket: Attempting connection to ${ApiConstants.socketBaseUrl}');
    
    _socket = io.io(
      ApiConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableForceNew() // Add forceNew
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.connect(); // Explicitly call connect

    _socket!.onConnect((_) {
      debugPrint('ChatSocket: connected');
      _status = ChatSocketConnectionStatus.connected;
      _statusController.add(_status);
    });

    _socket!.onDisconnect((_) {
      debugPrint('ChatSocket: disconnected');
      _status = ChatSocketConnectionStatus.disconnected;
      _statusController.add(_status);
    });

    _socket!.on('newMessage', (data) {
      debugPrint('ChatSocket: newMessage received');
      if (data != null) {
        try {
          final message = MessageModel.fromJson(Map<String, dynamic>.from(data));
          _messageController.add(message);
        } catch (e) {
          debugPrint('ChatSocket: Error parsing message: $e');
        }
      }
    });

    _socket!.onConnectError((err) => debugPrint('ChatSocket: Connection Error: $err'));
    _socket!.onError((err) => debugPrint('ChatSocket: Error: $err'));
  }

  void joinRoom(String roomId) {
    if (_socket?.connected == true) {
      debugPrint('ChatSocket: joining room $roomId');
      _socket!.emit('joinRoom', roomId);
    }
  }

  void leaveRoom(String roomId) {
    if (_socket?.connected == true) {
      _socket!.emit('leaveRoom', roomId);
    }
  }

  void disconnect() {
    debugPrint('ChatSocket: disconnect() called from:\n${StackTrace.current}');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _status = ChatSocketConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
