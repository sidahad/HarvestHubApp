import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  
  // Dynamic contact info from Firestore
  String _supportEmail = 'support@harvesthub.com';
  String _helplinePhone = '+92 42 111-HARVEST';
  String _officeAddress = 'Green Farm Complex, Gulberg III, Lahore';
  bool _isLoadingContactInfo = true;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('contact_info')
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _supportEmail = data['email'] as String? ?? _supportEmail;
          _helplinePhone = data['phone'] as String? ?? _helplinePhone;
          _officeAddress = data['address'] as String? ?? _officeAddress;
          _isLoadingContactInfo = false;
        });
      } else {
        setState(() => _isLoadingContactInfo = false);
      }
    } catch (e) {
      setState(() => _isLoadingContactInfo = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a message before sending')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before sending feedback.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Fetch user profile for more details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      final userName = userData?['fullName'] ?? user.displayName ?? 'User';
      final userPhone = userData?['phone'] ?? '';

      await FirebaseFirestore.instance.collection('contact_messages').add({
        'userId': user.uid,
        'userName': userName,
        'email': user.email ?? '',
        'phone': userPhone,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'rating': _selectedRating,
        'status': 'New',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final subjectText = _subjectController.text.trim();
      DataService().addNotification(
        title: 'Support Inquiry Sent',
        message: 'Your inquiry "$subjectText" has been received. Our team will review it shortly.',
        type: 'system',
      );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      setState(() => _selectedRating = 5);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your message has been sent to support.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send message: $error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Contact & Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get in Touch with Us',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Have a question about farm produce or your order? We are here 24/7.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Contact Info Cards (Dynamic)
              _isLoadingContactInfo
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildContactTile(
                          Icons.email_outlined,
                          'Support Email',
                          _supportEmail,
                        ),
                        _buildContactTile(
                          Icons.phone_outlined,
                          'Helpline Hotline',
                          _helplinePhone,
                        ),
                        _buildContactTile(
                          Icons.location_on_outlined,
                          'Main Farm HQ',
                          _officeAddress,
                        ),
                      ],
                    ),
              const SizedBox(height: 28),

              // Feedback Form Header
              Text(
                'Send Us Direct Feedback',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Rating Selection Stars
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      starIndex <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setState(() => _selectedRating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Subject Input
              Text(
                'Subject',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Order Delivery Query',
                ),
              ),
              const SizedBox(height: 16),

              // Message Input
              Text(
                'Your Message',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type your detailed feedback or question here...',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E3A2B),
            child: Icon(icon, color: const Color(0xFFA1C68A), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF8FA497),
                  ),
                ),
                Text(
                  val,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
