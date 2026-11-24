import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/courses/presentation/pages/course_detail_page.dart';
import '../../features/courses/presentation/pages/course_list_page.dart';
import '../../features/lesson_player/presentation/pages/lesson_player_page.dart';

/// Navigation graph.
///
/// Paths are built through [AppRoutes] helpers so no screen hardcodes
/// a URL string — renaming a route happens in one file only.
abstract class AppRoutes {
  static const String courses = '/';

  static String courseDetail(String courseId) => '/courses/$courseId';

  static String lessonPlayer(String courseId, String lessonId) =>
      '/courses/$courseId/lessons/$lessonId';
}

/// Pushes [location] once, ignoring taps fired while an earlier push is
/// still animating. Prevents double-navigated pages when the user taps
/// a card or lesson twice quickly.
void pushOnce(BuildContext context, String location) {
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return;
  context.push(location);
}

/// Provider so the router can be overridden/swapped in tests.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.courses,
    routes: [
      GoRoute(
        path: AppRoutes.courses,
        name: 'courses',
        builder: (context, state) => const CourseListPage(),
      ),
      GoRoute(
        path: '/courses/:courseId',
        name: 'course-detail',
        builder: (context, state) =>
            CourseDetailPage(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/courses/:courseId/lessons/:lessonId',
        name: 'lesson-player',
        builder: (context, state) => LessonPlayerPage(
          courseId: state.pathParameters['courseId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
    ],
    // Unknown route (e.g. deep link to a deleted course) gets a real
    // screen with a way back instead of a default error page.
    errorBuilder: (context, state) => RouteNotFoundScreen(
      message: 'Halaman tidak ditemukan.',
      onBack: () => context.go(AppRoutes.courses),
    ),
  );
});

/// Minimal fallback for unmatched routes.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              child: const Text('Ke daftar kelas'),
            ),
          ],
        ),
      ),
    );
  }
}
