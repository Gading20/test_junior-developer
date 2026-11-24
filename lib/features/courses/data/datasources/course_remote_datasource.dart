import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../domain/entities/course.dart';
import '../models/course_json_parser.dart';
import 'course_datasource.dart';

/// Talks to the real API through [ApiClient].
///
/// Kept deliberately thin: URL building and JSON parsing only, no
/// business logic. Swapping mock for real API touches nothing else.
class CourseRemoteDatasource implements CourseDatasource {
  const CourseRemoteDatasource(this._client);

  final ApiClient _client;

  @override
  Future<List<Course>> fetchCourses() async {
    final envelope = await _client.getJson(Endpoints.courses);
    return CourseJsonParser.parseCourseList(envelope);
  }

  @override
  Future<CourseDetail> fetchCourseDetail(String id) async {
    final envelope = await _client.getJson(Endpoints.courseById(id));
    return CourseJsonParser.parseCourseDetail(envelope);
  }
}
