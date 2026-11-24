import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/exception_mapper.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_datasource.dart';

/// Concrete repository: picks a datasource (injected by the provider)
/// and guarantees that EVERY failure leaves this layer as a [Failure].
///
/// The UI therefore only handles one error type, no matter whether the
/// problem was offline, timeout, 404, or malformed JSON.
class CourseRepositoryImpl implements CourseRepository {
  const CourseRepositoryImpl(this._datasource);

  final CourseDatasource _datasource;

  @override
  Future<List<Course>> getCourses() => _guard(_datasource.fetchCourses);

  @override
  Future<CourseDetail> getCourseDetail(String id) =>
      _guard(() => _datasource.fetchCourseDetail(id));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on Failure {
      rethrow;
    } on DioException catch (exception) {
      // ApiClient normally converts these already; kept as a safety net
      // so a future datasource cannot leak raw Dio errors upward.
      throw mapDioExceptionToFailure(exception);
    } on FormatException {
      throw const Failure(
        type: FailureType.parsing,
        message: 'Data tidak bisa dimuat. Coba lagi.',
      );
    } on TypeError {
      // Wrong JSON types (string where int is expected) surface as
      // TypeError from the `as` casts in fromJson.
      throw const Failure(
        type: FailureType.parsing,
        message: 'Data tidak bisa dimuat. Coba lagi.',
      );
    } catch (error) {
      throw const Failure(
        type: FailureType.unknown,
        message: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }
}
