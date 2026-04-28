import 'package:flutter/material.dart';

/// GlassTask design tokens — pixel-faithful port of
/// `colors_and_type.css` and `ui_kits/todo_app/index.html`.
class AppTheme {
  AppTheme._();

  // ──────────────────────────────────────────────────────────────────
  // Accent palette (sRGB approximations of the OKLCH values)
  // ──────────────────────────────────────────────────────────────────
  /// `oklch(67% 0.18 260)` — primary accent
  static const Color accentBlue = Color(0xFF5E8FFF);

  /// `oklch(62% 0.20 260)` — used for active text / icon
  static const Color accentBlueDeep = Color(0xFF4F7FFF);

  /// `oklch(72% 0.16 295)` — secondary accent
  static const Color accentPurple = Color(0xFFA78BFA);

  /// `oklch(68% 0.18 295)` — used in tags
  static const Color accentPurpleDeep = Color(0xFF9D7AF5);

  /// `oklch(72% 0.14 200)` — harmony
  static const Color accentTeal = Color(0xFF60C8C0);

  /// `oklch(72% 0.16 330)` — harmony
  static const Color accentPink = Color(0xFFE490C8);

  // Status palette
  static const Color statusDone = Color(0xFF1FBE55); // oklch(64% 0.16 145)
  static const Color statusDoneDeep = Color(0xFF009E2F); // oklch(58% 0.18 145)
  static const Color statusActive = Color(0xFFF39A22); // oklch(72% 0.16 60)
  static const Color statusActiveDeep = Color(0xFFE87500); // oklch(68% 0.18 60)
  static const Color statusOverdue = Color(0xFFDC3C3C); // oklch(62% 0.20 25)
  static const Color statusOverdueDeep =
      Color(0xFFDA4634); // oklch(58% 0.22 25)
  static const Color statusSomeday = Color(0xFF8E94AB);

  // ──────────────────────────────────────────────────────────────────
  // Neutral scale
  // ──────────────────────────────────────────────────────────────────
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F8FC);
  static const Color neutral100 = Color(0xFFEEF0F6);
  static const Color neutral200 = Color(0xFFDDE1EC);
  static const Color neutral300 = Color(0xFFC4CAD8);
  static const Color neutral400 = Color(0xFF9AA3B8);
  static const Color neutral500 = Color(0xFF6E7891);
  static const Color neutral600 = Color(0xFF4E5669);
  static const Color neutral700 = Color(0xFF343B4F);
  static const Color neutral800 = Color(0xFF1E2332);
  static const Color neutral900 = Color(0xFF0E1120);

  // Foreground semantic
  static const Color fgPrimary = neutral900; // T.fg1
  static const Color fgSecondary = neutral600; // T.fg2
  static const Color fgTertiary = neutral400; // T.fg3
  static const Color fgDisabled = neutral300;
  static const Color fgInverse = neutral0;

  // ──────────────────────────────────────────────────────────────────
  // Canvas (page background gradient)
  // matches `linear-gradient(135deg, #c8d8f0 0%, #d8c8f0 40%, #c8e8f0 100%)`
  // ──────────────────────────────────────────────────────────────────
  static const List<Color> canvasGradient = [
    Color(0xFFC8D8F0),
    Color(0xFFD8C8F0),
    Color(0xFFC8E8F0),
  ];
  static const List<double> canvasStops = [0.0, 0.4, 1.0];

  // ──────────────────────────────────────────────────────────────────
  // Glass surface tokens
  // ──────────────────────────────────────────────────────────────────
  /// Sidebar shell surface — `rgba(255,255,255,0.30)`
  static const Color glassShellFill = Color(0x4DFFFFFF);
  static const double glassShellBlur = 40;

  /// Card / task item surface.
  ///
  /// The HTML prototype uses `rgba(255,255,255,0.58)`, but Flutter's
  /// macOS compositor reads thinner over the same pastel canvas. A denser
  /// fill keeps task surfaces legible without removing the glass effect.
  static const Color glassCardFill = Color(0xB3FFFFFF);
  static const double glassCardBlur = 24;

  /// Modal / sheet surface (T.glassBg) — `rgba(255,255,255,0.72)`
  static const Color glassModalFill = Color(0xB8FFFFFF);
  static const double glassModalBlur = 32;

  /// Menu / popup surface — `rgba(255,255,255,0.80)`
  static const Color glassMenuFill = Color(0xCCFFFFFF);
  static const double glassMenuBlur = 16;

  // Glass borders
  static const Color glassBorderLight = Color(0xB3FFFFFF); // 0.70
  static const Color glassBorderMedium = Color(0x73FFFFFF); // 0.45
  static const Color glassBorderStrong = Color(0x33FFFFFF); // 0.20

  // ──────────────────────────────────────────────────────────────────
  // Corner radii
  // ──────────────────────────────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  // ──────────────────────────────────────────────────────────────────
  // Spacing (4px grid)
  // ──────────────────────────────────────────────────────────────────
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 20;
  static const double sp6 = 24;
  static const double sp8 = 32;
  static const double sp10 = 40;
  static const double sp12 = 48;

  // ──────────────────────────────────────────────────────────────────
  // Shadows
  // ──────────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowElevated = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 60, offset: Offset(0, 20)),
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowFab = [
    BoxShadow(
      color: Color(0x6B5E8FFF), // rgba(94,143,255,0.42)
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> shadowWindow = [
    BoxShadow(color: Color(0x38000000), blurRadius: 80, offset: Offset(0, 32)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ──────────────────────────────────────────────────────────────────
  // Animation
  // ──────────────────────────────────────────────────────────────────
  static const Duration durMicro = Duration(milliseconds: 150);
  static const Duration durStd = Duration(milliseconds: 250);
  static const Duration durLayout = Duration(milliseconds: 400);
  static const Duration durModal = Duration(milliseconds: 600);

  static const Cubic easeStandard = Cubic(0.4, 0, 0.2, 1);
  static const Cubic easeSpring = Cubic(0.34, 1.56, 0.64, 1);
  static const Cubic easeExit = Cubic(0.4, 0, 1, 1);

  // ──────────────────────────────────────────────────────────────────
  // Typography helpers (Plus Jakarta Sans + Inter + JetBrains Mono)
  // Fonts are bundled locally in fonts/ — no network access required.
  // ──────────────────────────────────────────────────────────────────
  static TextStyle display({
    double size = 24,
    FontWeight weight = FontWeight.w700,
    Color color = fgPrimary,
    double? height,
    double letterSpacing = -0.6,
  }) =>
      TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = fgPrimary,
    double? height,
    double letterSpacing = -0.15,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = fgTertiary,
    double? height,
  }) =>
      TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle label({
    double size = 11,
    Color color = fgTertiary,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.7,
        height: 1.4,
      );

  // ──────────────────────────────────────────────────────────────────
  // ThemeData
  // ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      fontFamily: 'Inter',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Inter',
        bodyColor: fgPrimary,
        displayColor: fgPrimary,
      ),
    );
  }
}
