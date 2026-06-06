import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/models/student_models.dart';
import 'package:opalmer_education/core/services/student_service.dart';
import 'package:opalmer_education/core/providers/auth_provider.dart';

final studentServiceProvider = Provider<StudentService>(
  (ref) => StudentService(),
);

final studentDashboardDataProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return await ref.watch(studentServiceProvider).getStudentDashboardData();
});

final studentLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  return await ref.watch(studentServiceProvider).getLessons();
});

final studentQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  final studentId = ref.watch(authStateProvider)?.id;
  if (studentId == null) return [];
  return await ref.watch(studentServiceProvider).getQuizzes(studentId);
});

final studentHomeworkProvider = FutureProvider<List<HomeworkModel>>((
  ref,
) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final service = ref.read(studentServiceProvider);

  try {
    debugPrint('studentHomeworkProvider: Starting fetch for user ${user.id}');

    // 1. WAIT for classes to finish loading before fetching homework.
    //    Previously used .value ?? [] which returned empty during loading (race condition).
    final classes = await ref.watch(studentClassesProvider.future);

    if (classes.isEmpty) {
      debugPrint('studentHomeworkProvider: No classes found, returning empty');
      return [];
    }

    // 2. Fetch homework for every class the student is enrolled in.
    //    Note: homework.userId refers to the TEACHER who created it, not the student,
    //    so we must query by classId, NOT by student userId.
    final List<Future<List<HomeworkModel>>> fetches = classes
        .where((cls) => cls.id.isNotEmpty)
        .map((cls) => service.getHomeworkByClass(cls.id))
        .toList();

    // 3. Execute concurrently with timeout protection
    final results = await Future.wait(fetches).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('studentHomeworkProvider: Fetch timed out');
        return <List<HomeworkModel>>[];
      },
    );

    final List<HomeworkModel> allHomework = [];
    for (var list in results) {
      allHomework.addAll(list);
    }

    // 4. Deduplicate by id
    final Map<String, HomeworkModel> uniqueHomework = {};
    for (final h in allHomework) {
      if (h.id.isNotEmpty) uniqueHomework[h.id] = h;
    }

    final resultList = uniqueHomework.values.toList();
    debugPrint(
      'studentHomeworkProvider: Completed with ${resultList.length} items',
    );

    resultList.sort((a, b) {
      final dateA = a.createdAt;
      final dateB = b.createdAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return resultList;
  } catch (e, stack) {
    debugPrint('studentHomeworkProvider ERROR: $e');
    debugPrint(stack.toString());
    rethrow;
  }
});

final studentGroupWorkProvider = FutureProvider<List<GroupWorkModel>>((
  ref,
) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final service = ref.read(studentServiceProvider);

  try {
    // 1. Wait for enrolled classes to finish loading (fixes race condition)
    final classes = await ref.watch(studentClassesProvider.future);
    if (classes.isEmpty) return [];

    final List<GroupWorkModel> allGroupWork = [];

    // 2. Fetch group work for each class
    final classFetches = classes.map(
      (cls) => service.getGroupWorkByClass(cls.id),
    );
    final results = await Future.wait(
      classFetches,
    ).timeout(const Duration(seconds: 15), onTimeout: () => []);

    for (var list in results) {
      allGroupWork.addAll(list);
    }

    // 3. Deduplicate
    final Map<String, GroupWorkModel> uniqueGW = {};
    for (final gw in allGroupWork) {
      if (gw.id.isNotEmpty) uniqueGW[gw.id] = gw;
    }

    final resultList = uniqueGW.values.toList();

    // 4. Sort by date
    resultList.sort((a, b) {
      final dateA = a.createdAt;
      final dateB = b.createdAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return resultList;
  } catch (e) {
    debugPrint('studentGroupWorkProvider error: $e');
    rethrow;
  }
});

final studentAcademicDocumentsProvider =
    FutureProvider<List<AcademicDocumentModel>>((ref) async {
      return await ref.watch(studentServiceProvider).getAcademicDocuments();
    });

final studentClassesProvider = FutureProvider<List<StudentClassModel>>((
  ref,
) async {
  final studentId = ref.watch(authStateProvider)?.id;
  if (studentId == null) return [];
  try {
    return await ref.watch(studentServiceProvider).getStudentClasses(studentId);
  } catch (e) {
    debugPrint('studentClassesProvider error: $e');
    rethrow;
  }
});

final studentAttendanceProvider = FutureProvider<List<AttendanceRecord>>((
  ref,
) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final classes = await ref.watch(studentClassesProvider.future);
  if (classes.isEmpty) return [];

  final service = ref.watch(studentServiceProvider);
  final List<AttendanceRecord> allRecords = [];

  for (final cls in classes) {
    try {
      final records = await service.getAttendance(user.id, cls.id);
      allRecords.addAll(records);
    } catch (e) {
      // Skip classes that fail
    }
  }

  allRecords.sort((a, b) => b.date.compareTo(a.date));
  return allRecords;
});

final quizQAProvider = FutureProvider.family<QuizQA?, String>((
  ref,
  quizId,
) async {
  return await ref.watch(studentServiceProvider).getQuizQA(quizId);
});

final studentQuizResultsProvider = FutureProvider<List<QuizResultModel>>((
  ref,
) async {
  final studentId = ref.watch(authStateProvider)?.id;
  if (studentId == null) return [];
  return await ref.watch(studentServiceProvider).getQuizResults(studentId);
});

final studentBehaviorsProvider = FutureProvider<List<BehaviorRecord>>((
  ref,
) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return await ref.watch(studentServiceProvider).getStudentBehaviors();
});

final studentClassAttendanceProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((
  ref,
  classId,
) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return await ref.watch(studentServiceProvider).getAttendance(user.id, classId);
});

final studentClassQuizResultsProvider =
    FutureProvider.family<List<QuizResultModel>, String>((
  ref,
  classId,
) async {
  final allResults = await ref.watch(studentQuizResultsProvider.future);
  return allResults.where((r) => r.classId == classId).toList();
});
