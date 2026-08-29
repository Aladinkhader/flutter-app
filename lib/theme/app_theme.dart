import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryTeal,
        secondary: AppColors.secondaryText,
        surface: AppColors.cardDark,
        onPrimary: AppColors.background,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.mainText,
        displayColor: AppColors.mainText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.95),
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.mainText,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.veryDarkBackground,
        selectedItemColor: AppColors.mainText,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
