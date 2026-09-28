import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../gamification/leaderboard_screen.dart';

class FarmerRewardsScreen extends StatelessWidget {
  const FarmerRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmerId = FirebaseAuth.instance.currentUser?.uid;

    if (farmerId == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('Please log in.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ),
      );
    }

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
        title: Text('Farmer Rewards',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded,
                color: AppTheme.primary),
            tooltip: 'Farmer Leaderboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen(
                        initialTab: LeaderboardTab.farmer,
                      )),
            ),
          ),
        ],
      ),
      body: StreamBuilder<FarmerGamificationProfile>(
        stream: GamificationService().farmerProfileStream(farmerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final profile =
              snap.data ?? FarmerGamificationProfile.empty(farmerId);
          return _buildBody(context, profile);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FarmerGamificationProfile p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FarmerHeroCard(profile: p),
          const SizedBox(height: 20),
          _FarmerTierCard(profile: p),
          const SizedBox(height: 20),
          _PerformanceBreakdownCard(profile: p),
          const SizedBox(height: 20),
          _FarmerEarningRulesCard(),
          const SizedBox(height: 20),
          _FarmerLeaderboardBanner(onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const LeaderboardScreen(
                      initialTab: LeaderboardTab.farmer,
                    )),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HERO CARD
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerHeroCard extends StatelessWidget {
  final FarmerGamificationProfile profile;
  const _FarmerHeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final badgeColor = GamificationService.farmerBadgeColor(profile.badge);
    final badgeIcon = GamificationService.farmerBadgeIcon(profile.badge);
    final badgeLabel = GamificationService.farmerBadgeLabel(profile.badge);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withOpacity(0.22),
            AppTheme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, color: badgeColor, size: 16),
                const SizedBox(width: 6),
                Text(badgeLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: badgeColor)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Points',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${profile.totalPoints}',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 6),
                      Text('pts',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _FarmerStatBubble(
                label: 'This Month',
                value: '${profile.monthlyPoints}',
                icon: Icons.trending_up_rounded,
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              _FarmerStatBubble(
                label: 'Orders',
                value: '${profile.completedOrders}',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.primary,
                small: true,
              ),
              const SizedBox(width: 8),
              _FarmerStatBubble(
                label: 'On-Time',
                value: '${profile.onTimeDeliveries}',
                icon: Icons.timer_rounded,
                color: AppTheme.info,
                small: true,
              ),
              const SizedBox(width: 8),
              _FarmerStatBubble(
                label: '5-Star Reviews',
                value: '${profile.fiveStarRatings}',
                icon: Icons.star_rounded,
                color: AppTheme.warning,
                small: true,
              ),
              const SizedBox(width: 8),
              _FarmerStatBubble(
                label: 'Rating',
                value: profile.avgRating > 0
                    ? profile.avgRating.toStringAsFixed(1)
                    : 'N/A',
                icon: Icons.grade_rounded,
                color: AppTheme.secondary,
                small: true,
              ),
            ],
          ),
          if (profile.isMonthlyTop) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.warning.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium,
                      color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Text('Farmer of the Month!',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warning)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TIER PROGRESS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerTierCard extends StatelessWidget {
  final FarmerGamificationProfile profile;
  const _FarmerTierCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isMax = profile.badge == FarmerBadge.topFarmer ||
        profile.badge == FarmerBadge.farmerOfTheMonth;
    final badgeColor = GamificationService.farmerBadgeColor(profile.badge);

    String nextLabel = 'Max Tier';
    if (!isMax) {
      final nextBadge = FarmerBadge.values[profile.badge.index + 1];
      nextLabel = GamificationService.farmerBadgeLabel(nextBadge);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Text('Tier Progress',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          _FarmerTierSteps(current: profile.badge),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                GamificationService.farmerBadgeLabel(profile.badge),
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                isMax ? 'Max Tier' : nextLabel,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: profile.tierProgress,
              minHeight: 10,
              backgroundColor: AppTheme.border.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(badgeColor),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: isMax
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, color: AppTheme.warning, size: 16),
                      const SizedBox(width: 6),
                      Text('You reached the highest farmer tier!',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning)),
                    ],
                  )
                : Text(
                    '${profile.pointsToNextTier} more pts to unlock $nextLabel',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _FarmerTierSteps extends StatelessWidget {
  final FarmerBadge current;
  const _FarmerTierSteps({required this.current});

  @override
  Widget build(BuildContext context) {
    // Show first 5 tiers (skip farmerOfTheMonth as it's a special monthly award)
    final badges = FarmerBadge.values
        .where((b) => b != FarmerBadge.farmerOfTheMonth)
        .toList();
    return Row(
      children: List.generate(badges.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftBadge = badges[i ~/ 2];
          final reached = current.index > leftBadge.index;
          return Expanded(
            child: Container(
              height: 2,
              color: reached
                  ? AppTheme.primary
                  : AppTheme.border.withOpacity(0.3),
            ),
          );
        }
        final badge = badges[i ~/ 2];
        final isReached = current.index >= badge.index;
        final isCurrent = current == badge;
        final color = GamificationService.farmerBadgeColor(badge);
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 40 : 32,
              height: isCurrent ? 40 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReached
                    ? color.withOpacity(0.2)
                    : AppTheme.background,
                border: Border.all(
                    color: isReached
                        ? color
                        : AppTheme.border.withOpacity(0.3),
                    width: isCurrent ? 2.5 : 1.5),
              ),
              child: Center(
                child: Icon(
                  GamificationService.farmerBadgeIcon(badge),
                  color: isReached ? color : AppTheme.textMuted,
                  size: isCurrent ? 18 : 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              GamificationService.farmerBadgeLabel(badge)
                  .split(' ')
                  .first,
              style: GoogleFonts.inter(
                  fontSize: 8,
                  color: isReached ? color : AppTheme.textMuted),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PERFORMANCE BREAKDOWN
// ═══════════════════════════════════════════════════════════════════════════

class _PerformanceBreakdownCard extends StatelessWidget {
  final FarmerGamificationProfile profile;
  const _PerformanceBreakdownCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _PerfRow(
          icon: Icons.inventory_2_outlined,
          label: 'Completed Orders',
          value: '${profile.completedOrders}',
          pts:
              '+${profile.completedOrders * GamificationConfig.farmerPointsPerOrder} pts',
          color: AppTheme.primary),
      _PerfRow(
          icon: Icons.schedule,
          label: 'On-Time Deliveries',
          value: '${profile.onTimeDeliveries}',
          pts:
              '+${profile.onTimeDeliveries * GamificationConfig.farmerPointsOnTimeDelivery} pts',
          color: AppTheme.info),
      _PerfRow(
          icon: Icons.star_rounded,
          label: '5-Star Ratings',
          value: '${profile.fiveStarRatings}',
          pts:
              '+${profile.fiveStarRatings * GamificationConfig.farmerPointsPerFiveStar} pts',
          color: AppTheme.warning),
      _PerfRow(
          icon: Icons.verified_rounded,
          label: 'Verified Quality',
          value: '${profile.verifiedProducts}',
          pts:
              '+${profile.verifiedProducts * GamificationConfig.farmerPointsVerifiedQuality} pts',
          color: AppTheme.success),
      _PerfRow(
          icon: Icons.cancel_outlined,
          label: 'Cancellations',
          value: '${profile.cancellations}',
          pts:
              '${profile.cancellations * GamificationConfig.farmerDeductCancellation} pts',
          color: AppTheme.error),
      _PerfRow(
          icon: Icons.warning_amber_rounded,
          label: 'Complaints',
          value: '${profile.complaints}',
          pts:
              '${profile.complaints * GamificationConfig.farmerDeductComplaint} pts',
          color: AppTheme.error),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppTheme.info, size: 20),
              const SizedBox(width: 8),
              Text('Performance Breakdown',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.map((r) => _buildRow(r)),
        ],
      ),
    );
  }

  Widget _buildRow(_PerfRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(r.icon, color: r.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textPrimary)),
          ),
          Text(r.value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: r.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(r.pts,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: r.color)),
          ),
        ],
      ),
    );
  }
}

