import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/notification_model.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/notification_service.dart';
import 'package:opalmer_education/core/services/notification_socket_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

final notificationSocketProvider =
    Provider<NotificationSocketService>((ref) => NotificationSocketService());

class NotificationState {
  final bool loading;
  final String? error;
  final List<NotificationModel> items;

  const NotificationState({
    this.loading = false,
    this.error,
    this.items = const [],
  });

  int get unreadCount => items.where((n) => !n.isViewed).length;

  NotificationState copyWith({
    bool? loading,
    String? error,
    List<NotificationModel>? items,
    bool clearError = false,
  }) {
    return NotificationState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._ref) : super(const NotificationState()) {
    _bindSocket();
  }

  final Ref _ref;

  String? get _userId => _ref.read(authStateProvider)?.id;

  void _bindSocket() {
    final socket = _ref.read(notificationSocketProvider);
    socket.onNotification = (notification) {
      state = state.copyWith(
        items: [notification, ...state.items],
      );
    };

    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      socket.connect(userId);
    }

    _ref.listen(authStateProvider, (previous, next) {
      final prevId = previous?.id;
      final nextId = next?.id;
      if (prevId == nextId) return;
      if (nextId == null || nextId.isEmpty) {
        socket.disconnect();
        state = const NotificationState();
      } else {
        socket.connect(nextId);
      }
    });
  }

  Future<void> load({bool silent = false}) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = const NotificationState();
      return;
    }
    if (!silent) {
      state = state.copyWith(loading: true, clearError: true);
    }
    try {
      final items =
          await _ref.read(notificationServiceProvider).getNotifications(userId);
      state = state.copyWith(loading: false, items: items, clearError: true);
    } catch (e) {
      debugPrint('NotificationNotifier: load failed: $e');
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    if (state.unreadCount == 0) return;

    final previous = state.items;
    state = state.copyWith(
      items: previous.map((n) => n.copyWith(isViewed: true)).toList(),
    );
    try {
      await _ref.read(notificationServiceProvider).markAllAsRead(userId);
    } catch (e) {
      debugPrint('NotificationNotifier: markAllAsRead failed: $e');
      state = state.copyWith(items: previous);
      rethrow;
    }
  }

  @override
  void dispose() {
    _ref.read(notificationSocketProvider).disconnect();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref),
);

final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).unreadCount,
);
