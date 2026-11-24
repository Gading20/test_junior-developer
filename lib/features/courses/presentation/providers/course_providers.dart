import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/course_providers.dart';
import '../../domain/entities/course.dart';

/// UI-facing state for the course list.
///
/// FutureProvider instead of AsyncNotifier: the list is read-only data,
/// no mutations are needed, and FutureProvider gives AsyncValue (with
/// loading/error/data) for free.
///
/// retry is disabled: Riverpod 3 retries failed futures by default
/// (up to 10 times, exponential backoff), which would keep the screen
/// in its loading state for many seconds instead of showing the
/// offline/timeout message. We already offer an explicit "Coba lagi"
/// button, so automatic retries would duplicate it.
final courseListProvider = FutureProvider<List<Course>>(
  (ref) => ref.watch(courseRepositoryProvider).getCourses(),
  retry: (attempt, error) => null,
);

/// Course detail (with lessons) cached per course id.
final courseDetailProvider = FutureProvider.family<CourseDetail, String>(
  (ref, courseId) =>
      ref.watch(courseRepositoryProvider).getCourseDetail(courseId),
  retry: (attempt, error) => null,
);
