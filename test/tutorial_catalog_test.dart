import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_developer/features/courses/domain/entities/course.dart';

void main() {
  test('curated lessons have unique sources, attribution and exact totals', () {
    final json = jsonDecode(
      File('assets/mock/api/courses.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final sources = <String>{};
    for (final raw in json['data'] as List<dynamic>) {
      final course = Course.fromJson(raw as Map<String, dynamic>);
      final lessons = (raw['lessons'] as List<dynamic>)
          .map((item) => Lesson.fromJson(item as Map<String, dynamic>))
          .toList();
      expect(course.totalLessons, lessons.length);
      expect(
        course.totalDurationSeconds,
        lessons.fold<int>(0, (sum, lesson) => sum + lesson.durationSeconds),
      );
      for (final lesson in lessons) {
        final uri = Uri.parse(lesson.videoUrl);
        expect(uri.scheme, 'https');
        expect(uri.host, 'www.youtube.com');
        expect(uri.queryParameters['v'], matches(r'^[a-zA-Z0-9_-]{11}$'));
        expect(sources.add(lesson.videoUrl), isTrue);
        expect(lesson.description, contains('Pembuat:'));
        expect(lesson.durationSeconds, greaterThan(0));
        expect(lesson.courseId, course.id);
      }
    }
    expect(sources.length, 34);
  });
}