class _PerfRow {
  final IconData icon;
  final String label;
  final String value;
  final String pts;
  final Color color;
  const _PerfRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.pts,
      required this.color});
}

// ═══════════════════════════════════════════════════════════════════════════
//  EARNING RULES
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerEarningRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rules = [
      (Icons.inventory_2_outlined, 'Per completed order',
          '+${GamificationConfig.farmerPointsPerOrder} pts'),
      (Icons.schedule, 'On-time delivery',
          '+${GamificationConfig.farmerPointsOnTimeDelivery} pts'),
      (Icons.star_rounded, '5-star rating',
          '+${GamificationConfig.farmerPointsPerFiveStar} pts'),
      (Icons.verified_rounded, 'Verified quality',
          '+${GamificationConfig.farmerPointsVerifiedQuality} pts'),
      (Icons.cancel_outlined, 'Cancellation',
          '${GamificationConfig.farmerDeductCancellation} pts'),
      (Icons.warning_amber_rounded, 'Customer complaint',
          '${GamificationConfig.farmerDeductComplaint} pts'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.info, size: 20),
              const SizedBox(width: 8),
              Text('Point Rules',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...rules.map((r) {
            final isDeduct = r.$3.startsWith('-');
            final color = isDeduct ? AppTheme.error : AppTheme.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(r.$1, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.$2,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(r.$3,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LEADERBOARD BANNER
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerLeaderboardBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _FarmerLeaderboardBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.warning.withOpacity(0.8),
              AppTheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Farmer Leaderboard',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Compete for Farmer of the Month!',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FARMER STAT BUBBLE
// ═══════════════════════════════════════════════════════════════════════════

class _FarmerStatBubble extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool small;

  const _FarmerStatBubble({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 8 : 14, vertical: small ? 8 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: small ? 15 : 20),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: small ? 11 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 8,
                    color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
