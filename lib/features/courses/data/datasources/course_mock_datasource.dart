import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../../core/error/failure.dart';
import '../../domain/entities/course.dart';
import '../models/course_json_parser.dart';
import 'course_datasource.dart';

/// Serves the same JSON envelope as the real API, loaded from
/// assets/mock/api/courses.json.
///
/// One file simulates both endpoints: the list is the whole "data"
/// array, a detail is one element of that array. The response shape
/// stays identical to the documented contract, so repository and UI
/// cannot tell mock from remote.
class CourseMockDatasource implements CourseDatasource {
  CourseMockDatasource({AssetBundle? bundle, Duration? latency})
    : _bundle = bundle ?? rootBundle,
      _latency = latency ?? const Duration(milliseconds: 400);

  static const String assetPath = 'assets/mock/api/courses.json';

  final AssetBundle _bundle;

  /// Small delay so the skeleton loading state is visible during demos
  /// (real network has latency anyway).
  final Duration _latency;

  @override
  Future<List<Course>> fetchCourses() async {
    final envelope = await _loadEnvelope();
    return CourseJsonParser.parseCourseList(envelope);
  }

  @override
  Future<CourseDetail> fetchCourseDetail(String id) async {
    final envelope = await _loadEnvelope();
    final matches = CourseJsonParser.courseMaps(envelope)
        .where((course) => course['id'] == id);
    if (matches.isEmpty) {
      // Mock equivalent of HTTP 404.
      throw const Failure(
        type: FailureType.notFound,
        message: 'Kelas tidak ditemukan.',
        retryable: false,
      );
    }
    return CourseJsonParser.parseCourseDetail({
      'success': true,
      'data': matches.first,
    });
  }

  Future<Map<String, dynamic>> _loadEnvelope() async {
    await Future<void>.delayed(_latency);
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Mock envelope must be an object');
    }
    return decoded;
  }
}
