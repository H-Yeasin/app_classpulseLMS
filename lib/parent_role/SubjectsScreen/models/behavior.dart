enum BehaviorType { positive, negative }

class BehaviorRecord {
  final String id;
  final String description;
  final BehaviorType type;
  final String teacherName;
  final String teacherAvatar;
  final String date;
  final String studentName;

  const BehaviorRecord({
    required this.id,
    required this.description,
    required this.type,
    required this.teacherName,
    required this.teacherAvatar,
    required this.date,
    required this.studentName,
  });

  String get typeText =>
      type == BehaviorType.positive ? "Positive" : "Negative";

  factory BehaviorRecord.fromJson(
    Map<String, dynamic> json, {
    String studentNameFallback = '',
  }) {
    final teacher = json['teacherId'];
    final student = json['studentId'];

    return BehaviorRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      description: (json['message'] ?? '').toString(),
      type: _parseType(json['state']),
      teacherName: _readNestedText(teacher, 'username', fallback: 'Teacher'),
      teacherAvatar: _readNestedAvatar(teacher),
      studentName: _readNestedText(
        student,
        'username',
        fallback: studentNameFallback,
      ),
      date: _formatDate(json['created_at']) ?? '—',
    );
  }

  static BehaviorType _parseType(dynamic raw) {
    return raw.toString().toLowerCase() == 'negative'
        ? BehaviorType.negative
        : BehaviorType.positive;
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

  static String _readNestedAvatar(dynamic value) {
    if (value is! Map) return '';
    final avatar = value['avatar'];
    if (avatar is Map && avatar['url'] != null) {
      return avatar['url'].toString();
    }
    return '';
  }

  static String? _formatDate(dynamic iso) {
    if (iso is! String || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yy = (d.year % 100).toString().padLeft(2, '0');
      return '$dd-$mm-$yy';
    } catch (_) {
      return null;
    }
  }
}
