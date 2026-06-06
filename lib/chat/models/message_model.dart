

enum MessageDeliveryStatus { sending, sent, delivered, read, failed }

class MessageAttachment {
  final String filename;
  final String url;
  final String? publicId;
  final DateTime? uploadedAt;

  const MessageAttachment({
    required this.filename,
    required this.url,
    this.publicId,
    this.uploadedAt,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      publicId: json['public_id'],
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.tryParse(json['uploadedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'public_id': publicId,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}

class MessageModel {
  final String id;
  final String chatSessionId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<MessageAttachment> attachments;
  final MessageDeliveryStatus deliveryStatus;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.chatSessionId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.attachments = const [],
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedAt,
    this.readBy = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      chatSessionId: json['roomId'] ?? '',
      senderId: json['userId'] ?? '',
      text: json['message'] ?? '',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      attachments: (json['file'] as List? ?? [])
          .map((item) => MessageAttachment.fromJson(item))
          .toList(),
      deliveryStatus: _parseStatus(json['status']),
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null 
          ? DateTime.tryParse(json['deletedAt'].toString()) 
          : null,
      readBy: (json['readBy'] as List? ?? [])
          .map((id) => id.toString())
          .toList(),
    );
  }

  static MessageDeliveryStatus _parseStatus(dynamic status) {
    switch (status?.toString()) {
      case 'read':
        return MessageDeliveryStatus.read;
      case 'delivered':
        return MessageDeliveryStatus.delivered;
      case 'sent':
      default:
        return MessageDeliveryStatus.sent;
    }
  }

  MessageModel copyWith({
    String? id,
    String? chatSessionId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    List<MessageAttachment>? attachments,
    MessageDeliveryStatus? deliveryStatus,
    bool? isEdited,
    bool? isDeleted,
    DateTime? deletedAt,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatSessionId: chatSessionId ?? this.chatSessionId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': chatSessionId,
      'userId': senderId,
      'message': text,
      'file': attachments.map((a) => a.toJson()).toList(),
      'status': deliveryStatus.name,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'readBy': readBy,
    };
  }
}
