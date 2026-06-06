class AcademicDocument {
  final String id;
  final String title;
  final String downloadUrl;
  final String teacherName;
  final String studentName;
  final String date;

  const AcademicDocument({
    required this.id,
    required this.title,
    required this.downloadUrl,
    required this.teacherName,
    required this.studentName,
    required this.date,
  });

  factory AcademicDocument.fromJson(
    Map<String, dynamic> json, {
    String studentNameFallback = '',
  }) {
    final document = json['document'];
    final url = _readNestedText(document, 'url');
    final publicId = _readNestedText(document, 'public_id');
    final teacher = json['teacherId'];
    final student = json['studentId'];

    return AcademicDocument(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: _documentTitle(url, publicId),
      downloadUrl: url,
      teacherName: _readNestedText(teacher, 'username', fallback: 'Teacher'),
      studentName: _readNestedText(
        student,
        'username',
        fallback: studentNameFallback,
      ),
      date: _formatDate(json['created_at']) ?? '',
    );
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

  static String _documentTitle(String url, String publicId) {
    final uri = Uri.tryParse(url);
    final urlName = uri?.pathSegments.isNotEmpty == true
        ? Uri.decodeComponent(uri!.pathSegments.last)
        : '';
    final publicName = publicId.split('/').last;

    if (urlName.trim().isNotEmpty) return urlName.trim();
    if (publicName.trim().isNotEmpty) return publicName.trim();
    return 'Academic Document';
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
