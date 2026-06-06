import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/services/secure_storage_service.dart';

class ApiClient {
  final Dio _dio = Dio();
  final SecureStorageService _storage = SecureStorageService();
  late final Uri _apiBaseUri;
  late final Uri _apiOriginUri;

  ApiClient() {
    debugPrint('ApiClient: Initializing with baseUrl: ${ApiConstants.baseUrl}');
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _apiBaseUri = Uri.parse(ApiConstants.baseUrl);
    _apiOriginUri = Uri.parse(ApiConstants.apiOrigin);
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final pathUri = Uri.tryParse(options.path);
          final isAbsolutePath =
              pathUri != null && pathUri.hasScheme && pathUri.host.isNotEmpty;
          final isExternalPath =
              isAbsolutePath &&
              pathUri.host != _apiBaseUri.host &&
              pathUri.host != _apiOriginUri.host;

          if (isAbsolutePath) {
            options.baseUrl = '';
          }

          final token = await _storage.getToken();
          final requestUri = options.uri;
          final isApiRequest = !isExternalPath &&
              (requestUri.host.isEmpty ||
                  requestUri.host == _apiBaseUri.host ||
                  requestUri.host == _apiOriginUri.host);
          if (isApiRequest && token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint(
            'ApiClient: [${options.method}] REQUEST to: ${options.uri}',
          );
          debugPrint('ApiClient: [${options.method}] Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            'ApiClient: [${response.requestOptions.method}] RESPONSE from: ${response.requestOptions.uri}',
          );
          debugPrint('ApiClient: [${response.requestOptions.method}] Status Code: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            'ApiClient: [${e.requestOptions.method}] ERROR from: ${e.requestOptions.uri}',
          );
          debugPrint('ApiClient: [${e.requestOptions.method}] Message: ${e.message}');
          debugPrint('ApiClient: [${e.requestOptions.method}] Response Data: ${e.response?.data}');
          
          if (e.response?.statusCode == 401) {
            // Handle token expiration - e.g., redirect to login or refresh token
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Generic request methods for convenience
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(path, data: data, options: options);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path) async {

    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}
