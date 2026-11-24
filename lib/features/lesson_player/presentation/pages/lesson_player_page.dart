import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/presentation/providers/course_providers.dart';
import '../../../courses/presentation/widgets/lesson_tile.dart';
import '../lesson_navigation.dart';
import '../widgets/lesson_player_skeleton.dart';
import '../widgets/video_area.dart';

/// Video lesson screen: player, lesson metadata, prev/next navigation
/// and the full lesson list of the course.
///
/// Owns navigation-level state only (open lesson, fullscreen, whether a
/// switch is in flight). The player itself lives in [VideoArea], so it
/// is disposed exactly once when this route goes away.
class LessonPlayerPage extends ConsumerStatefulWidget {
  const LessonPlayerPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends ConsumerState<LessonPlayerPage> {
  /// Blocks further taps until the replacement lesson is mounted.
  bool _switching = false;

  bool _isFullscreen = false;

  /// GlobalKey keeps the player element alive across the portrait <->
  /// fullscreen layout swap. The two layouts put [VideoArea] under
  /// different parents, so a normal key would tear the subtree down and
  /// restart the video from zero every time fullscreen is toggled; a
  /// GlobalKey makes Flutter move the same element (and its controller)
  /// instead of recreating it.
  GlobalKey _videoKey = GlobalKey(debugLabel: 'lesson-video');

  @override
  void didUpdateWidget(covariant LessonPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.lessonId != widget.lessonId) {
      // A router may update this State in place for the same route pattern.
      // Give the new lesson its own player and release the previous one.
      _videoKey = GlobalKey(debugLabel: 'lesson-video');
      _switching = false;
    }
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      // Never leave the device stuck in landscape after the player goes.
      unawaited(
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
      );
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  Future<void> _setFullscreen(bool value) async {
    if (value == _isFullscreen) return;
    if (value) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (!mounted) return;
    setState(() => _isFullscreen = value);
  }

  void _toggleFullscreen() => unawaited(_setFullscreen(!_isFullscreen));

  /// Replaces this route with another lesson of the same course.
  ///
  /// [pushReplacement] instead of [push]: stacking players would leave
  /// two routes (and potentially two videos) alive under each other.
  void _goTo(String lessonId) {
    if (_switching || lessonId == widget.lessonId) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    // Flag first: the outgoing page lives through the transition and
    // VideoArea sees isActive=false, so it pauses before the next
    // lesson can start.
    setState(() => _switching = true);
    context.pushReplacement(AppRoutes.lessonPlayer(widget.courseId, lessonId));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));

