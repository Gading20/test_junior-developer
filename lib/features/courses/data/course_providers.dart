import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/repositories/course_repository.dart';
import 'datasources/course_datasource.dart';
import 'datasources/course_mock_datasource.dart';
import 'datasources/course_remote_datasource.dart';
import 'repositories/course_repository_impl.dart';

/// Dependency injection graph for the courses feature.
///
/// Order: ApiClient -> datasource (chosen by AppConfig.useMock) ->
/// repository. Changing to a real API means editing [AppConfig] only.

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final courseDatasourceProvider = Provider<CourseDatasource>((ref) {
  if (AppConfig.useMock) {
    return CourseMockDatasource();
  }
  return CourseRemoteDatasource(ref.watch(apiClientProvider));
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl(ref.watch(courseDatasourceProvider));
});
