import 'package:opalmer_education/core/constants/api_constants.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/models/teacher_class_model.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';
import 'package:opalmer_education/core/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final teacherQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiConstants.quizzesByTeacher(user.id));

  if (response.statusCode == 200 && response.data['success'] == true) {
    final List<dynamic> quizData = response.data['data'] ?? [];
    return quizData
        .whereType<Map<String, dynamic>>()
        .map((json) => QuizModel.fromJson(json))
        .toList();
  }

  return [];
});

final teacherClassesProvider = FutureProvider<List<TeacherClassModel>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final apiClient = ref.read(apiClientProvider);
  
  // 1. Fetch all classes for this teacher
  final response = await apiClient.get('/classes/teacher/${user.id}');
  
  if (response.statusCode == 200 && response.data['success'] == true) {
    final List<dynamic> classData = response.data['data'];
    final List<TeacherClassModel> classes = classData.map((e) => TeacherClassModel.fromJson(e)).toList();

    // 2. For each class, fetch the students explicitly assigned to it.
    final updatedClasses = await Future.wait(classes.map((cls) async {
      try {
        final stuResponse = await apiClient.get('/student-assign-to-class/class/${cls.id}');
        if (stuResponse.statusCode == 200 && stuResponse.data['success'] == true) {
          final assignments = stuResponse.data['data'];
          if (assignments is List) {
            return cls.copyWith(studentCount: assignments.length);
          }
        }
      } catch (e) {
        // Log error or handle gracefully
      }
      return cls;
    }));

    return updatedClasses;
  }
  
  return [];
});

final classStudentsProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final apiClient = ref.read(apiClientProvider);

  final response = await apiClient.get('/student-assign-to-class/class/$classId');
  
  if (response.statusCode == 200 && response.data['success'] == true) {
    final data = response.data['data'];
    if (data is List) return data;
  }
  return [];
});

final classLessonsProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/lessons/teacher-lessons');
  if (response.statusCode == 200 && response.data['success'] == true) {
    final List<dynamic> allLessons = response.data['data'];
    // Filter by classId since this screen is for a specific class
    return allLessons.where((lesson) {
      final cId = lesson['classId'];
      if (cId is Map) {
        return cId['_id'] == classId;
      }
      return cId == classId;
    }).toList();
  }
  return [];
});

final classHomeworkProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/homework/class/$classId');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data'];
  }
  return [];
});

final userRoomsProvider = FutureProvider<List<dynamic>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get(ApiConstants.myRooms);
  if (response.statusCode == 200 && response.data['success'] == true) {
    final data = response.data['data'];
    if (data is! List) return [];

    return data
        .where(
          (room) => room is Map<String, dynamic> && room['type'] == 'group',
        )
        .toList();
  }
  return [];
});

final classAttendanceStatsProvider = FutureProvider.family<int, String>((ref, classId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/attendances/class/$classId/stats');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data']['percentage'] ?? 0;
  }
  return 0;
});

final studentAttendanceStatsProvider =
    FutureProvider.family<int, String>((ref, params) async {
  final apiClient = ref.read(apiClientProvider);
  final parts = params.split('|');
  final studentId = parts[0];
  final classId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;

  final response = await apiClient.get(
    '/attendances/student/$studentId/stats',
    queryParameters: classId != null ? {'classId': classId} : null,
  );

  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data']['percentage'] ?? 0;
  }
  return 0;
});

final studentAnalysisProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, paramString) async {
  final apiClient = ref.read(apiClientProvider);
  final parts = paramString.split('|');
  if (parts.length < 2) return {};
  
  final classId = parts[0];
  final studentId = parts[1];
  final filter = parts.length > 2 ? parts[2] : 'weekly';

  final response = await apiClient.get(
    '/analysis/$classId/$studentId',
    queryParameters: {'filter': filter},
  );

  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data'];
  }
  return {};
});

final classAttendanceProvider = FutureProvider.family<List<dynamic>, String>((ref, classId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/attendances/class', queryParameters: {'classId': classId});
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data'];
  }
  return [];
});

final studentParentsProvider = FutureProvider.family<List<dynamic>, String>((ref, studentId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/parent/child/child/$studentId');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data']['parents'] ?? [];
  }
  return [];
});

final parentChildrenProvider = FutureProvider.family<List<dynamic>, String>((ref, parentId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/parent/child/parent/$parentId');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data']['children'] ?? [];
  }
  return [];
});

final studentQuizResultsProvider = FutureProvider.family<List<dynamic>, String>((ref, studentId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/test/quizzes/answers/$studentId');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data'] ?? [];
  }
  return [];
});

final studentBehaviorsProvider = FutureProvider.family<List<dynamic>, String>((ref, studentId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/behavior/student/$studentId');
  if (response.statusCode == 200 && response.data['success'] == true) {
    return response.data['data'] ?? [];
  }
  return [];
});

final createBehaviorProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, data) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.post('/behavior/create', data: data);
  return response.statusCode == 200 && response.data['success'] == true;
});

final updateBehaviorProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final apiClient = ref.read(apiClientProvider);
  final behaviorId = params['behaviorId'];
  final data = params['data'];
  final response = await apiClient.put('/behavior/update/$behaviorId', data: data);
  return response.statusCode == 200 && response.data['success'] == true;
});

final deleteBehaviorProvider = FutureProvider.family<bool, String>((ref, behaviorId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.delete('/behavior/delete/$behaviorId');
  return response.statusCode == 200 && response.data['success'] == true;
});

final studentAcademicDocumentsProvider =
    FutureProvider.family<List<AcademicDocumentModel>, String>(
        (ref, studentId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('/academicDocument/teacher-documents');
  if (response.statusCode == 200 && response.data['success'] == true) {
    final List<dynamic> allDocs = response.data['data'] ?? [];
    return allDocs
        .map((e) => AcademicDocumentModel.fromJson(e))
        .where((doc) => doc.studentId == studentId)
        .toList();
  }
  return [];
});

final deleteAcademicDocumentProvider = FutureProvider.family<bool, String>((ref, docId) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.delete('/academicDocument/delete/$docId');
  return response.statusCode == 200 && response.data['success'] == true;
});



