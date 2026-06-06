class GradingProgressData {
  final int overallPercentage;
  final int completedCount;
  final List<GradingRecord> records;

  const GradingProgressData({
    required this.overallPercentage,
    required this.completedCount,
    required this.records,
  });

  factory GradingProgressData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final records = json['records'];

    return GradingProgressData(
      overallPercentage: _readInt(summary, 'overallPercentage'),
      completedCount: _readInt(summary, 'completedCount'),
      records: records is List
          ? records
                .whereType<Map>()
                .map(
                  (item) =>
                      GradingRecord.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static int _readInt(dynamic value, String key) {
    if (value is Map && value[key] != null) {
      return int.tryParse(value[key].toString()) ?? 0;
    }
    return 0;
  }
}

class GradingRecord {
  final String id;
  final String sessionId;
  final String title;
  final String date;
  final int score;
  final int totalQuestions;
  final double percentage;
  final String percentageLabel;
  final String status;
  final String classSubject;
  final String teacherName;

  const GradingRecord({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.percentageLabel,
    required this.status,
    required this.classSubject,
    required this.teacherName,
  });

  factory GradingRecord.fromJson(Map<String, dynamic> json) {
    final rawPercentage = _readNum(json['percentage']).clamp(0, 100);
    final classData = json['class'];
    final teacher = json['teacher'];

    return GradingRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
      title: (json['title'] ?? 'Grading Session').toString(),
      date: _formatDate(json['date']) ?? '',
      score: _readNum(json['score']).round(),
      totalQuestions: _readNum(json['totalQuestions']).round(),
      percentage: rawPercentage / 100,
      percentageLabel: '${rawPercentage.round()}%',
      status: (json['status'] ?? '').toString(),
      classSubject: _readNestedText(classData, 'subject'),
      teacherName: _readNestedText(teacher, 'username', fallback: 'Teacher'),
    );
  }

  String get scoreLabel => '$score/$totalQuestions';

  static num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readNestedText(
    dynamic value,
    String key, {
    String fallback = '',
  }) {
    if (value is Map && value[key] != null) {
      return value[key].toString();
    }
    return fallback;
  }

  static String? _formatDate(dynamic iso) {
    if (iso is! String || iso.isEmpty) return null;
    try {
      final date = DateTime.parse(iso).toLocal();
      final dd = date.day.toString().padLeft(2, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final yy = (date.year % 100).toString().padLeft(2, '0');
      return '$dd-$mm-$yy';
    } catch (_) {
      return null;
    }
  }
}
