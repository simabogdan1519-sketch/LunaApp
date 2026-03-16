import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LunaTheme {
  static const Color primary = Color(0xFFE8A4B8);
  static const Color primaryDark = Color(0xFFC47A95);
  static const Color secondary = Color(0xFFB8A4D8);
  static const Color menstrual = Color(0xFFE57373);
  static const Color follicular = Color(0xFF81C784);
  static const Color ovulation = Color(0xFFE6C14F);
  static const Color luteal = Color(0xFF7986CB);
  static const Color surface = Color(0xFFFDF6F8);
  static const Color surfaceV = Color(0xFFF5EEF2);
  static const Color text = Color(0xFF3D2C35);
  static const Color text2 = Color(0xFF8A7080);
  static const Color text3 = Color(0xFFBFADB6);

  static Color phaseColor(String phase) {
    switch (phase) {
      case 'menstrual': return menstrual;
      case 'follicular': return follicular;
      case 'ovulation': return ovulation;
      case 'luteal': return luteal;
      default: return primary;
    }
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: surface),
    scaffoldBackgroundColor: surface,
    textTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(color: text, fontSize: 20, fontWeight: FontWeight.w900),
      iconTheme: const IconThemeData(color: primaryDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceV,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      hintStyle: GoogleFonts.nunito(color: text3, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
