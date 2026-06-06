import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/user_model.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';
import '../models/chat_session_model.dart';
import '../models/message_model.dart';
import '../services/chat_api_service.dart';
import '../services/chat_socket_service.dart';

class ChatState {
  final List<ChatSessionModel> rooms;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.rooms = const [],
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatSessionModel>? rooms,
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatApiService _apiService = ChatApiService();
  final ChatSocketService _socketService = ChatSocketService();
  final SecureStorageService _storage = SecureStorageService();
  final Ref _ref;

  ChatNotifier(this._ref) : super(const ChatState()) {
    _init();
  }

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  bool _listenersBound = false;

  void _init() {
    _ref.listen<UserModel?>(authStateProvider, (previous, next) {
      if (previous != null && next == null) {
        _socketService.disconnect();
      } else if (next != null) {
        unawaited(_handleAuthChange(next));
      }
    }, fireImmediately: true);
  }

  Future<void> _handleAuthChange(UserModel? user) async {
    if (user == null) {
      _socketService.disconnect();
      _messageSubscription?.cancel();
      _messageSubscription = null;
      _statusSubscription?.cancel();
      _statusSubscription = null;
      _listenersBound = false;
      state = const ChatState();
      return;
    }

    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return;

    _socketService.connect(token: token);
    _setupListeners();
    await loadRooms();
  }

  void _setupListeners() {
    if (_listenersBound) return;
    _listenersBound = true;

    _messageSubscription?.cancel();
    _messageSubscription = _socketService.messages.listen((message) {
      _handleNewIncomingMessage(message);
    });

    _statusSubscription?.cancel();
    _statusSubscription = _socketService.statusStream.listen((status) {
      if (status == ChatSocketConnectionStatus.connected) {
        // Re-join active rooms if needed, or refresh list
        loadRooms();
      }
    });
  }

  void _handleNewIncomingMessage(MessageModel message) {
    // Prevent duplicates
    if (state.messages.any((m) => m.id == message.id)) return;

    final List<MessageModel> updatedMessages = [...state.messages, message];

    // Update rooms list with last message snippet
    final updatedRooms = state.rooms.map((room) {
      if (room.id == message.chatSessionId) {
        return room.copyWith(subtitle: message.text, updatedAt: DateTime.now());
      }
      return room;
    }).toList();

    state = state.copyWith(messages: updatedMessages, rooms: updatedRooms);
  }

  Future<void> loadRooms() async {
    final user = _ref.read(authStateProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final rooms = await _apiService.getRooms(user.id);
      state = state.copyWith(rooms: rooms, isLoading: false);

      // Auto-join all rooms via socket
      for (var room in rooms) {
        _socketService.joinRoom(room.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Manually add and join a room (e.g. after creating one)
  void addRoom(ChatSessionModel room) {
    if (!state.rooms.any((r) => r.id == room.id)) {
      state = state.copyWith(rooms: [room, ...state.rooms]);
    }
    _socketService.joinRoom(room.id);
  }

  Future<void> loadMessages(String roomId) async {
    state = state.copyWith(isLoading: true);
    try {
      final messages = await _apiService.getMessages(roomId);
      final newMessages = messages.reversed.toList();

      // Merge with existing messages, avoiding duplicates
      final existingIds = state.messages.map((m) => m.id).toSet();
      final filteredNew = newMessages
          .where((m) => !existingIds.contains(m.id))
          .toList();

      state = state.copyWith(
        messages: [...state.messages, ...filteredNew],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String roomId, String text) async {
    try {
      final newMessage = await _apiService.sendMessage(roomId, text);
      if (newMessage != null) {
        // Optimistically add to local state if socket didn't beat us to it
        _handleNewIncomingMessage(newMessage);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message: $e');
    }
  }

  Future<ChatSessionModel?> getOrCreateDirectRoom(String otherUserId) async {
    final user = _ref.read(authStateProvider);
    if (user == null) return null;

    state = state.copyWith(isLoading: true);
    try {
      final room = await _apiService.createRoom([otherUserId], user.id);
      if (room != null) {
        addRoom(room);
        state = state.copyWith(isLoading: false);
        return room;
      }
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((
  ref,
) {
  return ChatNotifier(ref);
});

// Helper for UI to filter rooms by role-specific logic if needed
final chatRoomsProvider = Provider<List<ChatSessionModel>>((ref) {
  final state = ref.watch(chatNotifierProvider);
  return state.rooms;
});

final chatMessagesProvider = Provider.family<List<MessageModel>, String>((
  ref,
  roomId,
) {
  final state = ref.watch(chatNotifierProvider);
  final roomMessages = state.messages
      .where((m) => m.chatSessionId == roomId)
      .toList();
  // Sort by timestamp to ensure correct order after merging history/new messages
  roomMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return roomMessages;
});
