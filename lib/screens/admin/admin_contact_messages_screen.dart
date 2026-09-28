import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class AdminContactMessagesScreen extends StatelessWidget {
  const AdminContactMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Contact Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('contact_messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Could not load messages.',
                style: GoogleFonts.inter(color: AppTheme.error),
              ),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final messages = snapshot.data!.docs;
          if (messages.isEmpty)
            return Center(
              child: Text(
                'No contact messages yet.',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = messages[index].data();
              final createdAt = data['createdAt'] as Timestamp?;
              final dateStr = createdAt != null
                  ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
                  : 'N/A';
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF15281E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['subject'] as String? ?? 'No subject',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFFF0F5F1),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A2B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFA1C68A).withAlpha(50),
                            ),
                          ),
                          child: Text(
                            data['status'] as String? ?? 'New',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA1C68A),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // User Details
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF8FA497)),
                        const SizedBox(width: 6),
                        Text(
                          data['userName'] as String? ?? 'Unknown User',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF0F5F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Color(0xFF8FA497)),
                        const SizedBox(width: 6),
                        Text(
                          data['email'] as String? ?? 'No email',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                      ],
                    ),
                    
                    if ((data['phone'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Color(0xFF8FA497)),
                          const SizedBox(width: 6),
                          Text(
                            data['phone'] as String? ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF8FA497),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8FA497)),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8FA497),
                          ),
                        ),
                      ],
                    ),
                    
                    Divider(height: 20, color: Colors.white.withAlpha(15)),
                    
                    // Message Content
                    Text(
                      data['message'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFF0F5F1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Rating Stars
                    Row(
                      children: [
                        Text(
                          'Rating: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        ...List.generate(5, (i) {
                          final rating = (data['rating'] as int?) ?? 0;
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
