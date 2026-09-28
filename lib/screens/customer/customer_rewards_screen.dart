import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../gamification/leaderboard_screen.dart';

class CustomerRewardsScreen extends StatefulWidget {
  const CustomerRewardsScreen({super.key});

  @override
  State<CustomerRewardsScreen> createState() => _CustomerRewardsScreenState();
}

class _CustomerRewardsScreenState extends State<CustomerRewardsScreen> {
  final GamificationService _gs = GamificationService();
  final TextEditingController _redeemController = TextEditingController();
  int _pointsToRedeem = 0;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
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
        title: Text('My Rewards',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: AppTheme.primary),
            tooltip: 'Leaderboard',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
        ],
      ),
      body: StreamBuilder<CustomerGamificationProfile>(
        stream: _gs.customerProfileStream(_uid!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final profile =
              snap.data ?? CustomerGamificationProfile.empty(_uid!);
          return _buildBody(profile);
        },
      ),
    );
  }

  Widget _buildBody(CustomerGamificationProfile p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PointsHeroCard(profile: p),
          const SizedBox(height: 20),
          _BadgeProgressCard(profile: p),
          const SizedBox(height: 20),
          _RedeemCard(
            profile: p,
            pointsToRedeem: _pointsToRedeem,
            controller: _redeemController,
            onChanged: (v) {
              final parsed = int.tryParse(v) ?? 0;
              setState(() => _pointsToRedeem = parsed.clamp(
                    0,
                    p.currentPoints,
                  ));
            },
            onRedeem: () => _showRedeemInfo(p),
          ),
          const SizedBox(height: 20),
          _EarningRulesCard(),
          const SizedBox(height: 20),
          _LeaderboardBanner(onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
        ],
      ),
    );
  }

  void _showRedeemInfo(CustomerGamificationProfile p) {
    if (_pointsToRedeem < GamificationConfig.minRedeemPoints) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Minimum ${GamificationConfig.minRedeemPoints} points required to redeem.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final discount =
        GamificationService.calculateDiscount(_pointsToRedeem);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem Points',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings_rounded,
                color: AppTheme.warning, size: 48),
            const SizedBox(height: 12),
            Text(
              '$_pointsToRedeem pts  →  Rs ${discount.toStringAsFixed(0)} OFF',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Apply this discount at checkout on your next order.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',
                style: GoogleFonts.poppins(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HERO POINTS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PointsHeroCard extends StatelessWidget {
  final CustomerGamificationProfile profile;
  const _PointsHeroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final badgeColor = GamificationService.customerBadgeColor(profile.badge);
    final badgeIcon = GamificationService.customerBadgeIcon(profile.badge);
    final badgeLabel = GamificationService.customerBadgeLabel(profile.badge);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withOpacity(0.25),
            AppTheme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.12),
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
                  Text('Available Points',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${profile.currentPoints}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
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
              // Monthly pts bubble
              _StatBubble(
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
              _StatBubble(
                label: 'Total Earned',
                value: '${profile.totalPoints}',
                icon: Icons.stars_rounded,
                color: AppTheme.warning,
                small: true,
              ),
              const SizedBox(width: 12),
              _StatBubble(
                label: 'Orders Done',
                value: '${profile.completedOrders}',
                icon: Icons.check_circle_outline_rounded,
                color: AppTheme.primary,
                small: true,
              ),
              const SizedBox(width: 12),
              _StatBubble(
                label: 'Total Spent',
                value: 'Rs ${profile.totalSpent.toStringAsFixed(0)}',
                icon: Icons.wallet_rounded,
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
                  const Icon(Icons.emoji_events,
                      color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  Text('Buyer of the Month!',
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
//  BADGE PROGRESS CARD
// ═══════════════════════════════════════════════════════════════════════════

class _BadgeProgressCard extends StatelessWidget {
  final CustomerGamificationProfile profile;
  const _BadgeProgressCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isMax = profile.badge == CustomerBadge.vipCustomer;
    final badgeColor = GamificationService.customerBadgeColor(profile.badge);

    // Next tier info
    String nextLabel = 'Max Tier';
    if (!isMax) {
      final nextBadge = CustomerBadge.values[profile.badge.index + 1];
      nextLabel = GamificationService.customerBadgeLabel(nextBadge);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded,
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
          // Tier steps
          _TierSteps(current: profile.badge),
          const SizedBox(height: 20),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                GamificationService.customerBadgeLabel(profile.badge),
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
          if (!isMax)
            Center(
              child: Text(
                '${profile.pointsToNextTier} more pts to unlock $nextLabel',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            )
          else
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'You have reached the highest tier!',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TierSteps extends StatelessWidget {
  final CustomerBadge current;
  const _TierSteps({required this.current});

  @override
  Widget build(BuildContext context) {
    final badges = CustomerBadge.values;
    return Row(
      children: List.generate(badges.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
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
        final color = GamificationService.customerBadgeColor(badge);
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 44 : 36,
              height: isCurrent ? 44 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isReached
                    ? color.withOpacity(0.2)
                    : AppTheme.background,
                border: Border.all(
                  color: isReached
                      ? color
                      : AppTheme.border.withOpacity(0.3),
                  width: isCurrent ? 2.5 : 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  GamificationService.customerBadgeIcon(badge),
                  color: isReached ? color : AppTheme.textMuted,
                  size: isCurrent ? 20 : 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              GamificationService.customerBadgeLabel(badge)
                  .split(' ')
                  .first,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color:
                      isReached ? color : AppTheme.textMuted),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REDEEM CARD
// ═══════════════════════════════════════════════════════════════════════════

class _RedeemCard extends StatelessWidget {
  final CustomerGamificationProfile profile;
  final int pointsToRedeem;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRedeem;

  const _RedeemCard({
    required this.profile,
    required this.pointsToRedeem,
    required this.controller,
    required this.onChanged,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final discount =
        GamificationService.calculateDiscount(pointsToRedeem);
    final canRedeem =
        pointsToRedeem >= GamificationConfig.minRedeemPoints &&
            pointsToRedeem <= profile.currentPoints;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.redeem_rounded,
                  color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Text('Redeem Points',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              Text(
                '${profile.currentPoints} pts available',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${GamificationConfig.pointsPerRupee} pts = Rs 1 discount  •  Min ${GamificationConfig.minRedeemPoints} pts',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Enter points',
                    hintStyle: GoogleFonts.inter(
                        color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.primary),
                    ),
                    suffixText: 'pts',
                    suffixStyle: GoogleFonts.inter(
                        color: AppTheme.textSecondary),
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: canRedeem ? onRedeem : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  disabledBackgroundColor:
                      AppTheme.success.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Redeem',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ],
          ),
          if (pointsToRedeem > 0) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canRedeem
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: canRedeem
                      ? AppTheme.success.withOpacity(0.4)
                      : AppTheme.error.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    canRedeem
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: canRedeem
                        ? AppTheme.success
                        : AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canRedeem
                        ? '$pointsToRedeem pts  →  Rs ${discount.toStringAsFixed(0)} discount on next order'
                        : pointsToRedeem > profile.currentPoints
                            ? 'Not enough points'
                            : 'Min ${GamificationConfig.minRedeemPoints} pts required',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: canRedeem
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
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
//  EARNING RULES CARD
// ═══════════════════════════════════════════════════════════════════════════

class _EarningRulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rules = [
      (Icons.shopping_bag_outlined, 'Every Rs.100 spent',
          '+${GamificationConfig.pointsPerHundredRupees} pts'),
      (Icons.stars_rounded, 'First order bonus', '+${GamificationConfig.firstOrderBonus} pts'),
      (Icons.card_giftcard, 'Redeem rate',
          '${GamificationConfig.pointsPerRupee} pts = Rs 1'),
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
              Text('How to Earn',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(r.$1, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
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
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.$3,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LEADERBOARD BANNER
// ═══════════════════════════════════════════════════════════════════════════

class _LeaderboardBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LeaderboardBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF88AB75), Color(0xFF52B788)],
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
                  Text('Monthly Leaderboard',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text("See who's the Buyer of the Month!",
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
//  STAT BUBBLE
// ═══════════════════════════════════════════════════════════════════════════

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatBubble({
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
            horizontal: small ? 10 : 14, vertical: small ? 8 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: small ? 16 : 20),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: small ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
