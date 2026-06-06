class Subject {
  final String id;
  final String name;
  final String attendance;
  final String attendanceEmoji;
  final String performance;
  final String? teacherId;
  final String teacherName;
  final String teacherAvatar;
  final String date;
  final List<SubjectProgressPoint>? weeklyProgress;

  const Subject({
    required this.id,
    required this.name,
    required this.attendance,
    required this.attendanceEmoji,
    required this.performance,
    this.teacherId,
    required this.teacherName,
    required this.teacherAvatar,
    required this.date,
    this.weeklyProgress,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacherId'];
    final teacherMap = teacher is Map ? Map<String, dynamic>.from(teacher) : null;
    final avatar = teacherMap?['avatar'];
    final avatarUrl =
        avatar is Map ? (avatar['url']?.toString() ?? '') : (avatar?.toString() ?? '');

    final attendanceValue = json['attendancePercentage'];
    final performanceValue = json['performancePercentage'];

    final rawProgress = json['weeklyProgress'] as List?;
    final progressPoints = rawProgress == null
        ? null
        : List<SubjectProgressPoint>.generate(rawProgress.length, (i) {
            final p = rawProgress[i] as Map<String, dynamic>;
            final pct = p['percentage'];
            return SubjectProgressPoint(
              i.toDouble(),
              (pct is num) ? pct.toDouble() : 0,
              (p['dayLabel'] ?? '').toString(),
            );
          });

    return Subject(
      id: (json['_id'] ?? '').toString(),
      name: (json['subject'] ?? '').toString(),
      attendance: _formatPercent(attendanceValue),
      attendanceEmoji: _emojiForPercent(attendanceValue),
      performance: _formatPercent(performanceValue),
      teacherId: teacherMap?['_id']?.toString() ?? teacher?.toString(),
      teacherName: (teacherMap?['username'] ?? '—').toString(),
      teacherAvatar: avatarUrl,
      date: _formatDate(json['lastActivityDate']),
      weeklyProgress: progressPoints,
    );
  }

  static String _formatPercent(dynamic v) {
    if (v is num) return '${v.round()}%';
    return '—';
  }

  static String _emojiForPercent(dynamic v) {
    if (v is! num) return '😕';
    if (v >= 90) return '🌟';
    if (v >= 75) return '😎';
    if (v >= 50) return '😇';
    return '😕';
  }

  static String _formatDate(dynamic iso) {
    if (iso is! String || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yy = (d.year % 100).toString().padLeft(2, '0');
      return '$dd-$mm-$yy';
    } catch (_) {
      return '—';
    }
  }
}

class SubjectProgressPoint {
  final double x; // Represents day (0-6)
  final double y; // Represents percentage (0-100)
  final String dayLabel;

  const SubjectProgressPoint(this.x, this.y, this.dayLabel);
}

class ChildProfile {
  final String id;
  final String name;
  final String imageUrl;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    String imageUrl = '';
    if (avatar is Map) {
      imageUrl = (avatar['url']?.toString() ?? '');
    } else if (avatar is String) {
      imageUrl = avatar;
    }
    return ChildProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['username'] ?? json['name'] ?? '').toString(),
      imageUrl: imageUrl,
    );
  }
}

const List<ChildProfile> mockChildren = [
  ChildProfile(
    id: "1",
    name: "Mia Johnson",
    imageUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
  ChildProfile(
    id: "2",
    name: "Alex Johnson",
    imageUrl: "https://images.unsplash.com/photo-1517677129300-07b130802f46?auto=format&fit=crop&w=150&q=80",
  ),
];

// Mock Progress Data
const List<SubjectProgressPoint> scienceProgress = [
  SubjectProgressPoint(0, 30, "Sun"),
  SubjectProgressPoint(1, 38, "Mon"),
  SubjectProgressPoint(2, 32, "Tue"),
  SubjectProgressPoint(3, 45, "Wed"),
  SubjectProgressPoint(4, 55, "Thu"),
  SubjectProgressPoint(5, 42, "Fri"),
  SubjectProgressPoint(6, 42, "Sat"),
];

const List<Subject> mockSubjects = [
  Subject(
    id: "s1",
    name: "Science",
    attendance: "92%",
    attendanceEmoji: "😇",
    performance: "85%",
    teacherName: "Olivia Carter",
    teacherAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=60",
    date: "06-03-25",
    weeklyProgress: scienceProgress,
  ),
  Subject(
    id: "s2",
    name: "Mathematics",
    attendance: "88%",
    attendanceEmoji: "😎",
    performance: "90%",
    teacherName: "Benjamin Wade",
    teacherAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=60",
    date: "06-03-25",
  ),
  Subject(
    id: "s3",
    name: "English",
    attendance: "95%",
    attendanceEmoji: "🌟",
    performance: "92%",
    teacherName: "Sophia Miller",
    teacherAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=100&q=60",
    date: "06-03-25",
  ),
];
