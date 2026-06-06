import 'package:flutter/foundation.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/notification_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef NotificationCallback = void Function(NotificationModel notification);

class NotificationSocketService {
  NotificationSocketService._internal();
  static final NotificationSocketService _instance =
      NotificationSocketService._internal();
  factory NotificationSocketService() => _instance;

  io.Socket? _socket;
  String? _joinedUserId;
  NotificationCallback? onNotification;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String userId) {
    if (_socket != null && _joinedUserId == userId) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    _socket?.dispose();
    _joinedUserId = userId;

    final socket = io.io(
      ApiConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('NotificationSocket: connected, joining $userId');
      socket.emit('joinNotification', userId);
    });

    socket.on('newNotification', (data) {
      if (data is Map) {
        try {
          final notification =
              NotificationModel.fromJson(Map<String, dynamic>.from(data));
          onNotification?.call(notification);
        } catch (e) {
          debugPrint('NotificationSocket: failed to parse payload: $e');
        }
      }
    });

    socket.onDisconnect(
        (_) => debugPrint('NotificationSocket: disconnected'));
    socket.onConnectError(
        (err) => debugPrint('NotificationSocket: connect error: $err'));
    socket.onError(
        (err) => debugPrint('NotificationSocket: error: $err'));

    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _joinedUserId = null;
  }
}
