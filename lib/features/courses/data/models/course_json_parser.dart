import '../../domain/entities/course.dart';

/// Parses the API envelope shared by both endpoints.
///
/// Mock and remote datasources both call these methods, so switching
/// from mock to real API can never change how JSON becomes objects.
/// Broken shapes throw [FormatException] → FailureType.parsing.
class CourseJsonParser {
  const CourseJsonParser._();

  /// GET /courses -> `List<Course>`
  static List<Course> parseCourseList(Map<String, dynamic> envelope) {
    return courseMaps(envelope).map(Course.fromJson).toList(growable: false);
  }

  /// GET /courses/{id} -> CourseDetail
  static CourseDetail parseCourseDetail(Map<String, dynamic> envelope) {
    _ensureSuccess(envelope);
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('"data" must be an object');
    }
    final rawLessons = data['lessons'];
    if (rawLessons is! List) {
      throw const FormatException('"lessons" must be a list');
    }
    return CourseDetail(
      course: Course.fromJson(data),
      lessons: rawLessons
          .map((item) => Lesson.fromJson(_asObject(item, 'lesson')))
          .toList(growable: false),
    );
  }

  /// "data" array of the list endpoint, with every element validated
  /// as an object. Used by the mock to reach lessons of one course.
  static List<Map<String, dynamic>> courseMaps(Map<String, dynamic> envelope) {
    _ensureSuccess(envelope);
    final data = envelope['data'];
    if (data is! List) {
      throw const FormatException('"data" must be a list');
    }
    return data
        .map((item) => _asObject(item, 'course'))
        .toList(growable: false);
  }

  static Map<String, dynamic> _asObject(Object? item, String label) {
    if (item is! Map<String, dynamic>) {
      throw FormatException('$label must be an object');
    }
    return item;
  }

  static void _ensureSuccess(Map<String, dynamic> envelope) {
    if (envelope['success'] != true) {
      throw const FormatException('"success" is not true');
    }
  }
}
