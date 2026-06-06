import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/chat/models/call_models.dart';
import 'package:opalmer_education/chat/services/call_socket_service.dart';
import 'package:opalmer_education/chat/services/chat_api_service.dart';
import 'package:opalmer_education/core/models/user_model.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';

class CallState {
  final IncomingCall? incomingCall;
  final String? activeRoomId;
  final String? activeCallLogId;
  final String? error;

  const CallState({
    this.incomingCall,
    this.activeRoomId,
    this.activeCallLogId,
    this.error,
  });

  bool get isBusy => activeRoomId != null;

  CallState copyWith({
    IncomingCall? incomingCall,
    bool clearIncomingCall = false,
    String? activeRoomId,
    bool clearActiveRoomId = false,
    String? activeCallLogId,
    bool clearActiveCallLogId = false,
    String? error,
    bool clearError = false,
  }) {
    return CallState(
      incomingCall: clearIncomingCall
          ? null
          : (incomingCall ?? this.incomingCall),
      activeRoomId: clearActiveRoomId
          ? null
          : (activeRoomId ?? this.activeRoomId),
      activeCallLogId: clearActiveCallLogId
          ? null
          : (activeCallLogId ?? this.activeCallLogId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final Ref _ref;
  final CallSocketService _socketService = CallSocketService();
  final ChatApiService _apiService = ChatApiService();
  final SecureStorageService _storage = SecureStorageService();

  StreamSubscription<IncomingCall>? _incomingCallSubscription;
  StreamSubscription<CallDeclinedEvent>? _callDeclinedSubscription;
  StreamSubscription<CallEndedEvent>? _callEndedSubscription;
  bool _listenersBound = false;

  CallNotifier(this._ref) : super(const CallState()) {
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
      state = const CallState();
      return;
    }

    final token = await _storage.getToken();
    if (token == null) return;

    _socketService.connect(token: token);
    _bindSocketListeners();
  }

  void _bindSocketListeners() {
    if (_listenersBound) return;
    _listenersBound = true;

    _incomingCallSubscription = _socketService.incomingCalls.listen((
      call,
    ) async {
      if (state.isBusy || state.incomingCall != null) {
        _socketService.declineCall(
          roomId: call.roomId,
          callerId: call.callerId,
          callLogId: call.callLogId,
          reason: 'busy',
        );

        if (call.callLogId != null) {
          await _safeEndCallLog(call.callLogId!, status: 'missed');
        }
        return;
      }

      state = state.copyWith(incomingCall: call, clearError: true);
    });

    _callDeclinedSubscription = _socketService.callDeclined.listen((event) {
      final shouldClearActive = state.activeRoomId == event.roomId;
      final shouldClearIncoming = state.incomingCall?.roomId == event.roomId;

      state = state.copyWith(
        clearIncomingCall: shouldClearIncoming,
        clearActiveRoomId: shouldClearActive,
        clearActiveCallLogId: shouldClearActive,
      );
    });

    _callEndedSubscription = _socketService.callEnded.listen((event) {
      final shouldClearActive = state.activeRoomId == event.roomId;
      final shouldClearIncoming = state.incomingCall?.roomId == event.roomId;

      state = state.copyWith(
        clearIncomingCall: shouldClearIncoming,
        clearActiveRoomId: shouldClearActive,
        clearActiveCallLogId: shouldClearActive,
      );
    });
  }

  Future<String?> startOutgoingCall({
    required String roomId,
    required String receiverId,
    required CallMediaType callType,
  }) async {
    try {
      final callLogId = await _apiService.createCallLog(
        roomId: roomId,
        receiverId: receiverId,
        callType: callMediaTypeValue(callType),
      );

      _socketService.placeCall(
        roomId: roomId,
        calleeId: receiverId,
        callType: callType,
        callLogId: callLogId,
      );

      state = state.copyWith(
        activeRoomId: roomId,
        activeCallLogId: callLogId,
        clearIncomingCall: true,
        clearError: true,
      );

      return callLogId;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      rethrow;
    }
  }

  void acceptIncomingCall(IncomingCall call) {
    _socketService.acceptCall(
      roomId: call.roomId,
      callerId: call.callerId,
      callLogId: call.callLogId,
    );

    state = state.copyWith(
      clearIncomingCall: true,
      activeRoomId: call.roomId,
      activeCallLogId: call.callLogId,
      clearError: true,
    );
  }

  Future<void> declineIncomingCall(
    IncomingCall call, {
    String reason = 'declined',
  }) async {
    _socketService.declineCall(
      roomId: call.roomId,
      callerId: call.callerId,
      callLogId: call.callLogId,
      reason: reason,
    );

    if (call.callLogId != null) {
      await _safeEndCallLog(
        call.callLogId!,
        status: reason == 'busy' ? 'busy' : 'declined',
      );
    }

    state = state.copyWith(clearIncomingCall: true);
  }

  Future<void> markCallAnswered(String callLogId) async {
    try {
      await _apiService.answerCallLog(callLogId: callLogId);
    } catch (_) {
      // Best effort only: answering the call should not be blocked by log sync.
    }
  }

  Future<void> finishCall({
    required String roomId,
    required bool connected,
    String? status,
    String? targetUserId,
    String? callLogId,
    int? durationSeconds,
  }) async {
    final effectiveCallLogId = callLogId ?? state.activeCallLogId;
    final effectiveStatus = status ?? (connected ? 'completed' : 'cancelled');

    _socketService.endCall(
      roomId: roomId,
      targetUserId: targetUserId,
      callLogId: effectiveCallLogId,
    );

    if (effectiveCallLogId != null) {
      await _safeEndCallLog(
        effectiveCallLogId,
        status: effectiveStatus,
        duration: durationSeconds,
      );
    }

    clearActiveCall();
  }

  Future<void> finalizeCallLog({
    required bool connected,
    String? status,
    String? callLogId,
    int? durationSeconds,
  }) async {
    final effectiveCallLogId = callLogId ?? state.activeCallLogId;
    if (effectiveCallLogId == null) return;

    await _safeEndCallLog(
      effectiveCallLogId,
      status: status ?? (connected ? 'completed' : 'cancelled'),
      duration: durationSeconds,
    );
  }

  void registerIncomingCallHandled() {
    state = state.copyWith(clearIncomingCall: true);
  }

  void registerActiveCall({required String roomId, String? callLogId}) {
    state = state.copyWith(
      activeRoomId: roomId,
      activeCallLogId: callLogId,
      clearIncomingCall: true,
      clearError: true,
    );
  }

  void clearActiveCall() {
    state = state.copyWith(
      clearActiveRoomId: true,
      clearActiveCallLogId: true,
      clearError: true,
    );
  }

  Future<void> _safeEndCallLog(
    String callLogId, {
    required String status,
    int? duration,
  }) async {
    try {
      await _apiService.endCallLog(
        callLogId: callLogId,
        status: status,
        duration: duration,
      );
    } catch (_) {
      // Best effort only: the call UI should still recover even if logging fails.
    }
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _callDeclinedSubscription?.cancel();
    _callEndedSubscription?.cancel();
    super.dispose();
  }
}

final callNotifierProvider = StateNotifierProvider<CallNotifier, CallState>((
  ref,
) {
  return CallNotifier(ref);
});
