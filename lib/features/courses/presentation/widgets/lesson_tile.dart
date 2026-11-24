import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/course.dart';

/// One lesson row: number, title, duration, and status marks.
///
/// Used by course detail (plain) and lesson player (with [isActive]
/// left accent + equalizer mark, [isCompleted] check). Same widget =
/// same look on both screens.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.number,
    required this.lesson,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
  });

  final int number;
  final Lesson lesson;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : Colors.transparent,
        border: Border(
          // Left accent marks the lesson currently playing.
          left: BorderSide(
            width: 3,
            color: isActive ? AppColors.accent : Colors.transparent,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: _LeadingMark(
                    number: number,
                    isActive: isActive,
                    isCompleted: isCompleted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTypography.bodyStrong,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock3,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            DurationFormatter.clock(lesson.durationSeconds),
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingMark extends StatelessWidget {
  const _LeadingMark({
    required this.number,
    required this.isActive,
    required this.isCompleted,
  });

  final int number;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      // Equalizer-style mark for the lesson that is playing now.
      return const Icon(
        LucideIcons.activity,
        size: 18,
        color: AppColors.accent,
      );
    }
    if (isCompleted) {
      return const Icon(
        LucideIcons.checkCircle2,
        size: 18,
        color: AppColors.success,
      );
    }
    return Text('$number', style: AppTypography.caption);
  }
}