    return PopScope<Object?>(
      // Hardware back leaves fullscreen first, instead of leaving the lesson.
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_setFullscreen(false));
      },
      child: Scaffold(
        appBar: _isFullscreen ? null : AppBar(title: _title(detailAsync)),
        body: detailAsync.when(
          // The skeleton is already a ListView: wrapping it in another
          // one nests two viewports and crashes layout.
          loading: () => const LessonPlayerSkeleton(),
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
          data: (detail) =>
              _isFullscreen ? _videoOnly(detail) : _scrollable(context, detail),
        ),
      ),
    );
  }

  Widget _title(AsyncValue<CourseDetail> detailAsync) {
    final lesson = detailAsync.hasValue
        ? detailAsync.requireValue.lessonById(widget.lessonId)
        : null;
    if (lesson != null) {
      return Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return const Text('Pelajaran');
  }

  /// Fullscreen shows the video and nothing else: no AppBar, no list,
  /// no metadata — the frame belongs to the lesson.
  Widget _videoOnly(CourseDetail detail) {
    final lesson = detail.lessonById(widget.lessonId);
    if (lesson == null) return _notFound();
    // The YouTube WebView is a native platform view and can paint over
    // Flutter overlays. Reserve a strip outside it so the exit control
    // stays visible and tappable.
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: IconButton.filled(
                tooltip: 'Keluar layar penuh',
                onPressed: () => unawaited(_setFullscreen(false)),
                icon: const Icon(LucideIcons.minimize),
              ),
            ),
          ),
        ),
        Expanded(
          child: _stage(
            lesson,
            lessons: detail.lessons,
            isFullscreen: true,
            onBack: () => unawaited(_setFullscreen(false)),
          ),
        ),
      ],
    );
  }

  Widget _scrollable(BuildContext context, CourseDetail detail) {
    final lessons = detail.lessons;
    if (lessons.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          StateView(
            icon: LucideIcons.listVideo,
            message: 'Kelas ini belum punya pelajaran.',
          ),
        ],
      );
    }
    final lesson = detail.lessonById(widget.lessonId);
    if (lesson == null) return _notFound();
    final index = lessons.indexOf(lesson) + 1;

    return ListView(
      key: ValueKey('${widget.courseId}/${widget.lessonId}'),
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _stage(lesson, lessons: lessons, isFullscreen: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.course.title,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(lesson.title, style: AppTypography.titleL),
              const SizedBox(height: AppSpacing.sm),
              if (lesson.videoUrl.contains('youtube.com/watch'))
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final opened = await launchUrl(
                            Uri.parse(lesson.videoUrl),
                            mode: LaunchMode.externalApplication,
                          );
                          if (opened) return;
                        } catch (_) {
                          // Report failures without exposing platform errors.
                        }
                        if (!mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tidak dapat membuka YouTube. Coba lagi.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.externalLink),
                      label: const Text('Buka di YouTube'),
                    ),
                    TextButton.icon(
                      onPressed: _toggleFullscreen,
                      icon: const Icon(LucideIcons.maximize),
                      label: const Text('Layar penuh'),
                    ),
                  ],
                ),
              Text(
                'Pelajaran $index dari ${lessons.length} · '
                '${DurationFormatter.clock(lesson.durationSeconds)}',
                style: AppTypography.caption,
              ),
              if (lesson.description.isNotEmpty) ...[
                const SectionHeader(title: 'Tentang pelajaran'),
                Text(lesson.description, style: AppTypography.body),
              ],
              const SizedBox(height: AppSpacing.lg),
              _PrevNextButtons(
                previous: LessonNavigation.before(lessons, lesson.id),
                next: LessonNavigation.after(lessons, lesson.id),
                onPrevious: () =>
                    _goTo(LessonNavigation.before(lessons, lesson.id)!.id),
                onNext: () =>
                    _goTo(LessonNavigation.after(lessons, lesson.id)!.id),
              ),
              const Divider(),
              SectionHeader(
                title: 'Daftar pelajaran',
                trailing: '${lessons.length} pelajaran',
              ),
              for (var position = 0; position < lessons.length; position++) ...[
                LessonTile(
                  number: position + 1,
                  lesson: lessons[position],
                  isActive: lessons[position].id == lesson.id,
                  onTap: () => _goTo(lessons[position].id),
                ),
                const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stage(
    Lesson lesson, {
    required List<Lesson> lessons,
    required bool isFullscreen,
    VoidCallback? onBack,
  }) {
    final previous = LessonNavigation.before(lessons, lesson.id);
    final next = LessonNavigation.after(lessons, lesson.id);
    final area = VideoArea(
      // Preserve the player across fullscreen layout changes. Rotate
      // this key when the router updates the lesson in the same State.
      key: _videoKey,
      lesson: lesson,
      isActive: !_switching,
      isFullscreen: isFullscreen,
      onBack: onBack,
      onToggleFullscreen: _toggleFullscreen,
      onPrevious: previous == null ? null : () => _goTo(previous.id),
      onNext: next == null ? null : () => _goTo(next.id),
    );
    if (isFullscreen) return area;
    return AspectRatio(aspectRatio: 16 / 9, child: area);
  }

  Widget _notFound() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        StateView(
          icon: LucideIcons.searchX,
          message: 'Pelajaran tidak ditemukan.',
        ),
      ],
    );
  }

  static Failure _asFailure(Object error) => error is Failure
      ? error
      : const Failure(
          type: FailureType.unknown,
          message: 'Terjadi kesalahan. Coba lagi.',
        );
}

/// Prev/next navigation under the video. Text buttons instead of bare
/// chevrons: the labels state what happens, and both stay readable at
/// 1.3x text scale inside a 360dp screen.
class _PrevNextButtons extends StatelessWidget {
  const _PrevNextButtons({
    required this.previous,
    required this.next,
    required this.onPrevious,
    required this.onNext,
  });

  final Lesson? previous;
  final Lesson? next;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      // No CrossAxisAlignment.stretch here: inside a ListView the row's
      // height is unbounded, and stretch would force an infinite
      // height onto the buttons. Both labels are single-line, so the
      // default center alignment keeps them equal height anyway.
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: previous == null ? null : onPrevious,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text('Sebelumnya'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton(
            onPressed: next == null ? null : onNext,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text('Berikutnya'),
          ),
        ),
      ],
    );
  }
}
