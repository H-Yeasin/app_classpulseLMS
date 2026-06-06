import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/services/api_client.dart';

class StudentService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStudentDashboardData() async {
    try {
      // In a real scenario, you might have a dedicated dashboard API
      // If not, you can call multiple APIs here.
      // For now, let's assume we fetch lessons and homework as a summary.
      final lessonsResponse = await _apiClient.get(ApiConstants.lessons);
      final homeworkResponse = await _apiClient.get(ApiConstants.homework);

      return {
        'lessons': lessonsResponse.data['data'],
        'homework': homeworkResponse.data['data'],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LessonModel>> getLessons() async {
    try {
      final response = await _apiClient.get(ApiConstants.lessons);
      final rawData = response.data['data'];
      if (rawData is! List) return [];
      
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('StudentService: Error in getLessons: $e');
      return [];
    }
  }

  Future<List<HomeworkModel>> getHomework(String userId) async {
    try {
      debugPrint('StudentService: Fetching homework for user: $userId');
      final response = await _apiClient.get(
        '${ApiConstants.homework}/user/$userId',
      );
      debugPrint(
        'StudentService: getHomework response status: ${response.statusCode}',
      );

      var responseData = response.data['data'];
      if (responseData == null) {
        debugPrint('StudentService: No homework data found in response');
        return [];
      }

      List<dynamic> data = [];
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map && responseData.containsKey('homework')) {
        final homeworkList = responseData['homework'];
        if (homeworkList is List) data = homeworkList;
      }

      debugPrint(
        'StudentService: Found ${data.length} homework items for user',
      );
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => HomeworkModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      debugPrint('StudentService: Error in getHomework: $e');
      debugPrint(stack.toString());
      return []; // Return empty instead of rethrowing to avoid total UI hang
    }
  }

  Future<List<HomeworkModel>> getHomeworkByClass(String classId) async {
    try {
      debugPrint('StudentService: Fetching homework for class: $classId');
      final response = await _apiClient.get(
        ApiConstants.homeworkByClass(classId),
      );
      debugPrint(
        'StudentService: getHomeworkByClass response status: ${response.statusCode}',
      );

      var responseData = response.data['data'];
      if (responseData == null) return [];

      List<dynamic> data = [];
      if (responseData is List) {
        data = responseData;
      } else if (responseData is Map && responseData.containsKey('homework')) {
        final homeworkList = responseData['homework'];
        if (homeworkList is List) data = homeworkList;
      }

      debugPrint(
        'StudentService: Found ${data.length} homework items for class $classId',
      );
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => HomeworkModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      debugPrint('StudentService: Error in getHomeworkByClass ($classId): $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<GroupWorkModel>> getGroupWorkByClass(String classId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.groupWorkByClass(classId),
      );
      final rawData = response.data['data'];
      if (rawData is! List) return [];
      
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => GroupWorkModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('StudentService: Error in getGroupWorkByClass: $e');
      return [];
    }
  }

  Future<List<QuizModel>> getQuizzes(String studentId) async {
    try {
      debugPrint('StudentService: Fetching quizzes for student: $studentId');
      final response = await _apiClient.get(
        ApiConstants.quizzesByStudent(studentId),
      );
      debugPrint(
        'StudentService: getQuizzes response status: ${response.statusCode}',
      );

      final dynamic rawData = response.data['data'];
      List<dynamic> data = [];
      if (rawData is Map && rawData['quizzes'] is List) {
        data = rawData['quizzes'] as List<dynamic>;
      } else if (rawData is List) {
        data = rawData;
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => QuizModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      debugPrint('StudentService: Error in getQuizzes($studentId): $e');
      debugPrint(stack.toString());
      return [];
    }
  }

  Future<List<QuizResultModel>> getQuizResults(String studentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.quizResults}/$studentId',
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => QuizResultModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AcademicDocumentModel>> getAcademicDocuments() async {
    try {
      debugPrint('StudentService: Fetching academic documents');
      final response = await _apiClient.get(ApiConstants.academicDocument);
      debugPrint(
        'StudentService: getAcademicDocuments response status: ${response.statusCode}',
      );

      final List<dynamic> data = response.data['data'] ?? [];
      debugPrint('StudentService: Found ${data.length} academic documents');
      return data.map((json) => AcademicDocumentModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('StudentService: Error in getAcademicDocuments: $e');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAttendance(
    String userId,
    String classId,
  ) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.attendance}/student',
        queryParameters: {'userId': userId, 'classId': classId},
      );
      // print('Attendance response for class $classId: ${response.data}'); // Debugging
      // Backend returns { attendanceRecords, meta }
      final rawData = response.data['data'];
      List<dynamic> records = [];
      if (rawData is Map) {
        records = rawData['attendanceRecords'] as List? ?? [];
      }
      return records
          .whereType<Map<String, dynamic>>()
          .map((json) => AttendanceRecord.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    } catch (e) {
      debugPrint('StudentService: Error in getAttendance: $e');
      return [];
    }
  }

  Future<QuizQA?> getQuizQA(String quizId) async {
    try {
      debugPrint('StudentService: Fetching QA for quiz: $quizId');
      final response = await _apiClient.get('${ApiConstants.quizQA}/$quizId');
      debugPrint('StudentService: getQuizQA response status: ${response.statusCode}');
      
      if (response.data is Map && response.data['data'] != null) {
        return QuizQA.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('StudentService: DioException in getQuizQA ($quizId): ${e.message}');
      debugPrint('StudentService: Response status: ${e.response?.statusCode}');
      // 404 means the teacher hasn't generated questions for this quiz yet;
      // surface that to the UI as an empty state rather than a crash.
      if (e.response?.statusCode == 404) {
        debugPrint('StudentService: Quiz QA not found (404), returning null');
        return null;
      }
      rethrow;
    }
  }

  Future<bool> startQuiz(String quizId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.submitQuiz}/start',
        data: {'quizId': quizId},
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return true; // Already started
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> saveQuizProgress(
    String quizId,
    String question,
    String selectedAnswer,
  ) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.submitQuiz}/save-progress',
        data: {
          'quizId': quizId,
          'question': question,
          'selectedAnswer': selectedAnswer,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<QuizSubmissionResult?> submitQuiz(
    String quizId,
    String studentId,
    int score,
    int totalQuestions,
  ) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.submitQuiz}/submit',
        data: {
          'quizId': quizId,
          'studentId': studentId,
          'score': score,
          'totalQuestion': totalQuestions,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return QuizSubmissionResult.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<StudentClassModel>> getStudentClasses(String studentId) async {
    try {
      debugPrint('StudentService: Fetching classes for student: $studentId');
      final response = await _apiClient.get(
        ApiConstants.classesByStudent(studentId),
      );
      debugPrint(
        'StudentService: getStudentClasses response status: ${response.statusCode}',
      );

      final dynamic rawData = response.data['data'];
      List<dynamic> data = [];
      if (rawData is Map && rawData.containsKey('classes')) {
        final classesList = rawData['classes'];
        if (classesList is List) data = classesList;
      } else if (rawData is List) {
        data = rawData;
      }

      debugPrint('StudentService: Found ${data.length} classes for student');
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => StudentClassModel.fromJson(json))
          .toList();
    } catch (e, stack) {
      debugPrint('StudentService: Error in getStudentClasses: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Lightweight: fetches all classes (no enrichment) and returns IDs for a given grade.
  /// Used by homework/groupWork providers to avoid the heavy enrichment timeout.
  Future<List<String>> getClassIdsByGrade(int gradeLevel) async {
    try {
      final response = await _apiClient.get('/classes');
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .where((c) => c['grade'] == gradeLevel)
          .map<String>((c) => c['_id'].toString())
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BehaviorRecord>> getStudentBehaviors() async {
    try {
      final response = await _apiClient.get(ApiConstants.studentBehaviors);
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .whereType<Map>()
          .map((e) => BehaviorRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }
}
