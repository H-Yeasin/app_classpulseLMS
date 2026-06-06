class TeacherClassModel {
  final String id;
  final String teacherId;
  final int grade;
  final String subject;
  final String? section;
  final String? schedule;
  final int studentCount;
  final String attendance;
  final String performance;

  TeacherClassModel({
    required this.id,
    required this.teacherId,
    required this.grade,
    required this.subject,
    this.section,
    this.schedule,
    this.studentCount = 0,
    this.attendance = "0%",
    this.performance = "0%",
  });

  factory TeacherClassModel.fromJson(Map<String, dynamic> json) {
    return TeacherClassModel(
      id: json['_id'] ?? '',
      teacherId: json['teacherId'] is Map ? (json['teacherId']['_id'] ?? '') : (json['teacherId'] ?? ''),
      grade: json['grade'] ?? 0,
      subject: json['subject'] ?? '',
      section: json['section'],
      schedule: json['schedule'],
    );
  }

  TeacherClassModel copyWith({
    int? studentCount,
    String? attendance,
    String? performance,
  }) {
    return TeacherClassModel(
      id: id,
      teacherId: teacherId,
      grade: grade,
      subject: subject,
      section: section,
      schedule: schedule,
      studentCount: studentCount ?? this.studentCount,
      attendance: attendance ?? this.attendance,
      performance: performance ?? this.performance,
    );
  }
}
