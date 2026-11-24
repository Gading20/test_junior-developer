import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_developer/core/error/failure.dart';
import 'package:test_developer/core/network/exception_mapper.dart';
import 'package:test_developer/features/courses/data/datasources/course_datasource.dart';
import 'package:test_developer/features/courses/data/models/course_json_parser.dart';
import 'package:test_developer/features/courses/data/repositories/course_repository_impl.dart';
import 'package:test_developer/features/courses/domain/entities/course.dart';

class _StubDatasource implements CourseDatasource {
  _StubDatasource({this.courses = const []});

  Object? error;
  List<Course> courses;

  @override
  Future<List<Course>> fetchCourses() async {
    final failure = error;
    if (failure != null) throw failure;
    return courses;
  }

  @override
  Future<CourseDetail> fetchCourseDetail(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return CourseDetail(
      course: Course(
        id: id,
        title: 'Kelas',
        description: '',
        thumbnailUrl: '',
        instructor: '',
        level: Level.pemula,
        totalLessons: 1,
        totalDurationSeconds: 60,
      ),
      lessons: const [
        Lesson(
          id: 'l-1',
          courseId: 'c-1',
          title: 'Pelajaran',
          order: 1,
          durationSeconds: 60,
          videoUrl: 'https://www.youtube.com/watch?v=abcdefghijk',
          description: '',
        ),
      ],
    );
  }
}

Map<String, dynamic> _courseJson({
  Object? id = 'c-1',
  Object? title = 'Kelas Flutter',
  Object? level = 'pemula',
  Object? totalLessons = 2,
  Object? lessons,
}) => <String, dynamic>{
  'id': id,
  'title': title,
  'description': null,
  'thumbnailUrl': null,
  'instructor': null,
  'level': level,
  'totalLessons': totalLessons,
  'totalDurationSeconds': 120,
  'lessons':
      lessons ??
      [
        {
          'id': 'l-1',
          'courseId': 'c-1',
          'title': 'Pertama',
          'order': 1,
          'durationSeconds': 60,
          'videoUrl': 'https://www.youtube.com/watch?v=abcdefghijk',
          'description': null,
        },
      ],
};

void main() {
  group('model parsing', () {
    test(
      'valid envelope parses with optional text fields as empty strings',
      () {
        final detail = CourseJsonParser.parseCourseDetail(<String, dynamic>{
          'success': true,
          'data': _courseJson(),
        });
        expect(detail.course.title, 'Kelas Flutter');
        expect(detail.course.description, '');
        expect(detail.course.level, Level.pemula);
        expect(detail.lessons.single.description, '');
        expect(detail.lessons.single.videoUrl, contains('youtube.com'));
      },
    );

    test('missing mandatory fields throw FormatException', () {
      expect(
        () => Course.fromJson(_courseJson(id: null)),
        throwsFormatException,
      );
      expect(
        () => Course.fromJson(_courseJson(title: '')),
        throwsFormatException,
      );
      expect(
        () => Course.fromJson(_courseJson(level: 'ahli')),
        throwsFormatException,
      );
    });

    test('wrong JSON types throw, not silent defaults', () {
      expect(
        () => Course.fromJson(_courseJson(totalLessons: 'bukan angka')),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => CourseJsonParser.parseCourseList(<String, dynamic>{
          'success': true,
          'data': 'bukan daftar',
        }),
        throwsFormatException,
      );
    });

    test('broken envelope and lesson entries are rejected', () {
      expect(
        () => CourseJsonParser.courseMaps(<String, dynamic>{
          'success': false,
          'data': <dynamic>[],
        }),
        throwsFormatException,
      );
      expect(
        () => CourseJsonParser.parseCourseDetail(<String, dynamic>{
          'success': true,
          'data': _courseJson(lessons: 'bukan daftar'),
        }),
        throwsFormatException,
      );
      expect(
        () => CourseJsonParser.parseCourseDetail(<String, dynamic>{
          'success': true,
          'data': _courseJson(lessons: <dynamic>['bukan objek']),
        }),
        throwsFormatException,
      );
    });
  });

  group('repository failure mapping', () {
    test(
      'offline, timeout, not found and parsing get distinct types',
      () async {
        final datasource = _StubDatasource();
        final repository = CourseRepositoryImpl(datasource);

        datasource.error = const Failure(
          type: FailureType.offline,
          message: 'offline',
        );
        expect(
          () => repository.getCourses(),
          throwsA(
            isA<Failure>().having((f) => f.type, 'type', FailureType.offline),
          ),
        );

        datasource.error = const Failure(
          type: FailureType.timeout,
          message: 'timeout',
        );
        expect(
          () => repository.getCourses(),
          throwsA(
            isA<Failure>().having((f) => f.type, 'type', FailureType.timeout),
          ),
        );

        datasource.error = const Failure(
          type: FailureType.notFound,
          message: 'tidak ada',
          retryable: false,
        );
        expect(
          () => repository.getCourseDetail('c-x'),
          throwsA(
            isA<Failure>().having((f) => f.retryable, 'retryable', false),
          ),
        );

        datasource.error = const FormatException('broken');
        expect(
          () => repository.getCourses(),
          throwsA(
            isA<Failure>().having((f) => f.type, 'type', FailureType.parsing),
          ),
        );
      },
    );

    test('raw Dio errors never leak to the UI', () async {
      final datasource = _StubDatasource();
      final repository = CourseRepositoryImpl(datasource);
      datasource.error = DioException(
        requestOptions: RequestOptions(path: '/courses'),
        type: DioExceptionType.connectionError,
        error: const SocketException('offline'),
      );
      expect(
        () => repository.getCourses(),
        throwsA(
          isA<Failure>().having((f) => f.type, 'type', FailureType.offline),
        ),
      );
    });

    test('result passes through unchanged', () async {
      final course = Course.fromJson(_courseJson());
      final repository = CourseRepositoryImpl(
        _StubDatasource(courses: [course]),
      );
      expect(await repository.getCourses(), [course]);
      final detail = await repository.getCourseDetail('c-1');
      expect(detail.course.id, 'c-1');
    });
  });

  group('Dio exception mapper', () {
    Failure map(DioExceptionType type, {int? status, Object? error}) =>
        mapDioExceptionToFailure(
          DioException(
            requestOptions: RequestOptions(path: '/courses'),
            type: type,
            error: error,
            response: status == null
                ? null
                : Response(
                    requestOptions: RequestOptions(path: '/courses'),
                    statusCode: status,
                  ),
          ),
        );

    test('five status classes get five different user-facing failures', () {
      expect(map(DioExceptionType.connectionError).type, FailureType.offline);
      expect(map(DioExceptionType.receiveTimeout).type, FailureType.timeout);
      expect(
        map(DioExceptionType.badResponse, status: 404).type,
        FailureType.notFound,
      );
      expect(
        map(DioExceptionType.badResponse, status: 503).type,
        FailureType.server,
      );
      expect(map(DioExceptionType.unknown).type, FailureType.unknown);
      expect(
        map(
          DioExceptionType.unknown,
          error: const SocketException('offline'),
        ).type,
        FailureType.offline,
      );
    });
  });
}
