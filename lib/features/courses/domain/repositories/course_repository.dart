import '../entities/course.dart';

/// Contract the presentation layer depends on.
///
/// Abstract here so UI tests can swap in a fake repository without
/// touching Dio or assets.
abstract class CourseRepository {
  Future<List<Course>> getCourses();

  Future<CourseDetail> getCourseDetail(String id);
}
