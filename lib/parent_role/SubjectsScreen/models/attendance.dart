enum AttendanceStatus { present, absent, tardy, holiday, unknown }

class AttendanceRecord {
  final String id;
  final String date;
  final String studentName;
  final AttendanceStatus status;
  final String rawStatus;

  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.studentName,
    required this.status,
    required this.rawStatus,
  });

  String get statusText {
    switch (status) {
      case AttendanceStatus.present:
        return "Present";
      case AttendanceStatus.absent:
        return "Absent";
      case AttendanceStatus.tardy:
        return "Tardy";
      case AttendanceStatus.holiday:
        return "Holiday";
      case AttendanceStatus.unknown:
        return rawStatus.isEmpty ? "—" : rawStatus;
    }
  }

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    String studentNameFallback = '',
  }) {
    final rawStatus = _readStatus(json);
    return AttendanceRecord(
      id: (json['_id'] ?? '').toString(),
      date: _formatDate(json['date']) ?? '—',
      studentName: studentNameFallback,
      status: _parseStatus(rawStatus),
      rawStatus: rawStatus,
    );
  }

  static String _readStatus(Map<String, dynamic> json) {
    const keys = ['status', 'statusText', 'statusLabel', 'customStatus'];
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static AttendanceStatus _parseStatus(dynamic raw) {
    if (raw is! String) return AttendanceStatus.unknown;
    switch (raw.trim().toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'tardy':
        return AttendanceStatus.tardy;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.unknown;
    }
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
