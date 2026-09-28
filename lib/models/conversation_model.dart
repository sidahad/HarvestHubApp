import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, farmer, admin }

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantAvatars;
  final Map<String, UserRole> participantRoles;
  final String lastMessage;
  final String lastMessageType; // 'text', 'image', 'voice', 'video'
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    required this.participantRoles,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'participantRoles': participantRoles.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ConversationModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ConversationModel.fromMap(doc.id, data);
  }

  factory ConversationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Conversation document does not exist');
    }
    return ConversationModel.fromMap(doc.id, data);
  }

  factory ConversationModel.fromMap(String id, Map<String, dynamic> data) {
    final participantRolesRaw = data['participantRoles'] as Map? ?? {};
    final participantRoles = <String, UserRole>{};
    participantRolesRaw.forEach((key, value) {
      final roleStr = value.toString().toLowerCase();
      if (roleStr == 'customer') {
        participantRoles[key.toString()] = UserRole.customer;
      } else if (roleStr == 'farmer') {
        participantRoles[key.toString()] = UserRole.farmer;
      } else if (roleStr == 'admin') {
        participantRoles[key.toString()] = UserRole.admin;
      }
    });

    return ConversationModel(
      id: id,
      participantIds:
          List<String>.from(data['participantIds'] as List? ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] as Map? ?? {},
      ),
      participantAvatars: Map<String, String>.from(
        data['participantAvatars'] as Map? ?? {},
      ),
      participantRoles: participantRoles,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageType: data['lastMessageType'] as String? ?? 'text',
      lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map? ?? {}),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String getOtherParticipantName(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) {
        return participantNames[id] ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  String getOtherParticipantAvatar(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) {
        return participantAvatars[id] ?? '';
      }
    }
    return '';
  }

  String getOtherParticipantId(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) {
        return id;
      }
    }
    return '';
  }

  UserRole? getOtherParticipantRole(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) {
        return participantRoles[id];
      }
    }
    return null;
  }
}
