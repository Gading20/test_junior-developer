import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../domain/entities/course.dart';

/// Difficulty chip. The color carries meaning (green = beginner,
/// amber = intermediate, red = advanced) — never decoration.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final Level level;

  Color get _foreground => switch (level) {
    Level.pemula => AppColors.levelPemulaFg,
    Level.menengah => AppColors.levelMenengahFg,
    Level.lanjut => AppColors.levelLanjutFg,
  };

  Color get _background => switch (level) {
    Level.pemula => AppColors.levelPemulaBg,
    Level.menengah => AppColors.levelMenengahBg,
    Level.lanjut => AppColors.levelLanjutBg,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        level.label.toUpperCase(),
        style: AppTypography.label.copyWith(color: _foreground),
      ),
    );
  }
}
