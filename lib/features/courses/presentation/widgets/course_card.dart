import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/course.dart';
import 'level_badge.dart';

/// 16:9 thumbnail with a real placeholder and a graceful failure state
/// (never an empty gray rectangle, never a broken-image icon alone).
class CourseThumbnail extends StatelessWidget {
  const CourseThumbnail({super.key, required this.course, this.width});

  final Course course;

  /// Fixed width for list cards; null fills the parent (grid cards).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: course.thumbnailUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) =>
          const ColoredBox(color: AppColors.surfaceMuted),
      errorWidget: (context, url, error) => const ColoredBox(
        color: AppColors.surfaceMuted,
        child: Icon(
          LucideIcons.imageOff,
          size: 24,
          color: AppColors.textDisabled,
        ),
      ),
    );

    final framed = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: image,
    );

    // Screen readers get a human description instead of a bare image.
    return Semantics(
      label: 'Foto kelas ${course.title}',
      image: true,
      excludeSemantics: true,
      child: width == null
          ? AspectRatio(aspectRatio: 16 / 9, child: framed)
          : SizedBox(
              width: width,
              child: AspectRatio(aspectRatio: 16 / 9, child: framed),
            ),
    );
  }
}

/// Course card for phones: thumbnail left, dense info right.
/// Shows title (2 lines max), instructor, level, lessons, duration.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseThumbnail(course: course, width: 120),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _CourseInfo(course: course)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Course card for tablets/landscape: thumbnail on top, info below.
class CourseGridCard extends StatelessWidget {
  const CourseGridCard({super.key, required this.course, this.onTap});

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CourseThumbnail(course: course),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _CourseInfo(course: course),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared text block so list and grid cards cannot drift apart.
class _CourseInfo extends StatelessWidget {
  const _CourseInfo({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: AppTypography.titleS,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          course.instructor,
          style: AppTypography.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Wrap keeps the meta row from overflowing at 1.3x text scale.
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LevelBadge(level: course.level),
            _MetaText(
              icon: LucideIcons.listVideo,
              text: '${course.totalLessons} pelajaran',
            ),
            _MetaText(
              icon: LucideIcons.clock3,
              text: DurationFormatter.human(course.totalDurationSeconds),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        // Flexible: the text wraps inside the width the Row has left
        // (a bare child would get the full width and overflow the Row).
        Flexible(child: Text(text, style: AppTypography.caption)),
      ],
    );
  }
}
