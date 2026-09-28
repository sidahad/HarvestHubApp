import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../services/trust_safety_service.dart';
import '../../services/auth_service.dart';

// ── colour constants ────────────────────────────────────────────────────────
const _bg = Color(0xFF0D1A13);
const _card = Color(0xFF15281E);
const _primary = Color(0xFF88AB75);
const _textPrimary = Color(0xFFF0F5F1);
const _textSecondary = Color(0xFF8EAA95);
const _border = Color(0xFF1E3427);
const _error = Color(0xFFE76F51);

// ═══════════════════════════════════════════════════════════════════════════
//  TrustSafetyScreen  – main entry point
// ═══════════════════════════════════════════════════════════════════════════

class TrustSafetyScreen extends StatefulWidget {
  const TrustSafetyScreen({super.key});

  @override
  State<TrustSafetyScreen> createState() => _TrustSafetyScreenState();
}

class _TrustSafetyScreenState extends State<TrustSafetyScreen>
    with SingleTickerProviderStateMixin {
  final TrustSafetyService _service = TrustSafetyService();
  final AuthService _auth = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          l10n.trustSafety,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primary,
          labelColor: _primary,
          unselectedLabelColor: _textSecondary,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 12),
          tabs: [
            Tab(text: l10n.safetyScore),
            Tab(text: l10n.blockedUsers),
            Tab(text: l10n.reportHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SafetyProfileTab(
              service: _service, auth: _auth, l10n: l10n),
          _BlockedUsersTab(service: _service, l10n: l10n),
          _ReportHistoryTab(service: _service, l10n: l10n),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tab 1 – Safety Profile & Tips
// ═══════════════════════════════════════════════════════════════════════════

class _SafetyProfileTab extends StatelessWidget {
  final TrustSafetyService service;
  final AuthService auth;
  final AppLocalizations l10n;

  const _SafetyProfileTab(
      {required this.service, required this.auth, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return Center(
          child: Text(l10n.sessionExpired,
              style: GoogleFonts.inter(color: _textSecondary)));
    }

    return StreamBuilder<SafetyProfile?>(
      stream: service.safetyProfileStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _primary));
        }
        final profile = snap.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Score card ──────────────────────────────────────────────
              _ScoreCard(profile: profile, l10n: l10n),
              const SizedBox(height: 20),

              // ── Badges ──────────────────────────────────────────────────
              if (profile != null) ...[
                _BadgesRow(profile: profile, l10n: l10n),
                const SizedBox(height: 20),
              ],

              // ── Safety tips ─────────────────────────────────────────────
              _SectionHeader(l10n.safetyTips),
              const SizedBox(height: 12),
              _SafetyTipsCard(l10n: l10n),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final SafetyProfile? profile;
  final AppLocalizations l10n;
  const _ScoreCard({required this.profile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final score = profile?.safetyScore ?? 20;
    final level = profile?.trustLevel ?? TrustLevel.newUser;
    final levelColor = TrustSafetyService.trustLevelColor(level);
    final levelIconData = TrustSafetyService.trustLevelIconData(level);

    String levelLabel;
    switch (level) {
      case TrustLevel.newUser:
        levelLabel = l10n.newUser;
        break;
      case TrustLevel.regularUser:
        levelLabel = l10n.regularUser;
        break;
      case TrustLevel.trustedUser:
        levelLabel = l10n.trustedUser;
        break;
      case TrustLevel.premiumUser:
        levelLabel = l10n.premiumUser;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(levelIconData, color: levelColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trustLevel,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _textSecondary),
                    ),
                    Text(
                      levelLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Score circle
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor: _border,
                      valueColor: AlwaysStoppedAnimation(levelColor),
                    ),
                    Center(
                      child: Text(
                        '$score',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(levelColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
              Text(
                '$score / 100',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w600),
              ),
              Text('100',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: 16),
            const Divider(color: _border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Transactions',
                  value: '${profile!.totalTransactions}',
                ),
                _StatChip(
                  icon: Icons.flag_outlined,
                  label: 'Reports',
                  value: '${profile!.reportsReceived}',
                  valueColor:
                      profile!.reportsReceived > 0 ? _error : _textSecondary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: _textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? _textPrimary,
          ),
        ),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
      ],
    );
  }
}

class _BadgesRow extends StatelessWidget {
  final SafetyProfile profile;
  final AppLocalizations l10n;
  const _BadgesRow({required this.profile, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (profile.isVerified) {
      badges.add(_Badge(
        icon: Icons.verified_rounded,
        label: l10n.verifiedUser,
        color: const Color(0xFF2196F3),
      ));
    }
    if (profile.isTrustedSeller) {
      badges.add(_Badge(
        icon: Icons.storefront_rounded,
        label: l10n.trustedSeller,
        color: const Color(0xFFFFD700),
      ));
    }
    for (final b in profile.badges) {
      badges.add(_Badge(
        icon: Icons.military_tech_rounded,
        label: b,
        color: _primary,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.safetyBadge),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: badges),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _SafetyTipsCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _SafetyTipsCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final tips = [
      l10n.safetyTip1,
      l10n.safetyTip2,
      l10n.safetyTip3,
      l10n.safetyTip4,
    ];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: List.generate(tips.length, (i) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primary)),
                  ),
                ),
                title: Text(tips[i],
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _textPrimary)),
              ),
              if (i < tips.length - 1)
                const Divider(height: 1, color: _border),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tab 2 – Blocked Users
