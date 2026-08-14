import "package:flutter/material.dart";

class UniCartColors {
  UniCartColors._();

  static const background = Color(0xFF050B18);
  static const backgroundAlt = Color(0xFF081120);
  static const surface = Color(0xFF0D1526);
  static const surfaceRaised = Color(0xFF111E35);
  static const surfaceSoft = Color(0xFF16243D);
  static const surfaceInput = Color(0xFF0A1424);

  static const primary = Color(0xFF2563EB);
  static const primaryBright = Color(0xFF3B82F6);
  static const primarySoft = Color(0xFF60A5FA);

  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22D3EE);

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const border = Color(0xFF1E3A5F);
  static const divider = Color(0xFF17263E);

  static const primaryGlow = Color(0x382563EB);
  static const surfaceGlass = Color(0xCC0D1526);
  static const borderGlass = Color(0x331E5BA9);
}

class UniCartRadius {
  UniCartRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
}

class UniCartSpacing {
  UniCartSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class UniCartTheme {
  UniCartTheme._();

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark(
      primary: UniCartColors.primary,
      secondary: UniCartColors.primaryBright,
      surface: UniCartColors.surface,
      error: UniCartColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: UniCartColors.textPrimary,
      onError: Colors.white,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UniCartColors.background,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineLarge: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: const TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: const TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: UniCartColors.textPrimary,
        titleTextStyle: TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UniCartColors.surfaceInput,
        hintStyle: const TextStyle(
          color: UniCartColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: UniCartColors.primarySoft,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: UniCartColors.textSecondary,
        suffixIconColor: UniCartColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide: const BorderSide(color: UniCartColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide: const BorderSide(color: UniCartColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide: const BorderSide(
            color: UniCartColors.primaryBright,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide: const BorderSide(color: UniCartColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide: const BorderSide(
            color: UniCartColors.danger,
            width: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: UniCartColors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.xl),
          side: const BorderSide(color: UniCartColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.xl),
          side: const BorderSide(color: UniCartColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        contentTextStyle: const TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
      dividerTheme: const DividerThemeData(
        color: UniCartColors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: UniCartColors.primaryBright,
        linearTrackColor: UniCartColors.surfaceSoft,
        circularTrackColor: UniCartColors.surfaceSoft,
      ),
      iconTheme: const IconThemeData(color: UniCartColors.textSecondary),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UniCartColors.primarySoft,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UniCartRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UniCartColors.textPrimary,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: UniCartColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UniCartRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: UniCartColors.primary,
          disabledBackgroundColor: UniCartColors.surfaceSoft,
          disabledForegroundColor: UniCartColors.textMuted,
          minimumSize: const Size(44, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UniCartRadius.md),
          ),
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        textColor: UniCartColors.textPrimary,
        collapsedTextColor: UniCartColors.textPrimary,
        iconColor: UniCartColors.textSecondary,
        collapsedIconColor: UniCartColors.textSecondary,
        shape: Border(),
        collapsedShape: Border(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: UniCartColors.surfaceRaised,
        modalBarrierColor: Color(0x99000000),
      ),
    );
  }
}
