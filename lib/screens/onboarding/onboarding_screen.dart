import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardSlide> _slides = [
    _OnboardSlide(
      title: 'HarvestHub',
      tagline: 'Bring Nature Home',
      description: 'Beautiful plants.\nHappy spaces.\nBetter you.',
      buttonText: 'Get Started',
    ),
    _OnboardSlide(
      title: 'Farm Fresh',
      tagline: 'Direct From Local Farmers',
      description: 'Handpicked harvest.\nZero middlemen.\nPeak freshness.',
      buttonText: 'Explore Produce',
    ),
    _OnboardSlide(
      title: 'HarvestAI',
      tagline: 'Smart Farm Assistant',
      description:
          'Instant recipes.\nSeasonal recommendations.\nSmart insights.',
      buttonText: 'Start Shopping',
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToRoles();
    }
  }

  void _goToRoles() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1711),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Lush dark botanical background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.4),
                radius: 1.4,
                colors: [
                  Color(0xFF1E3A2B), // Ambient foliage glow
                  Color(0xFF112319),
                  Color(0xFF09140E),
                ],
              ),
            ),
          ),

          // Atmospheric subtle foliage shapes
          Positioned(
            top: -60,
            left: -40,
            child: Icon(Icons.eco, size: 280, color: Colors.white.withAlpha(8)),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Icon(
              Icons.spa_rounded,
              size: 320,
              color: const Color(0xFF88AB75).withAlpha(12),
            ),
          ),

          // Foreground layout: header, slide card, dots.
          // Using a Column (inside SafeArea) instead of freely-overlapping
          // Positioned/Stack children guarantees the header row always
          // reserves its own space at the top and the PageView/card is
          // confined to the remaining area via Expanded — so the Skip
          // button can never overlap the card content, on any screen size.
          SafeArea(
            child: Column(
              children: [
                // Top Controls (Back + Skip)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFFF0F5F1),
                            size: 18,
                          ),
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                        )
                      else
                        const SizedBox(width: 48),
                      TextButton(
                        onPressed: _goToRoles,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8FA497),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView for slides — takes all remaining vertical space
                // below the header, so it can never grow upward into it.
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, index) {
                      final slide = _slides[index];
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    28,
                                    44,
                                    28,
                                    36,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF15281E,
                                    ).withAlpha(160),
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(35),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(90),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Leaf Icon Emblem
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(
                                            0xFF88AB75,
                                          ).withAlpha(30),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF88AB75,
                                            ).withAlpha(80),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.eco_outlined,
                                          size: 34,
                                          color: Color(0xFFA1C68A),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Brand Title in Serif
                                      Text(
                                        slide.title,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFF0F5F1),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Subtitle Tagline
                                      Text(
                                        slide.tagline,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFA1C68A),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Description paragraph
                                      Text(
                                        slide.description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          height: 1.7,
                                          color: const Color(0xFF9EB3A6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 38),

                                      // Pill Action Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: _onNext,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF88AB75,
                                            ),
                                            foregroundColor: const Color(
                                              0xFF0D1A13,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                slide.buttonText,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0D1A13,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                                color: Color(0xFF0D1A13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Pagination Dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFA1C68A)
                              : Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
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

class _OnboardSlide {
  final String title;
  final String tagline;
  final String description;
  final String buttonText;

  const _OnboardSlide({
    required this.title,
    required this.tagline,
    required this.description,
    required this.buttonText,
  });
}
