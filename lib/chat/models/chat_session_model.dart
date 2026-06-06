enum ChatSessionType { direct, group, draft }

enum MessagePreviewType { text, voice, photo }

class ChatSessionModel {
  final String id;
  final ChatSessionType type;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final List<String> participantIds;
  final String? avatarUrl;
  final MessagePreviewType previewType;
  final bool showReadReceipt;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final String? createdBy;
  final bool isBlocked;
  final List<String> blockedBy;
  final List<String> mutedBy;

  const ChatSessionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.participantIds,
    this.avatarUrl,
    this.previewType = MessagePreviewType.text,
    this.showReadReceipt = false,
    this.lastMessageId,
    this.lastMessageAt,
    this.createdBy,
    this.isBlocked = false,
    this.blockedBy = const [],
    this.mutedBy = const [],
  });

  factory ChatSessionModel.fromJson(
    Map<String, dynamic> json, [
    String? currentUserId,
  ]) {
    final type = _parseType(json['type']);
    String title = json['name'] ?? '';
    String? avatar = json['avatar'];

    if (avatar != null && avatar.isEmpty) {
      avatar = null;
    }

    final List rawParticipants = json['participants'] as List? ?? [];
    final List<String> participantIds = rawParticipants
        .map((p) {
          final userData = p['userId'];
          if (userData is Map) {
            return userData['_id']?.toString() ?? '';
          }
          return userData?.toString() ?? '';
        })
        .where((id) => id.isNotEmpty)
        .toList();

    // If it's a direct room and title/avatar are missing, try to find the other participant's info
    if (type == ChatSessionType.direct && (title.isEmpty || avatar == null)) {
      final otherParticipant = rawParticipants.firstWhere((p) {
        final userData = p['userId'];
        final id = userData is Map
            ? userData['_id']?.toString()
            : userData?.toString();
        return id != null && id != currentUserId;
      }, orElse: () => null);

      if (otherParticipant != null && otherParticipant['userId'] is Map) {
        final userData = otherParticipant['userId'] as Map;
        if (title.isEmpty) title = userData['username'] ?? '';
        avatar ??= userData['avatar'] is Map
            ? userData['avatar']['url']
            : userData['avatar'];
      }
    }

    return ChatSessionModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: type,
      title: title,
      subtitle: json['lastMessage'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      participantIds: participantIds,
      avatarUrl: avatar,
      lastMessageId: json['lastMessageId'] is Map
          ? json['lastMessageId']['_id']
          : json['lastMessageId'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      createdBy: json['createdBy'],
      isBlocked: json['isBlocked'] ?? false,
      blockedBy: (json['blockedBy'] as List? ?? [])
          .map((id) => id.toString())
          .toList(),
      mutedBy: (json['mutedBy'] as List? ?? [])
          .map((id) => id.toString())
          .toList(),
    );
  }

  static ChatSessionType _parseType(dynamic type) {
    switch (type?.toString()) {
      case 'direct':
        return ChatSessionType.direct;
      case 'draft':
        return ChatSessionType.draft;
      case 'group':
      default:
        return ChatSessionType.group;
    }
  }

  String get displayDate {
    final month = updatedAt.month.toString().padLeft(2, '0');
    final day = updatedAt.day.toString().padLeft(2, '0');
    final year = (updatedAt.year % 100).toString().padLeft(2, '0');
    return '$month/$day/$year';
  }

  bool get isGroupOrDraft => type != ChatSessionType.direct;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': title,
      'lastMessage': subtitle,
      'updated_at': updatedAt.toIso8601String(),
      'participants': participantIds.map((id) => {'userId': id}).toList(),
      'avatar': avatarUrl,
      'lastMessageId': lastMessageId,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdBy': createdBy,
      'isBlocked': isBlocked,
      'blockedBy': blockedBy,
      'mutedBy': mutedBy,
    };
  }

  ChatSessionModel copyWith({
    String? id,
    ChatSessionType? type,
    String? title,
    String? subtitle,
    DateTime? updatedAt,
    List<String>? participantIds,
    String? avatarUrl,
    MessagePreviewType? previewType,
    bool? showReadReceipt,
    String? lastMessageId,
    DateTime? lastMessageAt,
    String? createdBy,
    bool? isBlocked,
    List<String>? blockedBy,
    List<String>? mutedBy,
  }) {
    return ChatSessionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      updatedAt: updatedAt ?? this.updatedAt,
      participantIds: participantIds ?? this.participantIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      previewType: previewType ?? this.previewType,
      showReadReceipt: showReadReceipt ?? this.showReadReceipt,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdBy: createdBy ?? this.createdBy,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedBy: blockedBy ?? this.blockedBy,
      mutedBy: mutedBy ?? this.mutedBy,
    );
  }
}
