import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';

enum LeaderboardTab { customer, farmer }

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardTab initialTab;
  const LeaderboardScreen(
      {super.key, this.initialTab = LeaderboardTab.customer});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GamificationService _gs = GamificationService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  List<LeaderboardEntry> _customerEntries = [];
  List<LeaderboardEntry> _farmerEntries = [];
  bool _loadingCustomer = true;
  bool _loadingFarmer = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load both in parallel
    await Future.wait([
      _gs
          .getCustomerLeaderboard(currentUserId: _uid)
          .then((v) => setState(() {
                _customerEntries = v;
                _loadingCustomer = false;
              })),
      _gs
          .getFarmerLeaderboard(currentFarmerId: _uid)
          .then((v) => setState(() {
                _farmerEntries = v;
                _loadingFarmer = false;
              })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Monthly Leaderboard',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primary),
            onPressed: () {
              setState(() {
                _loadingCustomer = true;
                _loadingFarmer = true;
              });
              _loadData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 14),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Customers'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Farmers'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerTab(),
          _buildFarmerTab(),
        ],
      ),
    );
  }

  // ── Customer Tab ──────────────────────────────────────────────────────────

  Widget _buildCustomerTab() {
    if (_loadingCustomer) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_customerEntries.isEmpty) {
      return _EmptyLeaderboard(
          message: 'No customer data yet.\nComplete orders to earn points!');
    }
    return _LeaderboardList(
      entries: _customerEntries,
      topTitle: 'Buyer of the Month',
      topSubtitle: 'Top customer by monthly points',
      badgeColorOf: (e) {
        final badge = GamificationService.customerBadgeFromKey(
            _badgeLabelToKey(e.badgeLabel, isCustomer: true));
        return GamificationService.customerBadgeColor(badge);
      },
    );
  }

  // ── Farmer Tab ────────────────────────────────────────────────────────────

  Widget _buildFarmerTab() {
    if (_loadingFarmer) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_farmerEntries.isEmpty) {
      return _EmptyLeaderboard(
          message:
              'No farmer data yet.\nComplete orders to earn points!');
    }
    return _LeaderboardList(
      entries: _farmerEntries,
      topTitle: 'Farmer of the Month',
      topSubtitle: 'Top farmer by monthly points',
      badgeColorOf: (e) {
        final badge = GamificationService.farmerBadgeFromKey(
            _badgeLabelToKey(e.badgeLabel, isCustomer: false));
        return GamificationService.farmerBadgeColor(badge);
      },
    );
  }

  // ── Helper: convert display label back to key ─────────────────────────────

  static String _badgeLabelToKey(String label,
      {required bool isCustomer}) {
    if (isCustomer) {
      switch (label) {
        case 'Regular Buyer':
          return 'regularBuyer';
        case 'Loyal Customer':
          return 'loyalCustomer';
        case 'VIP Customer':
          return 'vipCustomer';
        default:
          return 'newBuyer';
      }
    } else {
      switch (label) {
        case 'Active Farmer':
          return 'activeFarmer';
        case 'Trusted Farmer':
          return 'trustedFarmer';
        case 'Quality Farmer':
          return 'qualityFarmer';
        case 'Top Farmer':
          return 'topFarmer';
        case 'Farmer of the Month':
          return 'farmerOfTheMonth';
        default:
          return 'newFarmer';
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LEADERBOARD LIST  (shared by both tabs)
// ═══════════════════════════════════════════════════════════════════════════

class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String topTitle;
  final String topSubtitle;
  final Color Function(LeaderboardEntry) badgeColorOf;

  const _LeaderboardList({
    required this.entries,
    required this.topTitle,
    required this.topSubtitle,
    required this.badgeColorOf,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Top 3 Podium ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _Podium(
              entries: entries.take(3).toList(),
              topTitle: topTitle,
              topSubtitle: topSubtitle,
              badgeColorOf: badgeColorOf,
            ),
          ),
        ),
        // ── 4th and below ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList.builder(
            itemCount: entries.length > 3 ? entries.length - 3 : 0,
            itemBuilder: (_, i) {
              final entry = entries[i + 3];
              return _LeaderboardTile(
                entry: entry,
                badgeColor: badgeColorOf(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TOP 3 PODIUM
// ═══════════════════════════════════════════════════════════════════════════

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String topTitle;
  final String topSubtitle;
  final Color Function(LeaderboardEntry) badgeColorOf;

  const _Podium({
    required this.entries,
    required this.topTitle,
    required this.topSubtitle,
    required this.badgeColorOf,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withOpacity(0.15),
            AppTheme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Text(topTitle,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning)),
          Text(topSubtitle,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          // Podium row: 2nd | 1st | 3rd
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (second != null)
                _PodiumSlot(
                  entry: second,
                  rank: 2,
                  height: 90,
                  medalColor: const Color(0xFFC0C0C0),
                  badgeColor: badgeColorOf(second),
                ),
              const SizedBox(width: 12),
              _PodiumSlot(
                entry: first,
                rank: 1,
                height: 120,
                medalColor: const Color(0xFFFFD700),
                badgeColor: badgeColorOf(first),
                isFirst: true,
              ),
              const SizedBox(width: 12),
              if (third != null)
                _PodiumSlot(
                  entry: third,
                  rank: 3,
                  height: 70,
                  medalColor: const Color(0xFFCD7F32),
                  badgeColor: badgeColorOf(third),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color medalColor;
  final Color badgeColor;
  final bool isFirst;

  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.height,
    required this.medalColor,
    required this.badgeColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if (isFirst)
            const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
          const SizedBox(height: 4),
          // Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      entry.isCurrentUser ? AppTheme.primary : badgeColor,
                  width: isFirst ? 3 : 2),
            ),
            child: CircleAvatar(
              radius: isFirst ? 30 : 22,
              backgroundColor: badgeColor.withOpacity(0.2),
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.name.isNotEmpty
                          ? entry.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                          fontSize: isFirst ? 22 : 16,
                          fontWeight: FontWeight.bold,
                          color: badgeColor),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.name.split(' ').first,
            style: GoogleFonts.poppins(
                fontSize: isFirst ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: entry.isCurrentUser
                    ? AppTheme.primary
                    : AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${entry.points} pts',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          // Podium block
          Container(
            height: height,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(
                  color: badgeColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.military_tech_rounded,
                      color: medalColor, size: isFirst ? 28 : 22),
                  Text('#$rank',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: badgeColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  RANK 4+ TILE
// ═══════════════════════════════════════════════════════════════════════════

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color badgeColor;

  const _LeaderboardTile(
      {required this.entry, required this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppTheme.primary.withOpacity(0.08)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: entry.isCurrentUser
                ? AppTheme.primary.withOpacity(0.4)
                : AppTheme.border),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: badgeColor.withOpacity(0.2),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.name.isNotEmpty
                        ? entry.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: badgeColor),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name & badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? '${entry.name} (You)' : entry.name,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: entry.isCurrentUser
                          ? AppTheme.primary
                          : AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 13, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(entry.badgeLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: badgeColor),
              ),
              Text('pts',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyLeaderboard extends StatelessWidget {
  final String message;
  const _EmptyLeaderboard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppTheme.warning, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 15, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
