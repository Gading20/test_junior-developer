import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens/app_colors.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_view.dart';
import '../../domain/entities/course.dart';
import '../providers/course_providers.dart';
import '../widgets/course_card.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/level_badge.dart';
import '../widgets/skeletons.dart';

class CourseDetailPage extends ConsumerStatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<CourseDetailPage> createState() => _CourseDetailPageState();
}

/// Course detail: thumbnail, metadata, expandable description, numbered
/// lesson list, and a sticky primary action.
class _CourseDetailPageState extends ConsumerState<CourseDetailPage> {
  /// "Selengkapnya" toggle. Local view state, not application data, so a
  /// plain bool in State beats a provider here.
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      // While loading the placeholder title stays; once data arrives the
      // bar shows the course name, which orients the user better than a
      // generic "Detail kelas".
      appBar: AppBar(
        title: detailAsync.hasValue
            ? Text(
                detailAsync.requireValue.course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Detail kelas'),
      ),
      body: detailAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [CourseDetailSkeleton()],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            StateView.failure(
              _asFailure(error),
              onRetry: () =>
                  ref.invalidate(courseDetailProvider(widget.courseId)),
            ),
          ],
        ),
        data: (detail) => _content(context, detail),
      ),
      // Sticky action exists only once the course (and its lessons) loaded.
      bottomNavigationBar: detailAsync.hasValue
          ? _stickyStartButton(detailAsync.requireValue)
          : null,
    );
  }

  Widget _content(BuildContext context, CourseDetail detail) {
    final course = detail.course;
    final lessons = detail.lessons;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CourseThumbnail(course: course),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: AppTypography.titleL),
              const SizedBox(height: AppSpacing.md),
              // Wrap instead of one rigid row: survives 1.3x text scale.
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaText(icon: LucideIcons.users, text: course.instructor),
                  _MetaText(
                    icon: LucideIcons.listVideo,
                    text: '${course.totalLessons} pelajaran',
                  ),
                  _MetaText(
                    icon: LucideIcons.clock3,
                    text: DurationFormatter.human(course.totalDurationSeconds),
                  ),
                  LevelBadge(level: course.level),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Tentang kelas'),
              Text(
                course.description,
                style: AppTypography.body,
                maxLines: _descriptionExpanded ? null : 3,
                overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
              ),
              if (course.description.length > 120)
                TextButton(
                  onPressed: () => setState(
                    () => _descriptionExpanded = !_descriptionExpanded,
                  ),
                  child: Text(_descriptionExpanded ? 'Tutup' : 'Selengkapnya'),
                ),
              const Divider(),
              SectionHeader(
                title: 'Daftar pelajaran',
                trailing: '${lessons.length} pelajaran',
              ),
              if (lessons.isEmpty)
                const StateView(
                  icon: LucideIcons.listVideo,
                  message: 'Kelas ini belum punya pelajaran.',
                )
              else
                for (var index = 0; index < lessons.length; index++) ...[
                  LessonTile(
                    number: index + 1,
                    lesson: lessons[index],
                    onTap: () => pushOnce(
                      context,
                      AppRoutes.lessonPlayer(
                        widget.courseId,
                        lessons[index].id,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
              // Clearance so the last lesson clears the sticky button.
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stickyStartButton(CourseDetail detail) {
    final canStart = detail.lessons.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: canStart
              ? () => pushOnce(
                  context,
                  AppRoutes.lessonPlayer(
                    widget.courseId,
                    detail.lessons.first.id,
                  ),
                )
              : null,
          child: const Text('Mulai Belajar'),
        ),
      ),
    );
  }

  static Failure _asFailure(Object error) => error is Failure
      ? error
      : const Failure(
          type: FailureType.unknown,
          message: 'Terjadi kesalahan. Coba lagi.',
        );
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
        Flexible(child: Text(text, style: AppTypography.caption)),
      ],
    );
  }
}
