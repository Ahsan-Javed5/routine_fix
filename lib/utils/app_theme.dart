import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// ---- Named palette ----
/// InkNavy    - primary dark surface / brand color
/// SignalTeal - completion / accent / "you did it" color
/// EmberCoral - high priority
/// AmberGold  - medium priority
/// SageGreen  - low priority
/// Mist       - light background
class AppColors {
  static const inkNavy = Color(0xFF1B2340);
  static const signalTeal = Color(0xFF2EC4B6);
  static const emberCoral = Color(0xFFFF6B5E);
  static const amberGold = Color(0xFFFFB84D);
  static const sageGreen = Color(0xFF6FB77E);
  static const mist = Color(0xFFF5F7FA);
  static const charcoal = Color(0xFF14171F);
}

Color priorityColor(Priority p) {
  switch (p) {
    case Priority.high:
      return AppColors.emberCoral;
    case Priority.medium:
      return AppColors.amberGold;
    case Priority.low:
      return AppColors.sageGreen;
  }
}

String priorityLabel(Priority p) {
  switch (p) {
    case Priority.high:
      return 'High';
    case Priority.medium:
      return 'Medium';
    case Priority.low:
      return 'Low';
  }
}

String repetitionLabel(Repetition r) {
  switch (r) {
    case Repetition.none:
      return 'One-time';
    case Repetition.daily:
      return 'Daily';
    case Repetition.alternateDay:
      return 'Alternate Day';
    case Repetition.weekly:
      return 'Weekly';
    case Repetition.custom:
      return 'Custom Days';
  }
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.inkNavy,
      brightness: Brightness.light,
      primary: AppColors.inkNavy,
      secondary: AppColors.signalTeal,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.mist,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.signalTeal.withOpacity(0.18),
        elevation: 2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.signalTeal,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(height: 1.35),
      ),
    );
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.signalTeal,
      brightness: Brightness.dark,
      secondary: AppColors.signalTeal,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.charcoal,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E222C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E222C),
        indicatorColor: AppColors.signalTeal.withOpacity(0.25),
        elevation: 2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.signalTeal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
