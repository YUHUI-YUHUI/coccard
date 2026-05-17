import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette - Cthulhu forest green
  static const Color primary = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF2D6A4F);
  static const Color primaryDark = Color(0xFF0F2B1F);

  // Accent - ancient gold
  static const Color accent = Color(0xFFB08D57);
  static const Color accentLight = Color(0xFFD4A96A);

  // Danger
  static const Color danger = Color(0xFF8B0000);
  static const Color dangerLight = Color(0xFFB22222);

  // Attribute colors (semantic, consistent across themes)
  static const Color attrStr = Color(0xFFC0392B); // red
  static const Color attrCon = Color(0xFF27AE60); // green
  static const Color attrSiz = Color(0xFFE67E22); // orange
  static const Color attrDex = Color(0xFF2980B9); // blue
  static const Color attrApp = Color(0xFFE84393); // pink
  static const Color attrInt = Color(0xFF8E44AD); // purple
  static const Color attrPow = Color(0xFF16A085); // teal
  static const Color attrEdu = Color(0xFF2C3E50); // dark blue

  // Stat colors
  static const Color statHp = Color(0xFFC0392B);
  static const Color statMp = Color(0xFF2980B9);
  static const Color statSan = Color(0xFF8E44AD);
  static const Color statLuck = Color(0xFFD4A96A);
  static const Color statMove = Color(0xFF27AE60);
  static const Color statBuild = Color(0xFFE67E22);

  // Skill point colors
  static const Color occupationPoint = Color(0xFF2980B9);
  static const Color interestPoint = Color(0xFF27AE60);
  static const Color creditRange = Color(0xFFB08D57);

  // Reference page colors
  static const Color insanity = Color(0xFF8E44AD);
  static const Color phobia = Color(0xFFE67E22);
  static const Color mania = Color(0xFF16A085);

  // Success / failure for dice rolls
  static const Color success = Color(0xFF27AE60);
  static const Color failure = Color(0xFFC0392B);
}

class AppTheme {
  AppTheme._();

  // ==================== Dark Theme ====================
  static ThemeData dark() {
    const bg = Color(0xFF121212);
    const surface = Color(0xFF1A2E26);
    const card = Color(0xFF1E3A2F);
    const textPrimary = Color(0xFFE8E0D0);
    const textSecondary = Color(0xFF9DB4A8);

    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: textPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: textPrimary,
      secondary: AppColors.accent,
      onSecondary: Colors.black,
      secondaryContainer: AppColors.accent.withOpacity( 0.3),
      onSecondaryContainer: AppColors.accentLight,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      error: AppColors.dangerLight,
      onError: Colors.white,
      outline: AppColors.accent.withOpacity( 0.3),
      outlineVariant: Colors.white.withOpacity( 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 2,
        shadowColor: Colors.black.withOpacity( 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.accent.withOpacity( 0.15)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.accent.withOpacity( 0.2),
        thickness: 1,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.accentLight,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryLight,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent.withOpacity( 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent.withOpacity( 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withOpacity( 0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentLight,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight.withOpacity( 0.3),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        side: BorderSide(color: AppColors.accent.withOpacity( 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: AppColors.accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent.withOpacity( 0.4);
          return Colors.white.withOpacity( 0.1);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.accent),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ==================== Light Theme ====================
  static ThemeData light() {
    const bg = Color(0xFFF5F0E8);
    const surface = Color(0xFFFFFFFF);
    const card = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF2D2D2D);
    const textSecondary = Color(0xFF6B6B6B);

    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD4E8DF),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF0E0C8),
      onSecondaryContainer: const Color(0xFF5C4A2E),
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.primary.withOpacity( 0.3),
      outlineVariant: Colors.black.withOpacity( 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 1,
        shadowColor: Colors.black.withOpacity( 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.primary.withOpacity( 0.12)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withOpacity( 0.15),
        thickness: 1,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F5F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity( 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary.withOpacity( 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0E0C8),
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        side: BorderSide(color: AppColors.accent.withOpacity( 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: AppColors.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent.withOpacity( 0.4);
          return Colors.black.withOpacity( 0.1);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        titleLarge: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
