import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/language_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  /// If true, shown as a full page (from profile). If false, used as a dialog.
  final bool isFullPage;

  const LanguageSelectionScreen({super.key, this.isFullPage = true});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final LanguageService _languageService = LanguageService();
  AppLanguage? _selected;
  bool _saving = false;

  // ── theme colours ──────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0D1A13);
  static const Color _card = Color(0xFF15281E);
  static const Color _primary = Color(0xFF88AB75);
  static const Color _textPrimary = Color(0xFFF0F5F1);
  static const Color _textSecondary = Color(0xFF8EAA95);
  static const Color _border = Color(0xFF1E3427);

  @override
  void initState() {
    super.initState();
    _selected = _languageService.currentLanguage;
  }

  Future<void> _applyLanguage() async {
    if (_selected == null || _selected == _languageService.currentLanguage) {
      if (widget.isFullPage) Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    await _languageService.setLanguage(_selected!);
    setState(() => _saving = false);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageChanged,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (widget.isFullPage) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = LanguageService.allLanguages;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header card ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.language_rounded,
                    color: _primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chooseLanguage,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'زبان • भाषा • Language',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          l10n.language,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // ── Language option tiles ─────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: List.generate(options.length, (i) {
              final opt = options[i];
              final isSelected = _selected == opt.language;
              final isLast = i == options.length - 1;

              return Column(
                children: [
                  _LanguageTile(
                    option: opt,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selected = opt.language),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFF1E3427)),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 32),

        // ── Apply button ─────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _applyLanguage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.save,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // ── RTL note ─────────────────────────────────────────────────────
        Center(
          child: Text(
            '* Urdu uses right-to-left layout',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );

    if (!widget.isFullPage) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.language,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: body,
        ),
      ),
    );
  }
}

// ── Individual language tile ───────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final LanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF88AB75);
  static const Color _textPrimary = Color(0xFFF0F5F1);
  static const Color _textSecondary = Color(0xFF8EAA95);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Flag emoji
            Text(option.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),

            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.nativeName,
                    textDirection: option.language == AppLanguage.urdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: option.language == AppLanguage.urdu
                        // NotoNastaliqUrdu renders Urdu script correctly
                        ? GoogleFonts.notoNastaliqUrdu(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? _primary : _textPrimary,
                            height: 1.8, // Nastaliq needs extra line height
                          )
                        : GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? _primary : _textPrimary,
                          ),
                  ),
                  Text(
                    option.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _textSecondary.withOpacity(0.4), width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
