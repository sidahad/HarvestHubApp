import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_card_video_background.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('About HarvestHub'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Box
              HeroCardVideoBackground(
                videoAsset: 'video/about_harvesthub_hero.mp4',
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(24),
                fallbackDecoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                overlayGradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D2813).withValues(alpha: 0.72),
                    const Color(0xFF091E0E).withValues(alpha: 0.84),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HarvestHub Direct',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connecting Local Farmers Direct to Your Kitchen',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Our Mission
              Text(
                'Our Mission',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'HarvestHub empowers local smallholder farmers by removing middlemen, ensuring fair compensation for growers and offering consumers 100% fresh, organic produce harvested straight from local fields.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // Key Features Card Grid
              Text(
                'Why HarvestHub?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureTile(
                'Direct From Local Farmers',
                'No middlemen, maximum freshness & transparent pricing.',
              ),
              _buildFeatureTile(
                'Scheduled Farm Pickups',
                'Flexible time slots for pickup or doorstep delivery.',
              ),
              _buildFeatureTile(
                'HarvestAI Smart Assistant',
                'Instant recommendations on seasonal crops & farm recipes.',
              ),
              _buildFeatureTile(
                'Verified Organic Standards',
                'Rigorous farmer verification and pesticide checking.',
              ),
              const SizedBox(height: 30),

              // App Version
              Center(
                child: Text(
                  'HarvestHub App v1.0.0 (Build 2026)\nBuilt with Flutter & Firebase',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF15281E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF0F5F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8FA497),
            ),
          ),
        ],
      ),
    );
  }
}
