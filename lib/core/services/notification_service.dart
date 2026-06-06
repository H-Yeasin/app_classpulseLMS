import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/notification_model.dart';
import 'package:opalmer_education/core/services/api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response =
          await _apiClient.get('${ApiConstants.notifications}/$userId');
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map((e) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      debugPrint(
          'NotificationService: DioException in getNotifications: ${e.message}');
      rethrow;
    }
  }

  Future<int> markAllAsRead(String userId) async {
    try {
      final response = await _apiClient.dio
          .patch('${ApiConstants.notificationsReadAll}/$userId');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return (data['modifiedCount'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      debugPrint(
          'NotificationService: DioException in markAllAsRead: ${e.message}');
      rethrow;
    }
  }
}
