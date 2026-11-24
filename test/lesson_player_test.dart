import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:test_developer/core/error/failure.dart';
import 'package:test_developer/features/courses/data/course_providers.dart';
import 'package:test_developer/features/courses/domain/entities/course.dart';
import 'package:test_developer/features/courses/presentation/widgets/lesson_tile.dart';
import 'package:test_developer/features/lesson_player/presentation/pages/lesson_player_page.dart';
import 'package:test_developer/features/lesson_player/presentation/widgets/lesson_player_skeleton.dart';
import 'package:test_developer/features/lesson_player/presentation/widgets/player_controls.dart';
import 'package:test_developer/features/lesson_player/presentation/widgets/video_area.dart';

import 'helpers/fake_course_repository.dart';
import 'helpers/fake_video_player_platform.dart';

/// Hosts [home] with the repository override.
Widget _host(Widget home, FakeCourseRepository repo) {
  return ProviderScope(
    overrides: [courseRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
  );
}

void _setSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _page(String lessonId) =>
    LessonPlayerPage(courseId: 'c-1', lessonId: lessonId);

/// Lets pending player disposal finish.
///
/// `VideoPlayerController.dispose()` awaits `subscription.cancel()`,
/// whose future resolves in the root zone. The fake-async test zone
/// does not flush root-zone microtasks, so assertions on
/// [FakeVideoPlayerPlatform.disposed] need one real event-loop turn.
Future<void> _flushDisposal(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  // Fonts must not hit the network inside tests.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeVideoPlayerPlatform fake;

  setUp(() {
    fake = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fake;
  });

  group('LessonPlayerPage states', () {
    testWidgets('loading shows the player skeleton, no video yet', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Completer<CourseDetail>().future,
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pump();

      expect(find.byType(LessonPlayerSkeleton), findsOneWidget);
      expect(find.byKey(const Key('fake-video-surface')), findsNothing);
    });

    testWidgets('offline detail shows its own message and retry refetches', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailError: const Failure(
          type: FailureType.offline,
          message: 'Tidak ada internet. Periksa jaringan Anda lalu coba lagi.',
        ),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tidak ada internet'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      repo.detailError = null;
      repo.detailFuture = Future.value(sampleDetail());
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.detailCalls, 2);
      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
    });

    testWidgets('unknown lesson shows a message and no player', (tester) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-x'), repo));
      await tester.pumpAndSettle();

      expect(find.text('Pelajaran tidak ditemukan.'), findsOneWidget);
      expect(find.byKey(const Key('fake-video-surface')), findsNothing);
      expect(find.byType(VideoPlayer), findsNothing);
    });

    testWidgets('data shows video, counter, prev/next and lesson list', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
      expect(find.text('Pelajaran 1 dari 2 · 12:00'), findsOneWidget);
      expect(find.byType(LessonTile), findsNWidgets(2));
      expect(find.text('Sebelumnya'), findsOneWidget);
      expect(find.text('Berikutnya'), findsOneWidget);

      // First lesson: nothing before it, so the button is disabled.
      final previous = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sebelumnya'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(previous.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow on 360dp at 1.3x text scale', (tester) async {
      _setSize(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      // A RenderFlex overflow would be reported and fail the test.
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape at 1.3x text scale does not overflow', (
      tester,
    ) async {
      _setSize(tester, 640, 360);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LessonPlayerPage video states', () {
    testWidgets('invalid video URL degrades to a clear error, no controller', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail(secondVideoUrl: 'not-a-url')),
      );
      await tester.pumpWidget(_host(_page('l-2'), repo));
      await tester.pumpAndSettle();

      expect(find.text('Tautan video tidak valid.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      // Nothing was created, so nothing can ever play by accident.
      expect(fake.created, isEmpty);
    });

    testWidgets('failed video load shows a message and retry rebuilds it', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      fake.failWith = 'Video cannot be played';
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Video tidak dapat diputar'), findsOneWidget);
      expect(fake.created.length, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
      expect(fake.created.length, 2);
      await _flushDisposal(tester);
      // The broken controller was released, not left running.
      expect(fake.disposed, [0]);
    });

    testWidgets('connection lost during playback shows a recoverable error', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      fake.emitConnectionLost(0);
      await tester.pumpAndSettle();

      expect(find.textContaining('Video terhenti'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-video-surface')), findsOneWidget);
      await _flushDisposal(tester);
      expect(fake.disposed, [0]);
    });
  });

  group('LessonPlayerPage controls and lifecycle', () {
    testWidgets('tap toggles controls; play and pause reach the platform', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerControls), findsOneWidget);
      expect(find.byTooltip('Putar'), findsOneWidget);

      await tester.tap(find.byTooltip('Putar'));
      await tester.pump();
      expect(fake.played, isNotEmpty);

      // Bounded pumps only: a playing controller ticks every 100ms, so
      // pumpAndSettle would keep finding new frames to draw.
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byTooltip('Jeda'), findsOneWidget);

      await tester.tap(find.byTooltip('Jeda'));
      await tester.pumpAndSettle();
      expect(fake.paused, isNotEmpty);

      // Tapping the video itself hides the controls, tapping again
      // brings them back (no auto-hide timer).
      final area = tester.getRect(find.byKey(const Key('video-tap-area')));
      final spot = Offset(area.left + 8, area.center.dy);

      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerControls), findsNothing);

      await tester.tapAt(spot);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerControls), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sending the app to the background pauses the video', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Putar'));
      await tester.pump();
      expect(fake.played, isNotEmpty);
      final pausesBefore = fake.paused.length;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(fake.paused.length, greaterThan(pausesBefore));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    });
  });

  group('LessonPlayerPage navigation', () {
    testWidgets('switching lesson disposes the old player, never two at once', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final lessons = sampleDetail().lessons;

      Widget stage(Lesson lesson) => MaterialApp(
        home: Scaffold(
          body: AspectRatio(
            aspectRatio: 16 / 9,
            child: VideoArea(
              // Keyed by lesson, exactly like the real page does.
              key: ValueKey(lesson.id),
              lesson: lesson,
              isActive: true,
              isFullscreen: false,
              onToggleFullscreen: () {},
            ),
          ),
        ),
      );

      await tester.pumpWidget(stage(lessons[0]));
      await tester.pumpAndSettle();
      expect(fake.created.length, 1);

      await tester.tap(find.byTooltip('Putar'));
      await tester.pump();
      expect(fake.played, isNotEmpty);
      final pausesBefore = fake.paused.length;

      await tester.pumpWidget(stage(lessons[1]));
      await tester.pumpAndSettle();
      await _flushDisposal(tester);

      // Old platform player released, new one created, and the old one
      // was paused before release: exactly one video can be alive.
      expect(fake.disposed, [0]);
      expect(fake.created.length, 2);
      expect(fake.paused.length, greaterThan(pausesBefore));
    });

    testWidgets('double tap on a lesson switches exactly once', (tester) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      final router = GoRouter(
        initialLocation: '/courses/c-1/lessons/l-1',
        routes: [
          GoRoute(
            path: '/courses/:courseId/lessons/:lessonId',
            builder: (context, state) => LessonPlayerPage(
              courseId: state.pathParameters['courseId']!,
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [courseRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(fake.created.length, 1);

      final target = find.text('Widget dasar');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      final targetCount = tester.widgetList(find.text('Widget dasar')).length;
      expect(targetCount, 1);

      // Two taps with no frame in between: the guard must swallow the
      // second one instead of stacking a third player.
      await tester.tap(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await _flushDisposal(tester);

      expect(fake.created.length, 2);
      expect(fake.disposed, [0]);
      expect(find.text('Pelajaran 2 dari 2 · 11:00'), findsOneWidget);
    });

    testWidgets('fullscreen locks landscape and dispose restores it', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Layar penuh'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Sebelumnya'), findsNothing);
      expect(find.byTooltip('Keluar dari layar penuh'), findsOneWidget);
      // The same controller survived the layout swap: fullscreen must
      // not restart the video from zero.
      expect(fake.created.length, 1);
      expect(
        calls.any(
          (call) => call.method == 'SystemChrome.setPreferredOrientations',
        ),
        isTrue,
      );

      await tester.tap(find.byTooltip('Keluar dari layar penuh'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);

      // Re-enter fullscreen, then unmount: the device must not stay
      // locked in landscape after the player closes.
      await tester.tap(find.byTooltip('Layar penuh'));
      await tester.pumpAndSettle();
      calls.clear();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      final orientations = calls
          .where(
            (call) => call.method == 'SystemChrome.setPreferredOrientations',
          )
          .toList();
      expect(orientations, isNotEmpty);
      // DeviceOrientation.toString() is "DeviceOrientation.portraitUp".
      expect(
        (orientations.last.arguments as List)
            .map((argument) => argument.toString())
            .any((argument) => argument.endsWith('portraitUp')),
        isTrue,
      );
    });

    testWidgets('dedicated exit control leaves fullscreen', (tester) async {
      _setSize(tester, 360, 640);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await tester.pumpWidget(_host(_page('l-1'), repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Layar penuh'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Keluar layar penuh'), findsOneWidget);

      await tester.tap(find.byTooltip('Keluar layar penuh'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byTooltip('Keluar layar penuh'), findsNothing);
    });
  });
}
