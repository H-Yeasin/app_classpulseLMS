enum CallMediaType { audio, video }

CallMediaType parseCallMediaType(String? value) {
  switch (value) {
    case 'video':
      return CallMediaType.video;
    case 'audio':
    default:
      return CallMediaType.audio;
  }
}

String callMediaTypeValue(CallMediaType type) {
  switch (type) {
    case CallMediaType.video:
      return 'video';
    case CallMediaType.audio:
      return 'audio';
  }
}

class IncomingCall {
  final String roomId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final CallMediaType callType;
  final String? callLogId;

  const IncomingCall({
    required this.roomId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    this.callerAvatar,
    this.callLogId,
  });

  factory IncomingCall.fromJson(Map<String, dynamic> json) {
    final caller = Map<String, dynamic>.from(json['caller'] ?? const {});
    return IncomingCall(
      roomId: (json['roomId'] ?? '').toString(),
      callerId: (caller['id'] ?? '').toString(),
      callerName: (caller['name'] ?? 'Unknown caller').toString(),
      callerAvatar: caller['avatar']?.toString(),
      callType: parseCallMediaType(json['callType']?.toString()),
      callLogId: json['callLogId']?.toString(),
    );
  }
}

class CallAcceptedEvent {
  final String roomId;
  final String answeredById;
  final String answeredByName;
  final String? answeredByAvatar;
  final String? callLogId;

  const CallAcceptedEvent({
    required this.roomId,
    required this.answeredById,
    required this.answeredByName,
    this.answeredByAvatar,
    this.callLogId,
  });

  factory CallAcceptedEvent.fromJson(Map<String, dynamic> json) {
    final answeredBy = Map<String, dynamic>.from(
      json['answeredBy'] ?? const {},
    );
    return CallAcceptedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      answeredById: (answeredBy['id'] ?? '').toString(),
      answeredByName: (answeredBy['name'] ?? 'Unknown user').toString(),
      answeredByAvatar: answeredBy['avatar']?.toString(),
      callLogId: json['callLogId']?.toString(),
    );
  }
}

class CallDeclinedEvent {
  final String roomId;
  final String declinedById;
  final String declinedByName;
  final String? callLogId;
  final String reason;

  const CallDeclinedEvent({
    required this.roomId,
    required this.declinedById,
    required this.declinedByName,
    required this.reason,
    this.callLogId,
  });

  factory CallDeclinedEvent.fromJson(Map<String, dynamic> json) {
    final declinedBy = Map<String, dynamic>.from(
      json['declinedBy'] ?? const {},
    );
    return CallDeclinedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      declinedById: (declinedBy['id'] ?? '').toString(),
      declinedByName: (declinedBy['name'] ?? 'Unknown user').toString(),
      reason: (json['reason'] ?? 'declined').toString(),
      callLogId: json['callLogId']?.toString(),
    );
  }
}

class CallEndedEvent {
  final String roomId;
  final String endedById;
  final String endedByName;
  final String? callLogId;

  const CallEndedEvent({
    required this.roomId,
    required this.endedById,
    required this.endedByName,
    this.callLogId,
  });

  factory CallEndedEvent.fromJson(Map<String, dynamic> json) {
    final endedBy = Map<String, dynamic>.from(json['endedBy'] ?? const {});
    return CallEndedEvent(
      roomId: (json['roomId'] ?? '').toString(),
      endedById: (endedBy['id'] ?? '').toString(),
      endedByName: (endedBy['name'] ?? 'Unknown user').toString(),
      callLogId: json['callLogId']?.toString(),
    );
  }
}

class CallSignalEvent {
  final String socketId;
  final Map<String, dynamic> signal;

  const CallSignalEvent({required this.socketId, required this.signal});
}
