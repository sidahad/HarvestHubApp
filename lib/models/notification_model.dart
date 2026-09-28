import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final String type; // 'order', 'restock', 'promo', 'system'
  bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  String get displayTime {
    if (createdAt == null) return timeAgo;
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt!.day.toString().padLeft(2, '0')}/${createdAt!.month.toString().padLeft(2, '0')}/${createdAt!.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timeAgo': timeAgo,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(
    String id,
    Map<String, dynamic> map, [
    DateTime? date,
  ]) {
    DateTime? created = date;
    if (created == null && map['createdAt'] != null) {
      final raw = map['createdAt'];
      if (raw is Timestamp) {
        created = raw.toDate();
      } else if (raw is int) {
        created = DateTime.fromMillisecondsSinceEpoch(raw);
      } else if (raw is String) {
        created = DateTime.tryParse(raw);
      }
    }
    return NotificationModel(
      id: id,
      title: map['title'] as String? ?? 'Notification',
      message: map['message'] as String? ?? '',
      timeAgo: map['timeAgo'] as String? ?? 'Recently',
      type: map['type'] as String? ?? 'system',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: created,
    );
  }
}