// ═══════════════════════════════════════════════════════════════════════════

class _BlockedUsersTab extends StatelessWidget {
  final TrustSafetyService service;
  final AppLocalizations l10n;
  const _BlockedUsersTab({required this.service, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: service.blockedUserIdsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _primary));
        }

        final ids = snap.data ?? [];
        if (ids.isEmpty) {
          return _EmptyState(
            icon: Icons.person_off_outlined,
            message: l10n.noBlockedUsers,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BlockedUserTile(
            userId: ids[i],
            service: service,
            l10n: l10n,
          ),
        );
      },
    );
  }
}

class _BlockedUserTile extends StatefulWidget {
  final String userId;
  final TrustSafetyService service;
  final AppLocalizations l10n;
  const _BlockedUserTile(
      {required this.userId, required this.service, required this.l10n});

  @override
  State<_BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<_BlockedUserTile> {
  bool _unblocking = false;

  Future<void> _unblock() async {
    setState(() => _unblocking = true);
    try {
      await widget.service.unblockUser(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.l10n.userUnblocked,
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: _error,
        ));
      }
    } finally {
      if (mounted) setState(() => _unblocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _error.withOpacity(0.15),
            child: const Icon(Icons.person_off_outlined,
                color: _error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ID: ${widget.userId.substring(0, 8)}...',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary),
                ),
                Text(
                  widget.l10n.blockedUsers,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          _unblocking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primary))
              : TextButton(
                  onPressed: _unblock,
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: _primary.withOpacity(0.1),
                  ),
                  child: Text(widget.l10n.unblockUser,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tab 3 – Report History
// ═══════════════════════════════════════════════════════════════════════════

class _ReportHistoryTab extends StatefulWidget {
  final TrustSafetyService service;
  final AppLocalizations l10n;
  const _ReportHistoryTab({required this.service, required this.l10n});

  @override
  State<_ReportHistoryTab> createState() => _ReportHistoryTabState();
}

class _ReportHistoryTabState extends State<_ReportHistoryTab> {
  late Future<List<UserReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = widget.service.getMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserReport>>(
      future: _reportsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _primary));
        }
        final reports = snap.data ?? [];
        if (reports.isEmpty) {
          return _EmptyState(
            icon: Icons.flag_outlined,
            message: widget.l10n.noReportsYet,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _ReportTile(report: reports[i], l10n: widget.l10n),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final UserReport report;
  final AppLocalizations l10n;
  const _ReportTile({required this.report, required this.l10n});

  Color _statusColor(String status) {
    switch (status) {
      case 'reviewed':
        return _primary;
      case 'dismissed':
        return _textSecondary;
      default:
        return const Color(0xFFFFB74D);
    }
  }

  String _reasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return l10n.spam;
      case ReportReason.harassment:
        return l10n.harassment;
      case ReportReason.fakeProfile:
        return l10n.fakeProfile;
      case ReportReason.inappropriateContent:
        return l10n.inappropriateContent;
      case ReportReason.fraud:
        return l10n.fraud;
      case ReportReason.other:
        return l10n.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                style: GoogleFonts.inter(
                    fontSize: 11, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: _error),
              const SizedBox(width: 6),
              Text(
                _reasonLabel(report.reason),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          if (report.description != null &&
              report.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description!,
              style: GoogleFonts.inter(
                  fontSize: 12, color: _textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Report User Bottom Sheet  (callable from anywhere in the app)
// ═══════════════════════════════════════════════════════════════════════════

class ReportUserSheet extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ReportUserSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  /// Convenience method to show the sheet
  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReportUserSheet(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
      ),
    );
  }

  @override
  State<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<ReportUserSheet> {
  final TrustSafetyService _service = TrustSafetyService();
  final TextEditingController _descController = TextEditingController();
  ReportReason? _selectedReason;
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _submitting = true);

    try {
      await _service.reportUser(
        targetUserId: widget.targetUserId,
        reason: _selectedReason!,
        description:
            _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.reportSubmitted,
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: _error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasons = <ReportReason, String>{
      ReportReason.spam: l10n.spam,
      ReportReason.harassment: l10n.harassment,
      ReportReason.fakeProfile: l10n.fakeProfile,
      ReportReason.inappropriateContent: l10n.inappropriateContent,
      ReportReason.fraud: l10n.fraud,
      ReportReason.other: l10n.other,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: _error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.reportUser,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        )),
                    Text(
                      widget.targetUserName,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reason selection
          Text(l10n.reportReason,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reasons.entries.map((entry) {
              final isSelected = _selectedReason == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _error.withOpacity(0.15)
                        : _bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _error.withOpacity(0.6)
                          : _border,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? _error : _textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Description
          Text(l10n.reportDescription,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(color: _textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.reportDescription,
              hintStyle: GoogleFonts.inter(color: _textSecondary),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  (_selectedReason == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _error.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.submit,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Reusable helpers
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(message,
              style:
                  GoogleFonts.poppins(fontSize: 15, color: _textSecondary)),
        ],
      ),
    );
  }
}
