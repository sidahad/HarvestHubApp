import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../services/audio_player_service.dart';
import '../../services/trust_safety_service.dart';
import '../../models/message_model.dart';
import '../../l10n/app_localizations.dart';
import 'trust_safety_screen.dart';
import 'dart:async';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserAvatar;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final TrustSafetyService _trustService = TrustSafetyService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.conversationId);
  }

  // ── Trust & Safety: more options menu ────────────────────────────────────
  void _showMoreOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15281E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Report user ─────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.flag_rounded,
                    color: Color(0xFFE76F51)),
                title: Text(
                  l10n.reportUser,
                  style: GoogleFonts.inter(
                      color: const Color(0xFFF0F5F1)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ReportUserSheet.show(
                    context,
                    targetUserId: widget.otherUserId,
                    targetUserName: widget.otherUserName,
                  );
                },
              ),
              // ── Block user ───────────────────────────────────────────────
              FutureBuilder<bool>(
                future: _trustService.isUserBlocked(widget.otherUserId),
                builder: (_, snap) {
                  final isBlocked = snap.data ?? false;
                  return ListTile(
                    leading: Icon(
                      isBlocked
                          ? Icons.person_add_rounded
                          : Icons.person_off_outlined,
                      color: const Color(0xFFE76F51),
                    ),
                    title: Text(
                      isBlocked ? l10n.unblockUser : l10n.blockUser,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFF0F5F1)),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        if (isBlocked) {
                          await _trustService.unblockUser(widget.otherUserId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(l10n.userUnblocked),
                              backgroundColor: const Color(0xFF88AB75),
                            ));
                          }
                        } else {
                          // Confirm before blocking
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF15281E),
                              title: Text(l10n.blockUser,
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFFF0F5F1))),
                              content: Text(
                                '${l10n.confirmBlock}\n\n${l10n.blockWarning}',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF8EAA95)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(l10n.cancel,
                                      style: GoogleFonts.poppins(
                                          color: const Color(0xFF88AB75))),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: Text(l10n.blockUser,
                                      style: GoogleFonts.poppins(
                                          color: const Color(0xFFE76F51))),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _trustService.blockUser(widget.otherUserId);
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(l10n.userBlocked),
                                backgroundColor: const Color(0xFFE76F51),
                              ));
                              Navigator.of(context).pop(); // close chat
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: const Color(0xFFE76F51),
                          ));
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendTextMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        text: text,
      );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isSending = true);

      // Convert XFile to File and upload to Cloudinary
      final File imageFile = File(image.path);
      final imageUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: 'chat',
      );

      await _chatService.sendImageMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        imageUrl: imageUrl,
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primary),
                title: Text(l10n.chooseFromGallery, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: Text(l10n.takePhoto, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallOptions() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.call, color: AppTheme.primary),
                title: Text(l10n.voiceCall, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _initiateCall(CallType.voice);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: AppTheme.primary),
                title: Text(l10n.videoCall, style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _initiateCall(CallType.video);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initiateCall(CallType callType) async {
    // Show call UI placeholder
    final callTypeStr = callType == CallType.video ? 'Video' : 'Voice';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.otherUserAvatar.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar)
                  : null,
              child: widget.otherUserAvatar.isEmpty
                  ? Icon(
                      callType == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      size: 40,
                      color: AppTheme.primary,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '$callTypeStr calling...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.otherUserName,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.call_end, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Simulate call duration (in real app, this would be actual call)
                    await Future.delayed(const Duration(seconds: 2));
                    await _chatService.recordCall(
                      conversationId: widget.conversationId,
                      receiverId: widget.otherUserId,
                      callType: callType,
                      duration: 0, // In real app, track actual duration
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$callTypeStr call recorded'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      // Stop recording
      _recordingTimer?.cancel();
      
      try {
        setState(() => _isSending = true);
        
        // Stop recording and get file
        final result = await _voiceRecorder.stopRecording();
        
        if (result == null) {
          throw Exception('Failed to save recording');
        }

        final audioFile = File(result['path']);
        final duration = result['duration'] as int;

        // Upload to Firebase Storage
        final audioUrl = await _chatService.uploadAudioFile(audioFile);

        // Send voice message
        await _chatService.sendVoiceMessage(
          conversationId: widget.conversationId,
          receiverId: widget.otherUserId,
          audioUrl: audioUrl,
          duration: duration,
        );

        // Delete temp file
        if (await audioFile.exists()) {
          await audioFile.delete();
        }

        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice message sent'),
              backgroundColor: AppTheme.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRecording = false;
            _isSending = false;
            _recordingDuration = 0;
          });
        }
      }
    } else {
      // Start recording
      try {
        final started = await _voiceRecorder.startRecording();
        
        if (!started) {
          throw Exception('Failed to start recording. Please allow microphone permission.');
        }

        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        // Start timer to update duration
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isRecording) {
            setState(() {
              _recordingDuration = _voiceRecorder.getRecordingDuration();
            });
          }
        });

        // Show recording dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async {
              // Cancel recording on back press
              await _voiceRecorder.cancelRecording();
              _recordingTimer?.cancel();
              if (mounted) {
                setState(() {
                  _isRecording = false;
                  _recordingDuration = 0;
                });
              }
              return true;
            },
            child: AlertDialog(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              content: StatefulBuilder(
                builder: (context, setDialogState) {
                  // Update dialog when duration changes
                  _recordingTimer = Timer.periodic(
                    const Duration(seconds: 1),
                    (timer) {
                      if (mounted && _isRecording) {
                        setDialogState(() {
                          _recordingDuration = _voiceRecorder.getRecordingDuration();
                        });
                      }
                    },
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recording...',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap stop to send',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _voiceRecorder.cancelRecording();
                                _recordingTimer?.cancel();
                                if (mounted) {
                                  setState(() {
                                    _isRecording = false;
                                    _recordingDuration = 0;
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSending
                                  ? null
                                  : () => _toggleVoiceRecording(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.error,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.error,
                                      ),
                                    )
                                  : const Icon(Icons.stop_circle, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isSending ? 'Sending...' : 'Stop & Send',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserAvatar.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar)
                  : null,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: widget.otherUserAvatar.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.activeNow,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Voice/Video Call',
            onPressed: _showCallOptions,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading messages',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      
                      // Show date divider
                      bool showDateDivider = false;
                      if (index == messages.length - 1) {
                        showDateDivider = true;
                      } else {
                        final nextMessage = messages[index + 1];
                        final currentDate = DateTime(
                          message.createdAt.year,
                          message.createdAt.month,
                          message.createdAt.day,
                        );
                        final nextDate = DateTime(
                          nextMessage.createdAt.year,
                          nextMessage.createdAt.month,
                          nextMessage.createdAt.day,
                        );
                        showDateDivider = currentDate != nextDate;
                      }

                      return Column(
                        children: [
                          if (showDateDivider) _buildDateDivider(message.createdAt),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    color: AppTheme.primary,
                    onPressed: _showImageSourceDialog,
                    tooltip: 'Send Image',
                  ),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop_circle : Icons.mic_outlined,
                    ),
                    color: _isRecording ? AppTheme.error : AppTheme.primary,
                    onPressed: _toggleVoiceRecording,
                    tooltip: _isRecording ? 'Stop Recording' : 'Voice Message',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeAMessage,
                        hintStyle:
                            GoogleFonts.inter(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: AppTheme.primary,
                          onPressed: _sendTextMessage,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateStr;
    if (messageDate == today) {
      dateStr = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = timeago.format(date, locale: 'en_short');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.border)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final dir = Directionality.of(context);
    return Padding(
      // Use directional padding so bubble bottom spacing is always below
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        // Use directional mainAxisAlignment: "end" = right in LTR, left in RTL
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar.isNotEmpty
                  ? NetworkImage(message.senderAvatar)
                  : null,
              backgroundColor: AppTheme.primary.withOpacity(0.2),
              child: message.senderAvatar.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isMe
                  ? () => _showMessageOptions(context, message)
                  : null,
              child: Column(
                // crossAxisAlignment.end = trailing edge, flips in RTL
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primary : AppTheme.cardColor,
                      // Directional border radius: tail at bottom-end for
                      // "my" messages, bottom-start for "their" messages.
                      // Resolving against dir makes it flip correctly in RTL.
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: const Radius.circular(16),
                        topEnd: const Radius.circular(16),
                        bottomStart: Radius.circular(isMe ? 16 : 4),
                        bottomEnd: Radius.circular(isMe ? 4 : 16),
                      ).resolve(dir),
                      border: Border.all(
                        color: isMe
                            ? AppTheme.primary
                            : AppTheme.border,
                      ),
                    ),
                    child: _buildMessageContent(message, isMe),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.edited)
                        Padding(
                          // Directional so "edited" label gap flips in RTL
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: Text(
                            'edited',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Text(
                        timeago.format(message.createdAt, locale: 'en_short'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.type == MessageType.text)
                ListTile(
                  leading: const Icon(Icons.edit, color: AppTheme.primary),
                  title: Text(
                    'Edit Message',
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: Text(
                  'Delete Message',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Delete Message?',
          style: GoogleFonts.poppins(),
        ),
        content: Text(
          'This message will be permanently deleted.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _chatService.deleteMessage(
        conversationId: widget.conversationId,
        messageId: message.id,
        senderId: message.senderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _editMessage(MessageModel message) async {
    final TextEditingController editController =
        TextEditingController(text: message.content);

    try {
      final newText = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: Text(
            'Edit Message',
            style: GoogleFonts.poppins(),
          ),
          content: TextField(
            controller: editController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Enter new message...',
              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, editController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (newText == null || newText.isEmpty || newText == message.content) {
        return;
      }

      await _chatService.editMessage(
        conversationId: widget.conversationId,
        messageId: message.id,
        senderId: message.senderId,
        newText: newText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message updated'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      // Always dispose controller
      editController.dispose();
    }
  }

  Widget _buildMessageContent(MessageModel message, bool isMe) {
    final textColor = isMe ? Colors.white : AppTheme.textPrimary;

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: textColor,
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRounded(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.content,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: AppTheme.surface,
                  child: const Icon(Icons.broken_image, size: 64),
                ),
              ),
            ),
          ],
        );

      case MessageType.voice:
        final isCurrentlyPlaying = _audioPlayer.isPlaying &&
            _audioPlayer.currentPlayingUrl == message.content;

        return GestureDetector(
          onTap: () async {
            try {
              if (isCurrentlyPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(message.content);
              }
              setState(() {}); // Refresh to show play/pause icon
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to play audio: ${e.toString()}'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCurrentlyPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: textColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Message',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      _formatDuration(message.duration ?? 0),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      10,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 2,
                        height: isCurrentlyPlaying
                            ? ((index % 3 + 1) * 8.0)
                            : ((index % 2 + 1) * 6.0),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(
                            isCurrentlyPlaying ? 0.8 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );

      case MessageType.call:
        final callIcon = message.callType == CallType.video
            ? Icons.videocam
            : Icons.call;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(callIcon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        );

      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.thumbnailUrl ?? message.content,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 200,
                      color: AppTheme.surface,
                      child: const Icon(Icons.videocam, size: 64),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class ClipRounded extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const ClipRounded({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}
