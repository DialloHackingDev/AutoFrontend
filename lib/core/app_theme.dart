import 'package:flutter/material.dart';

/// Charte graphique AutoConnect, issue du logo (couleurs du drapeau guinéen).
///
/// - Rouge : couleur de marque (voiture, ruban) → actions principales
/// - Vert : succès, « en ligne », paiement confirmé
/// - Orange : accent, mises en avant, éléments en attente
/// - Jaune : touche décorative uniquement (peu lisible sur fond blanc)
class AppColors {
  static const primary = Color(0xFFE41824);
  static const primaryDark = Color(0xFFB3121C);
  static const primarySoft = Color(0xFFFDECED);

  static const success = Color(0xFF009C4E);
  static const successDark = Color(0xFF007A3D);
  static const successSoft = Color(0xFFE6F5EC);

  static const accent = Color(0xFFFCA83C);
  static const warning = Color(0xFFB86A00); // orange lisible pour du texte
  static const warningSoft = Color(0xFFFFF4E3);
  static const warningBorder = Color(0xFFFCD9A5);

  static const yellow = Color(0xFFFCF000);

  static const danger = Color(0xFFC62828);
  static const dangerSoft = Color(0xFFFDECEC);

  static const ink = Color(0xFF1C2230);
  static const inkMuted = Color(0xFF5B6475);
  static const border = Color(0xFFE4E6EB);
  static const background = Color(0xFFF7F7F8);
  static const surfaceMuted = Color(0xFFF2F3F5);
  static const surface = Colors.white;

  /// Liseré tricolore du logo, pour les touches décoratives
  static const brandGradient = LinearGradient(colors: [primary, accent, success]);
}

class AppTheme {
  static const _radius = 14.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.successSoft,
      tertiary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    );

    final roundedShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),

      // Boutons : grande zone tactile (52 px), coins arrondis
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: roundedShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: roundedShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 52),
          side: const BorderSide(color: AppColors.border),
          shape: roundedShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: buttonText),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        prefixIconColor: AppColors.inkMuted,
        labelStyle: const TextStyle(color: AppColors.inkMuted),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.ink, fontWeight: FontWeight.w500),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        elevation: 8,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.success : null),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.primary, textColor: Colors.white),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.inkMuted),
    );
  }
}
