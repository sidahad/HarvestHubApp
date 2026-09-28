import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/data_service.dart';
import '../../l10n/app_localizations.dart';

class HarvestAIScreen extends StatefulWidget {
  const HarvestAIScreen({super.key});

  @override
  State<HarvestAIScreen> createState() => _HarvestAIScreenState();
}

class _HarvestAIScreenState extends State<HarvestAIScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    "Kitne farmers aur products hain?",
    "Sabse cheap rates kiske hain?",
    "Apple aur Organic Milk ke kya fayde hain?",
    "Pickup slot kaise book karein?",
  ];

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _dataService.sendAIMessage(text.trim());
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _dataService.aiMessages;
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1A13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFFF0F5F1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF15281E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF88AB75).withAlpha(60)),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF88AB75),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.harvestAI,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF0F5F1),
                  ),
                ),
                Text(
                  l10n.harvestAISubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF8EAA95),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // Use directional alignment so bubbles flip correctly in RTL:
                  // user messages → end (right in LTR, left in RTL)
                  // AI messages  → start (left in LTR, right in RTL)
                  return Align(
                    alignment: msg.isUser
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFF88AB75) : const Color(0xFF15281E),
                        // Tail corner: user bubble tail at bottom-end, AI bubble tail at bottom-start
                        borderRadius: BorderRadiusDirectional.only(
                          topStart: const Radius.circular(20),
                          topEnd: const Radius.circular(20),
                          bottomStart: Radius.circular(msg.isUser ? 20 : 4),
                          bottomEnd: Radius.circular(msg.isUser ? 4 : 20),
                        ).resolve(Directionality.of(context)),
                        border: msg.isUser ? null : Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: msg.isUser ? const Color(0xFF0D1A13) : const Color(0xFFF0F5F1),
                          fontWeight: msg.isUser ? FontWeight.w500 : FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Suggestion Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    // Use directional padding so chips have correct spacing in RTL
                    padding: EdgeInsetsDirectional.only(end: 8.0),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF15281E),
                      side: BorderSide(color: Colors.white.withAlpha(20)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      label: Text(
                        prompt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFA1C68A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF102117),
                border: Border(top: BorderSide(color: Colors.white.withAlpha(20), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF172C20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: TextField(
                        controller: _inputController,
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        style: GoogleFonts.inter(color: const Color(0xFFF0F5F1), fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l10n.harvestAIHint,
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF6B8A74), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF88AB75),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF0D1A13),
                        size: 18,
                      ),
                      onPressed: () => _sendMessage(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
