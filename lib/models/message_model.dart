import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  voice,
  video,
  call,
}

enum CallType {
  voice,
  video,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final MessageType type;
  final String content; // text content or URL for media
  final String? thumbnailUrl; // for images/videos
  final int? duration; // for voice/video in seconds
  final CallType? callType;
  final int? callDuration;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool edited;
  final DateTime? editedAt;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.content,
    this.thumbnailUrl,
    this.duration,
    this.callType,
    this.callDuration,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.edited = false,
    this.editedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.toString().split('.').last,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'callType': callType?.toString().split('.').last,
      'callDuration': callDuration,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'edited': edited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MessageModel.fromMap(doc.id, data);
  }

  factory MessageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Message document does not exist');
    }
    return MessageModel.fromMap(doc.id, data);
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    // Parse MessageType
    MessageType parseMessageType(String? typeStr) {
      switch (typeStr?.toLowerCase()) {
        case 'image':
          return MessageType.image;
        case 'voice':
          return MessageType.voice;
        case 'video':
          return MessageType.video;
        case 'call':
          return MessageType.call;
        default:
          return MessageType.text;
      }
    }

    // Parse CallType
    CallType? parseCallType(String? typeStr) {
      if (typeStr == null) return null;
      switch (typeStr.toLowerCase()) {
        case 'video':
          return CallType.video;
        case 'voice':
          return CallType.voice;
        default:
          return null;
      }
    }

    // Parse MessageStatus
    MessageStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'sent':
          return MessageStatus.sent;
        case 'delivered':
          return MessageStatus.delivered;
        case 'read':
          return MessageStatus.read;
        case 'failed':
          return MessageStatus.failed;
        default:
          return MessageStatus.sending;
      }
    }

    return MessageModel(
      id: id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Unknown',
      senderAvatar: data['senderAvatar'] as String? ?? '',
      type: parseMessageType(data['type'] as String?),
      content: data['content'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      duration: data['duration'] as int?,
      callType: parseCallType(data['callType'] as String?),
      callDuration: data['callDuration'] as int?,
      status: parseStatus(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      edited: data['edited'] as bool? ?? false,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    String? thumbnailUrl,
    int? duration,
    CallType? callType,
    int? callDuration,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    bool? edited,
    DateTime? editedAt,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      callType: callType ?? this.callType,
      callDuration: callDuration ?? this.callDuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  String getDisplayContent() {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return 'Image';
      case MessageType.voice:
        return 'Voice message';
      case MessageType.video:
        return 'Video';
      case MessageType.call:
        final callTypeStr = callType == CallType.video ? 'Video' : 'Voice';
        return '$callTypeStr call';
    }
  }
}
