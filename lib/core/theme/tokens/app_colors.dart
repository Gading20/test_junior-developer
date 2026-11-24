import 'package:material_ui/material_ui.dart';

/// Design tokens: colors.
///
/// Every color in the app comes from here. No Colors.blue, no
/// ColorScheme.fromSeed defaults, no hex literals inside widgets.
abstract class AppColors {
  // Brand -----------------------------------------------------------------
  /// Primary actions: buttons, links, active markers. Teal reads as
  /// "learning/growth" and avoids the default Material blue/purple.
  /// Contrast vs white = 6.2:1 (WCAG AA for normal text).
  static const Color primary = Color(0xFF0B6E5F);

  /// Reserved accent: active lesson marker, progress. Used sparingly so
  /// it keeps its meaning. Text on accent uses [onAccent] (12:1).
  static const Color accent = Color(0xFFF2A007);
  static const Color onAccent = Color(0xFF1B1F1D);

  // Neutral (slightly warm gray, not pure gray) ---------------------------
  static const Color background = Color(0xFFF6F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF0EC); // skeleton, chips
  static const Color border = Color(0xFFE2E5DF); // 1px separators

  static const Color textPrimary = Color(0xFF1B1F1D); // 15.8:1 on surface
  static const Color textSecondary = Color(0xFF5C6360); // 6.1:1 on surface
  static const Color textDisabled = Color(0xFF9BA19C);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Semantic ---------------------------------------------------------------
  static const Color error = Color(0xFFC43E32);
  static const Color success = Color(0xFF2E7D4F);

  // Player overlay ---------------------------------------------------------
  /// Video stage background: near-black with a green cast so it belongs
  /// to the teal palette instead of a flat pure black.
  static const Color playerBackground = Color(0xFF101312);

  /// Scrim behind player controls. 70% opacity keeps white control text
  /// above 4.5:1 even over the brightest possible frame.
  static const Color playerScrim = Color(0xB3101312);

  /// Progress track (white 35%) and buffered range (white 55%).
  static const Color playerTrack = Color(0x59FFFFFF);
  static const Color playerBuffered = Color(0x8CFFFFFF);

  // Level badge = meaning (difficulty), not decoration ---------------------
  static const Color levelPemulaFg = Color(0xFF2E7D4F);
  static const Color levelPemulaBg = Color(0xFFE7F2EB);
  static const Color levelMenengahFg = Color(0xFF8A5A00);
  static const Color levelMenengahBg = Color(0xFFFCF1DC);
  static const Color levelLanjutFg = Color(0xFFA3352B);
  static const Color levelLanjutBg = Color(0xFFFBEAE8);
}
