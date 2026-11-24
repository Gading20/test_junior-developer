import '../../domain/entities/course.dart';

/// Where course data comes from. Two implementations exist:
/// remote (Dio against a real API) and mock (JSON asset).
abstract class CourseDatasource {
  Future<List<Course>> fetchCourses();

  Future<CourseDetail> fetchCourseDetail(String id);
}
