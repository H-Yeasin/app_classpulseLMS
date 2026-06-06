class Homework {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final bool isArchived;

  const Homework({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isArchived = false,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      dueDate: _formatDate(json['dueDate']) ??
          _formatDate(json['created_at']) ??
          '',
      isArchived: json['archived'] == true,
    );
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

class GroupHomework {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final bool isArchived;
  final List<GroupMember> members;

  const GroupHomework({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isArchived,
    required this.members,
  });

  factory GroupHomework.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['userId'] as List?;
    final members = rawMembers
            ?.whereType<Map>()
            .map((m) => GroupMember.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        <GroupMember>[];

    return GroupHomework(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      dueDate: Homework._formatDate(json['dueDate']) ??
          Homework._formatDate(json['created_at']) ??
          '',
      isArchived: json['archived'] == true,
      members: members,
    );
  }
}

class GroupMember {
  final String name;
  final String avatarUrl;

  const GroupMember({
    required this.name,
    required this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    String url = '';
    if (avatar is Map) {
      url = (avatar['url']?.toString() ?? '');
    } else if (avatar is String) {
      url = avatar;
    }
    return GroupMember(
      name: (json['username'] ?? json['name'] ?? '').toString(),
      avatarUrl: url,
    );
  }
}

const List<GroupMember> mockGroupMembers = [
  GroupMember(
    name: "Mia johnson",
    avatarUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
  GroupMember(
    name: "Mia johnson",
    avatarUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
  GroupMember(
    name: "Mia johnson",
    avatarUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
  GroupMember(
    name: "Mia johnson",
    avatarUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&w=150&q=80",
  ),
];

const List<Homework> mockClassHomework = [
  Homework(
    id: "h1",
    title: "Fractions Practice",
    description: "Solve question 1-10 on page 42 of the textbook.",
    dueDate: "June 13, 2025",
  ),
];

const List<Homework> mockArchivedHomework = [
  Homework(
    id: "h2",
    title: "Fractions Practice",
    description: "Solve question 1-10 on page 42 of the textbook.",
    dueDate: "June 13, 2025",
    isArchived: true,
  ),
  Homework(
    id: "h3",
    title: "Fractions Practice",
    description: "Solve question 1-10 on page 42 of the textbook.",
    dueDate: "June 13, 2025",
    isArchived: true,
  ),
  Homework(
    id: "h4",
    title: "Fractions Practice",
    description: "Solve question 1-10 on page 42 of the textbook.",
    dueDate: "June 13, 2025",
    isArchived: true,
  ),
  Homework(
    id: "h5",
    title: "Fractions Practice",
    description: "Solve question 1-10 on page 42 of the textbook.",
    dueDate: "June 13, 2025",
    isArchived: true,
  ),
];
