import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/chat/models/chat_session_model.dart';
import 'package:opalmer_education/chat/models/message_model.dart';

class ChatApiService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all rooms for the current user
  Future<List<ChatSessionModel>> getRooms(String currentUserId) async {
    final response = await _apiClient.get(ApiConstants.myRooms);
    if (response.data['success'] == true) {
      final List data = response.data['data'] ?? [];
      return data
          .map((json) => ChatSessionModel.fromJson(json, currentUserId))
          .toList();
    }
    return [];
  }

  /// Fetch messages for a specific room (paginated)
  Future<List<MessageModel>> getMessages(
    String roomId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.roomMessages(roomId),
      queryParameters: {'page': page, 'limit': limit},
    );
    if (response.data['success'] == true) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    }
    return [];
  }

  /// Create a new room
  Future<ChatSessionModel?> createRoom(
    List<String> participants,
    String currentUserId, {
    String? name,
    File? avatar,
  }) async {
    FormData formData = FormData.fromMap({
      'participants': jsonEncode(participants),
      ...?name != null ? {'name': name} : null,
    });

    if (avatar != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          await MultipartFile.fromFile(avatar.path, filename: 'avatar.jpg'),
        ),
      );
    }

    final response = await _apiClient.post(ApiConstants.rooms, data: formData);
    if (response.data['success'] == true) {
      return ChatSessionModel.fromJson(response.data['data'], currentUserId);
    }
    return null;
  }

  /// Send a message via HTTP
  Future<MessageModel?> sendMessage(
    String roomId,
    String text, {
    List<File>? files,
  }) async {
    FormData formData = FormData.fromMap({'roomId': roomId, 'message': text});

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        formData.files.add(
          MapEntry('files', await MultipartFile.fromFile(file.path)),
        );
      }
    }

    final response = await _apiClient.post(
      ApiConstants.messages,
      data: formData,
    );
    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    }
    return null;
  }

  /// Edit a message
  Future<MessageModel?> updateMessage(String messageId, String text) async {
    final response = await _apiClient.patch(
      '${ApiConstants.messages}/$messageId',
      data: {'message': text},
    );
    if (response.data['success'] == true) {
      return MessageModel.fromJson(response.data['data']);
    }
    return null;
  }

  /// Soft delete a message
  Future<bool> deleteMessage(String messageId) async {
    final response = await _apiClient.delete(
      '${ApiConstants.messages}/$messageId',
    );
    return response.data['success'] == true;
  }

  /// Fetch messageable contacts
  Future<List<Map<String, dynamic>>> getContacts() async {
    final response = await _apiClient.get(
      '/users/contacts',
    ); // Assume this endpoint exists or implement in backend
    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    }
    return [];
  }

  /// Fetch call logs
  Future<List<Map<String, dynamic>>> getCallLogs() async {
    final response = await _apiClient.get(ApiConstants.myCallLogs);
    if (response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    }
    return [];
  }

  /// Create a call log when a user starts a call.
  Future<String?> createCallLog({
    required String roomId,
    required String receiverId,
    required String callType,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.callLogs,
      data: {'roomId': roomId, 'receiverId': receiverId, 'callType': callType},
    );

    if (response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>?;
      return data?['_id']?.toString();
    }

    return null;
  }

  /// Mark a call log as completed or missed.
  Future<void> answerCallLog({required String callLogId}) async {
    await _apiClient.patch('${ApiConstants.callLogs}/$callLogId/answer');
  }

  /// Mark a call log as completed or missed.
  Future<void> endCallLog({
    required String callLogId,
    required String status,
    int? duration,
  }) async {
    await _apiClient.patch(
      '${ApiConstants.callLogs}/$callLogId/end',
      data: {
        'status': status,
        ...?duration != null ? {'duration': duration} : null,
      },
    );
  }
}
