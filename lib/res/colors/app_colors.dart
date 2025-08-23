import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../main.dart';

class AppColors {
  // ============== Light Theme Colors (Updated) ==============
  static const Color lightPrimary = Color(0xFF2A4D6E); // Navy (Trustworthy)
  static const Color lightSecondary = Color(0xFF5C9EAD); // Soft Teal (Calm)
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray (Background)

  // ============== Dark Theme Colors (Updated) ==============
  static const Color darkPrimary = Color(0xFF121212); // Charcoal (Professional)
  static const Color darkSecondary = Color(0xFF616161); // Gray (Secondary Dark)

  // ============== Theme-Aware Getters (Unchanged Structure) ==============
  static Color get primaryColor {
    return Get.find<ThemeController>().isDarkMode.value ? darkPrimary : lightPrimary;
  }

  static Color get secondaryColor {
    return Get.find<ThemeController>().isDarkMode.value ? darkSecondary : lightSecondary;
  }

  // ============== Static Colors (Updated to Match Healthcare Theme) ==============
  static const Color darkGreen = Color(0xFF015332); // Deep Green (Medical)
  static const Color rockCrystal = Color(0xFF4D3833); // Warm Brown (Neutral)
  static const Color lavender = Color(0xFFA89CFF); // Soft Lavender (Accent)
  static const Color goldenFizz = Color(0xFFFFD700); // Gold (Notification)
  static const Color illusion = Color(0xFFF7A6B6); // Soft Pink (Subtle)
  static const Color redColor = Color(0xFFE74C3C); // Error Red (Accessible)
  static const Color myColor = Color(0xFF2C5F2D); // Original Green (Retained)
  static const Color myColor2 = Color(0xFF97BC62); // Sage Green (Positive)
  static const Color terracottaRed = Color(0xFFB85042); // Warm Red (Alert)
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ============== Gradient (Adjusted for New Colors) ==============
  static LinearGradient get linearGrad {
    return Get.find<ThemeController>().isDarkMode.value
        ? LinearGradient(colors: [darkPrimary, darkSecondary]) // Dark: Charcoal → Gray
        : LinearGradient(colors: [lightPrimary, lightSecondary]); // Light: Navy → Teal
  }
}