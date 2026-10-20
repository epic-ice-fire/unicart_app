import "package:flutter/material.dart";

class UniCartColors {
  UniCartColors._();
  static final ValueNotifier<String> schoolId = ValueNotifier<String>("pau");
  static String get activeSchoolId => schoolId.value;
  static void setSchool(String? id) { final next = id == "augustine" || id == "babcock" ? id! : "pau"; if (schoolId.value != next) schoolId.value = next; }
  static _UniCartPalette get _palette => switch (activeSchoolId) { "augustine" => _augustine, "babcock" => _babcock, _ => _pau };
  static const _pau = _UniCartPalette(background: Color(0xFF050B18), backgroundAlt: Color(0xFF081120), surface: Color(0xFF0D1526), surfaceRaised: Color(0xFF111E35), surfaceSoft: Color(0xFF16243D), surfaceInput: Color(0xFF0A1424), primary: Color(0xFF2563EB), primaryBright: Color(0xFF3B82F6), primarySoft: Color(0xFF60A5FA), success: Color(0xFF10B981), warning: Color(0xFFF59E0B), danger: Color(0xFFEF4444), purple: Color(0xFF8B5CF6), cyan: Color(0xFF22D3EE), textPrimary: Color(0xFFF8FAFC), textSecondary: Color(0xFF94A3B8), textMuted: Color(0xFF64748B), border: Color(0xFF1E3A5F), divider: Color(0xFF17263E), primaryGlow: Color(0x382563EB), surfaceGlass: Color(0xCC0D1526), borderGlass: Color(0x331E5BA9));
  static const _augustine = _UniCartPalette(background: Color(0xFFF7F0E9), backgroundAlt: Color(0xFFF2E7DF), surface: Color(0xFFFFFAF6), surfaceRaised: Color(0xFFFFFFFF), surfaceSoft: Color(0xFFF1E2DD), surfaceInput: Color(0xFFFFFDFC), primary: Color(0xFF70263B), primaryBright: Color(0xFF9E455A), primarySoft: Color(0xFF9E455A), success: Color(0xFF356B50), warning: Color(0xFF98651E), danger: Color(0xFFB42332), purple: Color(0xFF84506F), cyan: Color(0xFF527D82), textPrimary: Color(0xFF301720), textSecondary: Color(0xFF6F5960), textMuted: Color(0xFF8B7B7F), border: Color(0xFFE0C8C3), divider: Color(0xFFEADBD7), primaryGlow: Color(0x2870263B), surfaceGlass: Color(0xE6FFFAF6), borderGlass: Color(0x339E455A));
  static const _babcock = _UniCartPalette(background: Color(0xFFF6F4EA), backgroundAlt: Color(0xFFEBEFE4), surface: Color(0xFFFCFBF6), surfaceRaised: Color(0xFFFFFFFF), surfaceSoft: Color(0xFFE5EDE3), surfaceInput: Color(0xFFFFFEFA), primary: Color(0xFF174C3A), primaryBright: Color(0xFF2D7656), primarySoft: Color(0xFF2D7656), success: Color(0xFF2D7656), warning: Color(0xFF9A6B14), danger: Color(0xFFB42332), purple: Color(0xFF5F6D4A), cyan: Color(0xFFD8ED78), textPrimary: Color(0xFF172C23), textSecondary: Color(0xFF586B5F), textMuted: Color(0xFF78877D), border: Color(0xFFD4DFD0), divider: Color(0xFFE1E8DC), primaryGlow: Color(0x28174C3A), surfaceGlass: Color(0xE6FCFBF6), borderGlass: Color(0x332D7656));
  static Color get background => _palette.background; static Color get backgroundAlt => _palette.backgroundAlt; static Color get surface => _palette.surface; static Color get surfaceRaised => _palette.surfaceRaised; static Color get surfaceSoft => _palette.surfaceSoft; static Color get surfaceInput => _palette.surfaceInput; static Color get primary => _palette.primary; static Color get primaryBright => _palette.primaryBright; static Color get primarySoft => _palette.primarySoft; static Color get success => _palette.success; static Color get warning => _palette.warning; static Color get danger => _palette.danger; static Color get purple => _palette.purple; static Color get cyan => _palette.cyan; static Color get textPrimary => _palette.textPrimary; static Color get textSecondary => _palette.textSecondary; static Color get textMuted => _palette.textMuted; static Color get border => _palette.border; static Color get divider => _palette.divider; static Color get primaryGlow => _palette.primaryGlow; static Color get surfaceGlass => _palette.surfaceGlass; static Color get borderGlass => _palette.borderGlass;
}
class _UniCartPalette {
 final Color background, backgroundAlt, surface, surfaceRaised, surfaceSoft, surfaceInput, primary, primaryBright, primarySoft, success, warning, danger, purple, cyan, textPrimary, textSecondary, textMuted, border, divider, primaryGlow, surfaceGlass, borderGlass;
 const _UniCartPalette({required this.background, required this.backgroundAlt, required this.surface, required this.surfaceRaised, required this.surfaceSoft, required this.surfaceInput, required this.primary, required this.primaryBright, required this.primarySoft, required this.success, required this.warning, required this.danger, required this.purple, required this.cyan, required this.textPrimary, required this.textSecondary, required this.textMuted, required this.border, required this.divider, required this.primaryGlow, required this.surfaceGlass, required this.borderGlass});
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
    final colorScheme =  ColorScheme.dark(
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
        displaySmall:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineLarge:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge:  TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium:  TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
        labelLarge:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme:  AppBarTheme(
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
        hintStyle:  TextStyle(
          color: UniCartColors.textMuted,
          fontSize: 14,
        ),
        labelStyle:  TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle:  TextStyle(
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
          borderSide:  BorderSide(color: UniCartColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide:  BorderSide(color: UniCartColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide:  BorderSide(
            color: UniCartColors.primaryBright,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide:  BorderSide(color: UniCartColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.md),
          borderSide:  BorderSide(
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
          side:  BorderSide(color: UniCartColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UniCartRadius.xl),
          side:  BorderSide(color: UniCartColors.border),
        ),
        titleTextStyle:  TextStyle(
          color: UniCartColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle:  TextStyle(
          color: UniCartColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        contentTextStyle:  TextStyle(
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
      dividerTheme:  DividerThemeData(
        color: UniCartColors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme:  ProgressIndicatorThemeData(
        color: UniCartColors.primaryBright,
        linearTrackColor: UniCartColors.surfaceSoft,
        circularTrackColor: UniCartColors.surfaceSoft,
      ),
      iconTheme:  IconThemeData(color: UniCartColors.textSecondary),
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
          side:  BorderSide(color: UniCartColors.border),
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
      expansionTileTheme:  ExpansionTileThemeData(
        textColor: UniCartColors.textPrimary,
        collapsedTextColor: UniCartColors.textPrimary,
        iconColor: UniCartColors.textSecondary,
        collapsedIconColor: UniCartColors.textSecondary,
        shape: Border(),
        collapsedShape: Border(),
      ),
      bottomSheetTheme:  BottomSheetThemeData(
        backgroundColor: UniCartColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: UniCartColors.surfaceRaised,
        modalBarrierColor: Color(0x99000000),
      ),
    );
  }
}
