import 'package:flutter_test/flutter_test.dart';

import 'package:test_developer/features/courses/domain/entities/course.dart';
import 'package:test_developer/features/lesson_player/presentation/lesson_navigation.dart';

Lesson _lesson(String id) => Lesson(
  id: id,
  courseId: 'c-1',
  title: id,
  order: 1,
  durationSeconds: 60,
  videoUrl: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
  description: '',
);

void main() {
  final lessons = [_lesson('a'), _lesson('b'), _lesson('c')];

  group('LessonNavigation', () {
    test('walks the list in course order', () {
      expect(LessonNavigation.before(lessons, 'b')!.id, 'a');
      expect(LessonNavigation.after(lessons, 'b')!.id, 'c');
    });

    test('returns null at both ends, so the buttons disable', () {
      expect(LessonNavigation.before(lessons, 'a'), isNull);
      expect(LessonNavigation.after(lessons, 'c'), isNull);
      expect(LessonNavigation.before(lessons, 'a'), isNull);
    });

    test('returns null for an id that is not in the list', () {
      expect(LessonNavigation.indexOf(lessons, 'zzz'), isNull);
      expect(LessonNavigation.before(lessons, 'zzz'), isNull);
      expect(LessonNavigation.after(lessons, 'zzz'), isNull);
    });

    test('handles a single-lesson course', () {
      final only = [_lesson('only')];
      expect(LessonNavigation.before(only, 'only'), isNull);
      expect(LessonNavigation.after(only, 'only'), isNull);
    });
  });
}
