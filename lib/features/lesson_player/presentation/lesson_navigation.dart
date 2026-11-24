import '../../courses/domain/entities/course.dart';

/// Order-based helpers for moving between the lessons of one course.
///
/// Pure functions (no BuildContext, no providers) so the navigation
/// rules — including "nothing before the first lesson" — can be
/// unit-tested without a widget tree.
abstract class LessonNavigation {
  /// Position of [lessonId] in course order, or null when the lesson is
  /// not part of this list (stale deep link, broken data).
  static int? indexOf(List<Lesson> lessons, String lessonId) {
    for (var index = 0; index < lessons.length; index++) {
      if (lessons[index].id == lessonId) return index;
    }
    return null;
  }

  /// The lesson before [lessonId]; null at the start of the course.
  static Lesson? before(List<Lesson> lessons, String lessonId) {
    final index = indexOf(lessons, lessonId);
    if (index == null || index == 0) return null;
    return lessons[index - 1];
  }

  /// The lesson after [lessonId]; null at the end of the course.
  static Lesson? after(List<Lesson> lessons, String lessonId) {
    final index = indexOf(lessons, lessonId);
    if (index == null || index >= lessons.length - 1) return null;
    return lessons[index + 1];
  }
}
