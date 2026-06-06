import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:opalmer_education/chat/services/chat_socket_service.dart';
import 'package:opalmer_education/chat/services/call_socket_service.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/user_model.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  Future<LoginResponse?> login(String id, String password) async {
    debugPrint('AuthService: Attempting login for ID: $id');
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {'Id': id, 'password': password},
      );

      debugPrint(
        'AuthService: Login response received: ${response.statusCode}',
      );
      final dataMap = UserModel.recursiveSafeMap(response.data);

      if (response.statusCode == 200 && dataMap['success'] == true) {
        debugPrint('AuthService: Login successful, saving token and user data');
        final loginResponse = LoginResponse.fromJson(dataMap);

        // Save token and user data
        await _storage.saveToken(loginResponse.token);
        await _storage.saveUserData(jsonEncode(loginResponse.user.toJson()));

        return loginResponse;
      }
      debugPrint(
        'AuthService: Login failed with success=false or wrong status code',
      );
      return null;
    } on DioException catch (e) {
      debugPrint('AuthService: DioException during login: ${e.message}');
      debugPrint('AuthService: Response status: ${e.response?.statusCode}');
      debugPrint('AuthService: Response data: ${e.response?.data}');

      final errorData = UserModel.recursiveSafeMap(e.response?.data);
      final message = errorData['message']?.toString() ?? 'Login failed';
      throw Exception(message);
    } catch (e) {
      debugPrint('AuthService: Unexpected error during login: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      // Disconnect sockets first to ensure no more events are received
      ChatSocketService().disconnect();
      CallSocketService().disconnect();

      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        await _apiClient.post(ApiConstants.logout);
      }
    } catch (e) {
      debugPrint(
        'AuthService: logout request failed, continuing local sign-out: $e',
      );
    } finally {
      await _storage.clearAll();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Fetches the authenticated user from GET /users/me and updates the
  /// cached user data. Returns null on failure so callers can fall back to
  /// their existing (possibly stale) state.
  Future<UserModel?> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get(ApiConstants.me);
      final dataMap = UserModel.recursiveSafeMap(response.data);
      if (response.statusCode == 200 && dataMap['success'] == true) {
        final userJson = UserModel.recursiveSafeMap(dataMap['data']);
        final user = UserModel.fromJson(userJson);
        await _storage.saveUserData(jsonEncode(user.toJson()));
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: fetchCurrentUser failed: $e');
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _apiClient.put('/users/$userId', data: updates);

      final dataMap = UserModel.recursiveSafeMap(response.data);
      if (response.statusCode == 200 && dataMap['success'] == true) {
        final userJson = UserModel.recursiveSafeMap(dataMap['data']);
        final updated = UserModel.fromJson(userJson);
        await _storage.saveUserData(jsonEncode(updated.toJson()));
        return updated;
      }

      final message =
          dataMap['message']?.toString() ?? 'Failed to update profile';
      throw Exception(message);
    } on DioException catch (e) {
      debugPrint(
        'AuthService: DioException during updateProfile: ${e.message}',
      );
      final errorData = UserModel.recursiveSafeMap(e.response?.data);
      final message =
          errorData['message']?.toString() ?? 'Failed to update profile';
      throw Exception(message);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      final dataMap = UserModel.recursiveSafeMap(response.data);
      if (response.statusCode == 200 && dataMap['success'] == true) {
        return;
      }
      throw Exception(
        dataMap['message']?.toString() ?? 'Failed to change password',
      );
    } on DioException catch (e) {
      final errorData = UserModel.recursiveSafeMap(e.response?.data);
      throw Exception(
        errorData['message']?.toString() ?? 'Failed to change password',
      );
    }
  }
}
