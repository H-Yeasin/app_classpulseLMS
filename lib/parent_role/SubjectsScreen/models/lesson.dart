class Lesson {
  final String id;
  final String objective;
  final String note;
  final String documentUrl;
  final bool isArchived;
  final String createdAt;

  const Lesson({
    required this.id,
    required this.objective,
    required this.note,
    required this.documentUrl,
    required this.isArchived,
    required this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: (json['_id'] ?? '').toString(),
      objective: (json['objective'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      documentUrl: _documentUrl(json['document']),
      isArchived: json['isArchived'] == true,
      createdAt: _formatDate(json['created_at']) ?? '',
    );
  }

  String get documentTitle {
    if (documentUrl.isEmpty) return 'No document attached';

    final uri = Uri.tryParse(documentUrl);
    final segments = uri?.pathSegments;
    if (segments != null && segments.isNotEmpty) {
      final fileName = Uri.decodeComponent(segments.last);
      if (fileName.isNotEmpty) return fileName;
    }

    return 'Lesson document';
  }

  static String _documentUrl(dynamic document) {
    if (document is Map) {
      return (document['url'] ?? '').toString();
    }
    if (document is String) {
      return document;
    }
    return '';
  }

  static String? _formatDate(dynamic iso) {
    if (iso is! String || iso.isEmpty) return null;
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return null;
    }
  }
}
