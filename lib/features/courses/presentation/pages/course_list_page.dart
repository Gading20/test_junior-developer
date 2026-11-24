import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/state_view.dart';
import '../../domain/entities/course.dart';
import '../providers/course_providers.dart';
import '../widgets/course_card.dart';
import '../widgets/skeletons.dart';

/// Course list screen.
///
/// States: loading (skeleton shaped like real cards), empty, error and
/// offline (StateView with retry). All states sit in a scroll view with
/// AlwaysScrollableScrollPhysics so pull-to-refresh works everywhere.
/// Scroll position survives a detail visit: go_router keeps this route
/// alive in the navigation stack, so popping back restores the offset.
class CourseListPage extends ConsumerWidget {
  const CourseListPage({super.key});

  /// Phones: compact horizontal cards. Tablet/landscape: 2-3 column grid.
  static const double _wideBreakpoint = 720;
  static const double _gridBreakpointForThirdColumn = 1080;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(courseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas'),
        // Pull-to-refresh is hard to discover with a mouse (tablet/
        // emulator), so the same action also lives in the app bar.
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(courseListProvider),
            tooltip: 'Muat ulang daftar kelas',
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(courseListProvider);
              await ref.read(courseListProvider.future);
            },
            child: coursesAsync.when(
              loading: () => _scrollable(_loadingSlivers(maxWidth)),
              error: (error, _) => _scrollable([
                SliverToBoxAdapter(
                  child: StateView.failure(
                    _asFailure(error),
                    onRetry: () => ref.invalidate(courseListProvider),
                  ),
                ),
              ]),
              data: (courses) => _scrollable(
                _dataSlivers(
                  context,
                  ref: ref,
                  courses: courses,
                  maxWidth: maxWidth,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scrollable(List<Widget> slivers) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );
  }

  List<Widget> _dataSlivers(
    BuildContext context, {
    required WidgetRef ref,
    required List<Course> courses,
    required double maxWidth,
  }) {
    if (courses.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: StateView(
            icon: LucideIcons.library,
            message: 'Belum ada kelas yang tersedia saat ini.',
            // Pull-to-refresh is invisible here, so offer an explicit action.
            actionLabel: 'Muat ulang',
            onAction: () => ref.invalidate(courseListProvider),
          ),
        ),
      ];
    }

    final totalSeconds = courses.fold<int>(
      0,
      (sum, course) => sum + course.totalDurationSeconds,
    );

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            '${courses.length} kelas · ${DurationFormatter.human(totalSeconds)}',
            style: AppTypography.caption,
          ),
        ),
      ),
      if (maxWidth >= _wideBreakpoint)
        _grid(courses, maxWidth)
      else
        _list(courses),
    ];
  }

  Widget _list(List<Course> courses) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CourseCard(
              course: courses[index],
              onTap: () =>
                  pushOnce(context, AppRoutes.courseDetail(courses[index].id)),
            ),
          ),
          childCount: courses.length,
        ),
      ),
    );
  }

  Widget _grid(List<Course> courses, double maxWidth) {
    final crossAxisCount = maxWidth >= _gridBreakpointForThirdColumn ? 3 : 2;
    const spacing = AppSpacing.lg;
    const horizontalPadding = AppSpacing.lg * 2;
    final columnWidth =
        (maxWidth - horizontalPadding) - spacing * (crossAxisCount - 1);
    // Image (16:9 of a column) plus the text block below it; extra
    // room keeps two title lines from clipping at 1.3x text scale.
    final cardExtent = (columnWidth / crossAxisCount) * 9 / 16 + 170;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: cardExtent,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => CourseGridCard(
            course: courses[index],
            onTap: () =>
                pushOnce(context, AppRoutes.courseDetail(courses[index].id)),
          ),
          childCount: courses.length,
        ),
      ),
    );
  }

  List<Widget> _loadingSlivers(double maxWidth) {
    if (maxWidth >= _wideBreakpoint) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 320,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const CourseGridCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: CourseCardSkeleton(),
            ),
            childCount: 5,
          ),
        ),
      ),
    ];
  }

  /// Repository guarantees Failure; anything else (a bug) still needs a
  /// message the user can read, so it becomes an unknown failure.
  static Failure _asFailure(Object error) => error is Failure
      ? error
      : const Failure(
          type: FailureType.unknown,
          message: 'Terjadi kesalahan. Coba lagi.',
        );
}
