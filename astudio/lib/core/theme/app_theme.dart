import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';

final appThemeProvider = Provider<AppTheme>((_) => const AppTheme());

class AppTheme {
  const AppTheme();

  ThemeData get lightTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.sunsetGold,
      onPrimary: AppColors.richBlack,
      secondary: AppColors.steelGray,
      onSecondary: AppColors.snowWhite,
      error: AppColors.errorRed,
      onError: AppColors.snowWhite,
      surface: AppColors.midnightGray,
      onSurface: AppColors.snowWhite,
      surfaceTint: AppColors.sunsetGold,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.jetBlack,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoal.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.sunsetGold.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.sunsetGold.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.sunsetGold),
        ),
        hintStyle: TextStyle(color: AppColors.snowWhite.withValues(alpha: 0.6)),
        labelStyle: const TextStyle(color: AppColors.snowWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunsetGold,
          foregroundColor: AppColors.richBlack,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textTheme: Typography.englishLike2021.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.charcoal.withValues(alpha: 0.3),
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.midnightGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.charcoal.withValues(alpha: 0.4)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.charcoal,
        selectedColor: AppColors.sunsetGold.withValues(alpha: 0.8),
        labelStyle: const TextStyle(color: AppColors.snowWhite),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData get darkTheme => lightTheme;
}
