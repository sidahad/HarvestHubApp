import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Botanical Luxury Dark Mode (Leafora Aesthetic)
  static const Color background     = Color(0xFF0D1A13); // Deep forest botanical background
  static const Color backgroundLight= Color(0xFF13251B);
  static const Color surface        = Color(0xFF15281E); // Translucent / frosted card surface
  static const Color cardColor      = Color(0xFF182D22); // Card surface
  static const Color cardSurfaceLight = Color(0xFF1F372A);
  
  // Accents
  static const Color primary        = Color(0xFF88AB75); // Sage / Pistachio green accent
  static const Color primaryLight   = Color(0xFFA1C68A);
  static const Color primaryDark    = Color(0xFF6B8F59);
  static const Color accent         = Color(0xFFB5D4A0);
  static const Color secondary      = Color(0xFFD4A373);
  
  // Text
  static const Color textPrimary    = Color(0xFFF0F5F1); // Soft crisp white
  static const Color textSecondary  = Color(0xFF8FA497); // Eucalyptus / sage grey
  static const Color textMuted      = Color(0xFF657A6E);
  
  // Borders & Glass
  static const Color border         = Color(0x26FFFFFF); // 15% white subtle border
  static const Color borderSubtle   = Color(0x1AFFFFFF); // 10% white
  static const Color glassFill      = Color(0x1FFFFFFF); // Frosted glass highlight
  
  // States
  static const Color success        = Color(0xFF52B788);
  static const Color warning        = Color(0xFFE9C46A);
  static const Color error          = Color(0xFFE76F51);
  static const Color info           = Color(0xFF48CAE4);

  static BoxDecoration glassCardDecoration({
    double radius = 24,
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: AppTheme.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(50),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0D1A13),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: error, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: border),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0E1C15),
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSurfaceLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
