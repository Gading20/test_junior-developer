import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:test_developer/core/error/failure.dart';
import 'package:test_developer/features/courses/data/course_providers.dart';
import 'package:test_developer/features/courses/domain/entities/course.dart';
import 'package:test_developer/features/courses/presentation/pages/course_detail_page.dart';
import 'package:test_developer/features/courses/presentation/pages/course_list_page.dart';
import 'package:test_developer/features/courses/presentation/widgets/course_card.dart';
import 'package:test_developer/features/courses/presentation/widgets/lesson_tile.dart';
import 'package:test_developer/features/courses/presentation/widgets/skeletons.dart';

import 'helpers/fake_course_repository.dart';

/// Hosts [home] with the repository override.
Widget _host(Widget home, FakeCourseRepository repo) {
  return ProviderScope(
    overrides: [courseRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
  );
}

void _setSize(
  WidgetTester tester,
  double width,
  double height, {
  double textScale = 1.0,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  // Text scale goes through the platform dispatcher, which is what the
  // app's MediaQuery is built from (a MediaQuery wrapper above
  // MaterialApp would not survive inside WidgetsApp).
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  // Fonts must not hit the network inside tests.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('CourseListPage', () {
    testWidgets('loading shows skeleton shaped like the real cards', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        pendingList: Completer<List<Course>>().future,
      );
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pump();
        expect(find.byType(CourseCardSkeleton), findsWidgets);
      });
    });

    testWidgets('data shows cards and header count', (tester) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(courses: [sampleCourse()]);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pumpAndSettle();
        expect(find.text('1 kelas · 1 j 51 m'), findsOneWidget);
        expect(find.byType(CourseCard), findsOneWidget);
      });
    });

    testWidgets('no overflow on 360dp at 1.3x text scale', (tester) async {
      _setSize(tester, 360, 640, textScale: 1.3);
      final repo = FakeCourseRepository(courses: [sampleCourse()]);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pumpAndSettle();
        // A RenderFlex overflow would be reported and fail the test.
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('tablet width uses grid cards', (tester) async {
      _setSize(tester, 1024, 768);
      final repo = FakeCourseRepository(courses: [sampleCourse()]);
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pumpAndSettle();
        expect(find.byType(CourseGridCard), findsOneWidget);
      });
    });

    testWidgets('offline failure shows specific message and retry', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        listError: const Failure(
          type: FailureType.offline,
          message: 'Tidak ada internet. Periksa jaringan Anda lalu coba lagi.',
        ),
      );
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pumpAndSettle();
        expect(find.textContaining('Tidak ada internet'), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);

        // Retry refetches: repository gets a second call.
        repo.listError = null;
        repo.courses = [sampleCourse()];
        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();
        expect(repo.listCalls, 2);
        expect(find.byType(CourseCard), findsOneWidget);
      });
    });

    testWidgets('empty list shows empty message without retry', (tester) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository();
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(_host(const CourseListPage(), repo));
        await tester.pumpAndSettle();
        expect(
          find.text('Belum ada kelas yang tersedia saat ini.'),
          findsOneWidget,
        );
        expect(find.text('Muat ulang'), findsOneWidget);
      });
    });
  });

  group('CourseDetailPage', () {
    testWidgets('shows lessons, metadata, and sticky start button', (
      tester,
    ) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          _host(const CourseDetailPage(courseId: 'c-1'), repo),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LessonTile), findsNWidgets(2));
        expect(find.text('Memasang Flutter dan VS Code'), findsOneWidget);
        expect(find.text('Mulai Belajar'), findsOneWidget);
        expect(find.text('Selengkapnya'), findsOneWidget);
      });
    });

    testWidgets('no overflow on detail at 1.3x text scale', (tester) async {
      _setSize(tester, 360, 640, textScale: 1.3);
      final repo = FakeCourseRepository(
        detailFuture: Future.value(sampleDetail()),
      );
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          _host(const CourseDetailPage(courseId: 'c-1'), repo),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('not found shows message without retry button', (tester) async {
      _setSize(tester, 360, 640);
      final repo = FakeCourseRepository();
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          _host(const CourseDetailPage(courseId: 'c-x'), repo),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kelas tidak ditemukan.'), findsOneWidget);
        expect(find.text('Coba lagi'), findsNothing);
      });
    });
  });
}
