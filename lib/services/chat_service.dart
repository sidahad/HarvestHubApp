import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import 'auth_service.dart';
import 'cloudinary_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Generate conversation ID from two user IDs
  String generateConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Create or get existing conversation
  Future<String> createConversation({
    required String otherUserId,
    required String otherUserName,
    required String otherUserAvatar,
    required UserRole otherUserRole,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final currentUserId = currentUser.uid;
    final currentUserName = _authService.userModel?.fullName ?? 'User';
    final currentUserAvatar = _authService.userModel?.profilePic ?? '';
    final currentUserRole = _authService.userModel?.role == 'farmer'
        ? UserRole.farmer
        : (_authService.userModel?.role == 'admin'
              ? UserRole.admin
              : UserRole.customer);

    final conversationId = generateConversationId(currentUserId, otherUserId);

    // Check if conversation exists
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      // Create new conversation
      await _firestore.collection('conversations').doc(conversationId).set({
        'participantIds': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'participantAvatars': {
          currentUserId: currentUserAvatar,
          otherUserId: otherUserAvatar,
        },
        'participantRoles': {
          currentUserId: currentUserRole.toString().split('.').last,
          otherUserId: otherUserRole.toString().split('.').last,
        },
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final messageRef = _firestore
        .collection('conversations/$conversationId/messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: currentUser.uid,
      senderName: _authService.userModel?.fullName ?? 'User',
      senderAvatar: _authService.userModel?.profilePic ?? '',
      type: MessageType.text,
      content: text,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update conversation
    await _updateConversation(
      conversationId: conversationId,
      lastMessage: text,
      lastMessageType: 'text',
      senderId: currentUser.uid,
      receiverId: receiverId,
    );
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String conversationId,
    required String receiverId,
    required String imageUrl,
    String? thumbnailUrl,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final messageRef = _firestore
        .collection('conversations/$conversationId/messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: currentUser.uid,
      senderName: _authService.userModel?.fullName ?? 'User',
      senderAvatar: _authService.userModel?.profilePic ?? '',
      type: MessageType.image,
      content: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update conversation
    await _updateConversation(
      conversationId: conversationId,
      lastMessage: 'Image',
      lastMessageType: 'image',
      senderId: currentUser.uid,
      receiverId: receiverId,
    );
  }

  // Upload audio file to Cloudinary using /raw/upload endpoint
  Future<String> uploadAudioFile(File audioFile) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Use /raw/upload endpoint — supports AAC, MP3, M4A etc.
      final audioUrl = await CloudinaryService.uploadAudio(
        audioFile,
        folder: 'voice_messages',
      );

      return audioUrl;
    } catch (e) {
      print('Error uploading audio: $e');
      throw Exception('Failed to upload audio: ${e.toString()}');
    }
  }

  // Send a voice message
  Future<void> sendVoiceMessage({
    required String conversationId,
    required String receiverId,
    required String audioUrl,
    required int duration,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final messageRef = _firestore
        .collection('conversations/$conversationId/messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: currentUser.uid,
      senderName: _authService.userModel?.fullName ?? 'User',
      senderAvatar: _authService.userModel?.profilePic ?? '',
      type: MessageType.voice,
      content: audioUrl,
      duration: duration,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update conversation
    await _updateConversation(
      conversationId: conversationId,
      lastMessage: 'Voice message',
      lastMessageType: 'voice',
      senderId: currentUser.uid,
      receiverId: receiverId,
    );
  }

  // Record call in conversation
  Future<void> recordCall({
    required String conversationId,
    required String receiverId,
    required CallType callType,
    required int duration,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    final messageRef = _firestore
        .collection('conversations/$conversationId/messages')
        .doc();

    final callTypeStr = callType == CallType.video ? 'Video' : 'Voice';
    final message = MessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: currentUser.uid,
      senderName: _authService.userModel?.fullName ?? 'User',
      senderAvatar: _authService.userModel?.profilePic ?? '',
      type: MessageType.call,
      content: '$callTypeStr call',
      callType: callType,
      callDuration: duration,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    await messageRef.set(message.toMap());

    // Update conversation
    await _updateConversation(
      conversationId: conversationId,
      lastMessage: '$callTypeStr call',
      lastMessageType: 'call',
      senderId: currentUser.uid,
      receiverId: receiverId,
    );
  }

  // Update conversation after sending message
  Future<void> _updateConversation({
    required String conversationId,
    required String lastMessage,
    required String lastMessageType,
    required String senderId,
    required String receiverId,
  }) async {
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    final currentUnreadCount =
        (await conversationRef.get()).data()?['unreadCount'] as Map? ?? {};

    await conversationRef.update({
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageSenderId': senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount.$receiverId': (currentUnreadCount[receiverId] ?? 0) + 1,
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);

    await conversationRef.update({'unreadCount.${currentUser.uid}': 0});

    // Update all unread messages to read
    final unreadMessages = await _firestore
        .collection('conversations/$conversationId/messages')
        .where('senderId', isNotEqualTo: currentUser.uid)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Get conversations stream
  Stream<List<ConversationModel>> getConversationsStream() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUser.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading conversations: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              return ConversationModel.fromDoc(doc);
            }).toList();
          } catch (e) {
            debugPrint('Error parsing conversations: $e');
            return <ConversationModel>[];
          }
        });
  }

  // Get messages stream for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations/$conversationId/messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromDoc(doc);
          }).toList();
        });
  }

  // Get all conversations for admin monitoring
  Stream<List<ConversationModel>> getAllConversationsForAdmin() {
    return _firestore
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading admin conversations: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              return ConversationModel.fromDoc(doc);
            }).toList();
          } catch (e) {
            debugPrint('Error parsing admin conversations: $e');
            return <ConversationModel>[];
          }
        });
  }

  // Delete conversation (soft delete by hiding from user)
  Future<void> deleteConversation(String conversationId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('conversations').doc(conversationId).update({
      'deletedBy.${currentUser.uid}': true,
    });
  }

  // Delete a specific message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String senderId,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Only allow deleting own messages
    if (currentUser.uid != senderId) {
      throw Exception('You can only delete your own messages');
    }

    await _firestore
        .collection('conversations/$conversationId/messages')
        .doc(messageId)
        .delete();
  }

  // Edit a text message
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String senderId,
    required String newText,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // Only allow editing own messages
    if (currentUser.uid != senderId) {
      throw Exception('You can only edit your own messages');
    }

    await _firestore
        .collection('conversations/$conversationId/messages')
        .doc(messageId)
        .update({
          'content': newText,
          'edited': true,
          'editedAt': FieldValue.serverTimestamp(),
        });

    // Update conversation if it's the last message
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (conversationDoc.exists) {
      final data = conversationDoc.data();
      if (data?['lastMessageSenderId'] == currentUser.uid) {
        await _firestore.collection('conversations').doc(conversationId).update(
          {'lastMessage': newText, 'updatedAt': FieldValue.serverTimestamp()},
        );
      }
    }
  }
}
