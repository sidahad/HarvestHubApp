import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class FarmerNotificationsScreen extends StatelessWidget {
  const FarmerNotificationsScreen({super.key});

  // ── Firestore stream: this farmer's notifications ──────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> _notifStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .set({'isRead': true, 'read': true}, SetOptions(merge: true));
  }

  Future<void> _markAllRead(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      final isRead = doc.data()['isRead'] == true || doc.data()['read'] == true;
      if (!isRead) {
        batch.set(doc.reference, {'isRead': true, 'read': true}, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  Future<void> _deleteNotif(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  // ── Icon/colour per type ──────────────────────────────────────────
  ({IconData icon, Color color}) _typeStyle(String type) {
    switch (type) {
      case 'low_stock':
        return (icon: Icons.warning_amber_rounded, color: Colors.orange);
      case 'new_order':
        return (icon: Icons.shopping_bag_rounded, color: Colors.blue);
      case 'order_status':
      case 'order_update':
        return (icon: Icons.local_shipping_rounded, color: Colors.purple);
      default:
        return (icon: Icons.notifications_rounded, color: AppTheme.primary);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notifStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[FarmerNotifications] Error in stream: ${snapshot.error}');
        }

        final rawDocs = snapshot.data?.docs ?? [];
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(rawDocs);
        
        // In-memory sort by createdAt descending (no Firestore composite index required)
        docs.sort((a, b) {
          final aTs = a.data()['createdAt'];
          final bTs = b.data()['createdAt'];
          if (aTs is Timestamp && bTs is Timestamp) {
            return bTs.compareTo(aTs);
          }
          if (aTs is Timestamp) return -1;
          if (bTs is Timestamp) return 1;
          return 0;
        });

        final unread = docs.where((d) {
          final isRead = d.data()['isRead'] == true || d.data()['read'] == true;
          return !isRead;
        }).length;
        
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            automaticallyImplyLeading: false, // Remove back button
            title: Row(
              children: [
                Text('Alerts',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread new',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: () => _markAllRead(docs),
                  child: Text(
                    'Mark All Read',
                    style: GoogleFonts.poppins(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            bottom: true,
            child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary))
              : docs.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildCard(context, docs[index]),
                    ),
          ),
        );
      },
    );
  }

  // ── Empty state ───────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text('No Alerts Yet',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'New orders, low stock warnings\nand updates will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Notification Card ─────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final isRead = data['isRead'] == true || data['read'] == true;
    final type = data['type'] as String? ?? 'system';
    final title = data['title'] as String? ?? 'Alert';
    final body = data['body'] as String? ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final style = _typeStyle(type);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.error, size: 26),
      ),
      onDismissed: (_) => _deleteNotif(doc.id),
      child: GestureDetector(
        onTap: () {
          if (!isRead) _markRead(doc.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppTheme.cardColor : style.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? AppTheme.border
                  : style.color.withValues(alpha: 0.35),
              width: isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type Icon ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 12,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: style.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel(type),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: style.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'low_stock':
        return 'Low Stock';
      case 'new_order':
        return 'New Order';
      case 'order_status':
        return 'Order Update';
      default:
        return 'Alert';
    }
  }
}
