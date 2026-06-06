import 'package:opalmer_education/core/services/api_client.dart';
import 'package:dio/dio.dart';

class GradingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getTeacherSessions({String? classId}) async {
    final response = await _apiClient.get(
      '/grading/sessions',
      queryParameters: classId != null ? {'classId': classId} : null,
    );
    return response.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession({
    required String classId,
    required String title,
    String? description,
    int? time,
  }) async {
    final response = await _apiClient.post(
      '/grading/sessions',
      data: {
        'classId': classId,
        'title': title,
        'description': description ?? '',
        'time': time ?? 5,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSession({
    required String sessionId,
    required String title,
    int? time,
  }) async {
    final response = await _apiClient.patch(
      '/grading/sessions/$sessionId',
      data: {
        'title': title,
        'time': time ?? 5,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsertQuestions({
    required String sessionId,
    required List<Map<String, dynamic>> questions,
  }) async {
    final response = await _apiClient.post(
      '/grading/sessions/$sessionId/questions',
      data: {'questions': questions},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<String> uploadQuestionImage(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
    });

    final response = await _apiClient.post(
      '/grading/question-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> publishSession(String sessionId) async {
    final response = await _apiClient.patch(
      '/grading/sessions/$sessionId/publish',
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionDetails(String sessionId) async {
    final response = await _apiClient.get('/grading/sessions/$sessionId');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSessionQuestions(String sessionId) async {
    final response = await _apiClient.get(
      '/grading/sessions/$sessionId/questions',
    );
    // The controller returns questions wrapped in a data object
    return response.data['data']['questions'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAttendedSubmittedStudents(
    String sessionId,
  ) async {
    final response = await _apiClient.get(
      '/grading/sessions/$sessionId/results',
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> generateAIQuestions({
    required String prompt,
    int count = 10,
  }) async {
    try {
      final response = await _apiClient.post(
        '/quiz/qa/generate',
        data: {'prompt': prompt, 'count': count},
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      return _extractQuestions(response.data['data']);
    } on DioException catch (e) {
      final responseText = e.response?.data.toString().toLowerCase() ?? '';
      final isLegacyContractError =
          e.response?.statusCode == 400 &&
          responseText.contains('quizid and topic are required');

      if (!isLegacyContractError) {
        throw Exception(_extractApiErrorMessage(e));
      }

      // Backward-compat fallback for older backend contract.
      final legacyResponse = await _apiClient.post(
        '/quiz/qa/generate',
        data: {
          'quizId': _buildLegacyPreviewQuizId(),
          'topic': prompt,
          'count': count,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      return _extractQuestions(legacyResponse.data['data']);
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception(
        'Failed to generate questions. Please try again in a moment.',
      );
    }
  }

  List<dynamic> _extractQuestions(dynamic data) {
    if (data is List<dynamic>) {
      return data;
    }
    if (data is Map<String, dynamic> && data['questions'] is List<dynamic>) {
      return data['questions'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  String _buildLegacyPreviewQuizId() {
    final hexTime = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final buffer = (hexTime + hexTime).padLeft(24, '0');
    return buffer.substring(buffer.length - 24);
  }

  String _extractApiErrorMessage(DioException e) {
    final data = e.response?.data;
    String message = 'Failed to generate questions.';

    if (data is Map<String, dynamic>) {
      final raw = data['message'];
      if (raw is String && raw.trim().isNotEmpty) {
        message = raw.trim();
      }
    } else if (e.message != null && e.message!.trim().isNotEmpty) {
      message = e.message!.trim();
    }

    final lowered = message.toLowerCase();
    if (lowered.contains('exceeded your current quota') ||
        lowered.contains('insufficient_quota')) {
      return 'AI quota exceeded. Add billing/credits to your OpenAI account or use a different API key.';
    }

    if (e.response?.statusCode == 429) {
      return 'AI rate limit reached. Please wait a bit and try again.';
    }

    return message;
  }
}
