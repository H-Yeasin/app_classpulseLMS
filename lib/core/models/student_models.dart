import 'package:opalmer_education/core/models/user_model.dart';
import 'package:intl/intl.dart';

class LessonModel {
  final String id;
  final String studentId;
  final String? teacherId;
  final String? classId;
  final String objective;
  final String note;
  final String? documentUrl;
  final bool isArchived;
  final DateTime? createdAt;
  final UserModel? teacher;

  LessonModel({
    required this.id,
    required this.studentId,
    this.teacherId,
    this.classId,
    required this.objective,
    required this.note,
    this.documentUrl,
    required this.isArchived,
    this.createdAt,
    this.teacher,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['_id'] ?? '',
      studentId: json['studentId'] is Map ? json['studentId']['_id'] : (json['studentId'] ?? ''),
      teacherId: json['teacherId'] is Map ? json['teacherId']['_id'] : json['teacherId'],
      classId: json['classId'] is Map ? json['classId']['_id'] : json['classId'],
      objective: json['objective'] ?? '',
      note: json['note'] ?? '',
      documentUrl: json['document']?['url'],
      isArchived: json['isArchived'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      teacher: json['teacherId'] is Map ? UserModel.fromJson(json['teacherId']) : null,
    );
  }
}

class HomeworkModel {
  final String id;
  final String classId;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final List<String> fileUrls;
  final bool archived;
  final DateTime? createdAt;

  HomeworkModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    required this.fileUrls,
    required this.archived,
    this.createdAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['file'];
    List<String> urls = [];
    if (rawFiles is List) {
      urls = rawFiles
          .map((f) => f is Map ? (f['url']?.toString() ?? '') : f.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return HomeworkModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      classId: json['classId'] is Map
          ? (json['classId']['_id']?.toString() ?? '')
          : (json['classId']?.toString() ?? ''),
      userId: json['userId'] is Map
          ? (json['userId']['_id']?.toString() ?? '')
          : (json['userId']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      fileUrls: urls,
      archived: json['archived'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String? description;
  final String? classId;
  final String? classSubject;
  final int? classGrade;
  final String? teacherId;
  final DateTime? createdAt;
  final String? teacherName;
  final int questionCount;
  final int durationMinutes;
  final String status;
  final String? image;

  QuizModel({
    required this.id,
    required this.title,
    this.description,
    this.classId,
    this.classSubject,
    this.classGrade,
    this.teacherId,
    this.createdAt,
    this.teacherName,
    this.questionCount = 0,
    this.durationMinutes = 0,
    this.status = '',
    this.image,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    // Handle nested teacher object from aggregation or student results
    String? tName;
    if (json['teacher'] != null && json['teacher'] is Map) {
      tName = json['teacher']['username'];
    } else if (json['teacherId'] != null && json['teacherId'] is Map) {
      tName = json['teacherId']['username'];
    }

    String? resolvedClassId;
    String? resolvedClassSubject;
    int? resolvedClassGrade;
    if (json['class'] is Map) {
      resolvedClassId = json['class']['_id']?.toString();
      resolvedClassSubject = json['class']['subject']?.toString();
      final grade = json['class']['grade'];
      if (grade is int) {
        resolvedClassGrade = grade;
      } else if (grade is num) {
        resolvedClassGrade = grade.toInt();
      } else {
        resolvedClassGrade = int.tryParse(grade?.toString() ?? '');
      }
    } else if (json['classId'] is Map) {
      resolvedClassId = json['classId']['_id']?.toString();
      resolvedClassSubject = json['classId']['subject']?.toString();
      final grade = json['classId']['grade'];
      if (grade is int) {
        resolvedClassGrade = grade;
      } else if (grade is num) {
        resolvedClassGrade = grade.toInt();
      } else {
        resolvedClassGrade = int.tryParse(grade?.toString() ?? '');
      }
    } else {
      resolvedClassId = json['classId']?.toString();
    }

    return QuizModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      classId: resolvedClassId,
      classSubject: resolvedClassSubject,
      classGrade: resolvedClassGrade,
      teacherId: json['teacherId'] is Map ? json['teacherId']['_id'] : json['teacherId'],
      teacherName: tName,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      questionCount: parseInt(json['questionCount']),
      durationMinutes: parseInt(json['time']),
      status: json['status']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  /// Human-friendly subtitle used on quiz cards. Falls back to the description
  /// when the backend hasn't populated counts yet.
  String get metaLine {
    final parts = <String>[];
    if ((classSubject ?? '').trim().isNotEmpty) {
      parts.add(classSubject!.trim());
    }
    if (questionCount > 0) {
      parts.add('$questionCount ${questionCount == 1 ? 'Question' : 'Questions'}');
    }
    if (durationMinutes > 0) parts.add('$durationMinutes min');
    if (parts.isEmpty) return (description ?? '').trim();
    return parts.join(' · ');
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;
  final String difficulty;
  final String type;
  final String imageUrl;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.explanation = '',
    this.difficulty = 'medium',
    this.type = 'normal',
    this.imageUrl = '',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
      explanation: json['explanation']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      type: json['type']?.toString() ?? 'normal',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class QuizQA {
  final String id;
  final String quizId;
  final List<QuizQuestion> questions;

  QuizQA({
    required this.id,
    required this.quizId,
    required this.questions,
  });

  factory QuizQA.fromJson(Map<String, dynamic> json) {
    var qs = json['questions'] as List? ?? [];
    return QuizQA(
      id: json['_id'] ?? '',
      quizId: json['quizId'] ?? '',
      questions: qs.map((q) => QuizQuestion.fromJson(q)).toList(),
    );
  }
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final String status; // e.g., "Present", "Absent"
  final String? note;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.note,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: (json['status'] ?? json['present'] ?? 'Absent').toString(),
      note: json['note'],
    );
  }

  bool get isPresent => status.toLowerCase() == 'present';
  bool get isHoliday => status.toLowerCase() == 'holiday';
}

class BehaviorRecord {
  final String id;
  final String message;
  final String state; // "positive" | "negative"
  final DateTime? createdAt;

  const BehaviorRecord({
    required this.id,
    required this.message,
    required this.state,
    this.createdAt,
  });

  factory BehaviorRecord.fromJson(Map<String, dynamic> json) {
    return BehaviorRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      state: (json['state'] ?? 'positive').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  bool get isPositive => state.toLowerCase() == 'positive';
}

class QuizResultModel {
  final String id;
  final String? quizId;
  final String? classId;
  final String quizTitle;
  final int score;
  final double percentage;
  final String status;
  final DateTime? createdAt;

  QuizResultModel({
    required this.id,
    this.quizId,
    this.classId,
    required this.quizTitle,
    required this.score,
    required this.percentage,
    required this.status,
    this.createdAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    // Handle both populated and non-populated quizId
    String title = "Unknown Quiz";
    String? qId;
    String? cId;
    
    if (json['quizId'] is Map) {
      title = json['quizId']['title'] ?? "Unknown Quiz";
      qId = json['quizId']['_id'];
      cId = json['quizId']['classId']?.toString();
    } else {
      qId = json['quizId']?.toString();
    }

    return QuizResultModel(
      id: json['_id'] ?? '',
      quizId: qId,
      classId: cId,
      quizTitle: title,
      score: (json['score'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? 0).toDouble() / 100.0, // Scale to 0.0-1.0 for progress bar
      status: json['progress']?['status'] ?? 'completed',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class QuizSubmissionResult {
  final int correctCount;
  final int totalQuestions;
  final double percentage;
  final List<QuizAnswerSummary> answers;

  QuizSubmissionResult({
    required this.correctCount,
    required this.totalQuestions,
    required this.percentage,
    required this.answers,
  });

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    var answerList = json['answers'] as List? ?? [];
    return QuizSubmissionResult(
      correctCount: (json['correctCount'] ?? 0).toInt(),
      totalQuestions: (json['totalQuestions'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      answers: answerList.map((e) => QuizAnswerSummary.fromJson(e)).toList(),
    );
  }
}

class QuizAnswerSummary {
  final String question;
  final String selectedAnswer;
  final String? correctAnswer;
  final bool isCorrect;

  QuizAnswerSummary({
    required this.question,
    required this.selectedAnswer,
    this.correctAnswer,
    required this.isCorrect,
  });

  factory QuizAnswerSummary.fromJson(Map<String, dynamic> json) {
    return QuizAnswerSummary(
      question: json['question'] ?? '',
      selectedAnswer: json['selectedAnswer'] ?? '',
      correctAnswer: json['correctAnswer'], // Might need to be added to backend response
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}

class StudentClassModel {
  final String id;
  final String subject;
  final int grade;
  final String? section;
  final String? schedule;
  final String? teacherId;
  final String? teacherName;
  final String? teacherAvatar;
  final int? attendancePercentage;
  final int? performancePercentage;
  final DateTime? lastActivityDate;
  final List<WeeklyProgress> weeklyProgress;

  StudentClassModel({
    required this.id,
    required this.subject,
    required this.grade,
    this.section,
    this.schedule,
    this.teacherId,
    this.teacherName,
    this.teacherAvatar,
    this.attendancePercentage,
    this.performancePercentage,
    this.lastActivityDate,
    this.weeklyProgress = const [],
  });

  factory StudentClassModel.fromJson(Map<String, dynamic> json) {
    // Handle teacher population
    String? tName;
    String? tId;
    if (json['teacherId'] is Map) {
      tName = json['teacherId']['username'];
      tId = json['teacherId']['_id']?.toString();
    } else {
      tId = json['teacherId']?.toString();
    }

    var wp = json['weeklyProgress'] as List? ?? [];

    return StudentClassModel(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? 'Unknown',
      grade: json['grade'] ?? 0,
      section: json['section'],
      schedule: json['schedule'],
      teacherId: tId,
      teacherName: tName,
      teacherAvatar: json['teacherAvatar'],
      attendancePercentage: json['attendancePercentage'],
      performancePercentage: json['performancePercentage'],
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.tryParse(json['lastActivityDate'])
          : null,
      weeklyProgress: wp.map((e) => WeeklyProgress.fromJson(e)).toList(),
    );
  }

  String get formattedLastActivity {
    if (lastActivityDate == null) return "N/A";
    return DateFormat('dd-MM-yy').format(lastActivityDate!);
  }
}

class WeeklyProgress {
  final String dayLabel;
  final int? percentage;

  WeeklyProgress({required this.dayLabel, this.percentage});

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      dayLabel: json['dayLabel'] ?? '',
      percentage: json['percentage'],
    );
  }
}

class AcademicDocumentModel {
  final String id;
  final String? studentId;
  final String? teacherId;
  final String? teacherName;
  final String? url;
  final DateTime? createdAt;

  AcademicDocumentModel({
    required this.id,
    this.studentId,
    this.teacherId,
    this.teacherName,
    this.url,
    this.createdAt,
  });

  factory AcademicDocumentModel.fromJson(Map<String, dynamic> json) {
    return AcademicDocumentModel(
      id: json['_id'] ?? '',
      studentId: json['studentId'] is Map
          ? json['studentId']['_id']
          : json['studentId']?.toString(),
      teacherId: json['teacherId'] is Map
          ? json['teacherId']['_id']
          : json['teacherId']?.toString(),
      teacherName:
          json['teacherId'] is Map ? json['teacherId']['username'] : null,
      url: (json['document'] is Map
              ? json['document']['url']?.toString()
              : null) ??
          (json['url'] is Map
              ? json['url']['url']?.toString()
              : json['url']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class GroupMemberModel {
  final String id;
  final String username;
  final String? avatar;

  GroupMemberModel({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] is Map
          ? json['avatar']['url']?.toString()
          : json['avatar']?.toString(),
    );
  }
}

class GroupWorkModel {
  final String id;
  final String classId;
  final List<GroupMemberModel> members;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final List<String> fileUrls;
  final bool archived;
  final DateTime? createdAt;

  GroupWorkModel({
    required this.id,
    required this.classId,
    required this.members,
    required this.title,
    this.description,
    this.dueDate,
    required this.fileUrls,
    required this.archived,
    this.createdAt,
  });

  factory GroupWorkModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['userId'];
    List<GroupMemberModel> members = [];
    if (rawMembers is List) {
      members = rawMembers
          .map((e) => e is Map<String, dynamic>
              ? GroupMemberModel.fromJson(e)
              : GroupMemberModel(id: e.toString(), username: 'Member'))
          .toList();
    }

    final rawFiles = json['file'];
    List<String> urls = [];
    if (rawFiles is List) {
      urls = rawFiles
          .map((f) => f is Map ? (f['url']?.toString() ?? '') : f.toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return GroupWorkModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      classId: json['classId'] is Map 
          ? (json['classId']['_id']?.toString() ?? '') 
          : (json['classId']?.toString() ?? ''),
      members: members,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      fileUrls: urls,
      archived: json['archived'] ?? false,
      createdAt:
          json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
