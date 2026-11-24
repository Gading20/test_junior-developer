import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Design tokens: typography.
///
/// One family (Plus Jakarta Sans, loaded via google_fonts) — it was
/// designed for Jakarta's city identity, so it suits Indonesian copy
/// and does not look like the stock Roboto/Inter default.
/// Scale: 24 / 18 / 16 / 14 / 12 / 11 with explicit line heights.
abstract class AppTypography {
  static const String family = 'Plus Jakarta Sans';

  /// Screen and section titles.
  static const TextStyle titleL = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleM = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleS = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Uppercase metadata labels (e.g. "PEMULA").
  static const TextStyle label = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );
}
