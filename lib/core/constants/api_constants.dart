class ApiConstants {
  // Production Server: https://api.classpulse.info/api/v1
  static const String baseUrl = 'https://api.classpulse.info/api/v1';
  // Local Development Server
  // static const String baseUrl = 'http://10.0.2.2:5000/api/v1';

  // Auth Endpoints
  static const String login = '/users/login';
  static const String register = '/users/register';

  static const String me = '/users/me';
  static const String logout = '/users/logout';
  static const String changePassword = '/users/change-password';

  static const String profile = '/users/profile';
  // Academics Endpoints
  static const String lessons = '/lessons';
  static const String homework = '/homework';
  static const String academicDocument = '/academicDocument/student-documents';
  static const String childAcademicDocuments =
      '/academicDocument/child-documents';
  static const String stuAssignToClass = '/student-assign-to-class';

  // Quizzes Endpoints
  static const String quizzes = '/quizzes';
  static String quizzesByStudent(String studentId) =>
      '/quizzes/student/$studentId';
  static String quizzesByTeacher(String teacherId) =>
      '/quizzes/teacher/$teacherId';
  static const String quizQA = '/quiz/qa';
  static const String submitQuiz = '/test/quizzes';
  static const String quizResults = '/test/quizzes/answers';

  // Attendance Endpoints
  static const String attendance = '/attendances';

  // Behavior
  static const String studentBehaviors = '/behavior/student-behaviors';

  // Grading
  static const String childGradingProgress = '/grading/child-progress';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read';

  // Socket
  static const String socketBaseUrl = 'https://api.classpulse.info';
  static String get apiOrigin =>
      baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  // Learning Tips Endpoints
  static const String learningTipsByParent = '/learning-tips/by-parent/me';

  // Parent → Children
  static String childrenByParent(String parentId) =>
      '/parent/child/parent/$parentId';

  // Classes per student (enriched with teacher avatar, attendance %, performance %, date, weekly progress)
  static String classesByStudent(String studentId) =>
      '/classes/student/$studentId';

  // Homework per class — supports ?archived=true|false
  static String homeworkByClass(String classId) => '/homework/class/$classId';

  // Lessons per class
  static String lessonsByClass(String classId) => '/lessons/class/$classId';

  // Group homework per class — members are populated with username + avatar
  static String groupWorkByClass(String classId) =>
      '/group-work/class/$classId';

  // Attendance list for a single student in a single class (paginated)
  static const String attendanceByStudent = '/attendances/student';

  // Chat Endpoints
  static const String rooms = '/rooms';
  static const String messages = '/message';
  static String roomMessages(String roomId) => '/message/$roomId';
  static String get myRooms => '/rooms/my-rooms';

  // Call Logs
  static const String callLogs = '/call-logs';
  static const String myCallLogs = '/call-logs/my-logs';

  static String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return '$apiOrigin$path';
    }
    return '$apiOrigin/$path';
  }
}
