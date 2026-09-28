import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/data_service.dart';
import 'farmer_profile_screen.dart';

class FavoriteFarmersScreen extends StatefulWidget {
  const FavoriteFarmersScreen({super.key});

  @override
  State<FavoriteFarmersScreen> createState() => _FavoriteFarmersScreenState();
}

class _FavoriteFarmersScreenState extends State<FavoriteFarmersScreen> {
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChange);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChange);
    super.dispose();
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final followed = _dataService.followedFarmers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Following Farmers'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: followed.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.agriculture_outlined,
                        size: 60,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You are not following any farmers',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow local farmers to get real-time restock alerts on fresh crops!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: followed.length,
                  itemBuilder: (context, index) {
                    final farmer = followed[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FarmerProfileScreen(farmer: farmer),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15281E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(farmer.avatarUrl),
                              onBackgroundImageError: (_, _) {},
                              child: farmer.avatarUrl.isEmpty
                                  ? const Icon(
                                      Icons.agriculture_outlined,
                                      color: AppTheme.primary,
                                      size: 24,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        farmer.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF0F5F1),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (farmer.isVerified)
                                        const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: AppTheme.primary,
                                        ),
                                    ],
                                  ),
                                  Text(
                                    farmer.farmName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF8FA497),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${farmer.rating} • ${farmer.location}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFA1C68A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _dataService.toggleFollowFarmer(farmer.id);
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withAlpha(30)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Unfollow',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8FA497),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
