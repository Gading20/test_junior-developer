import 'package:test_developer/core/error/failure.dart';
import 'package:test_developer/features/courses/domain/entities/course.dart';
import 'package:test_developer/features/courses/domain/repositories/course_repository.dart';

/// Fake repository: every test decides what the UI receives.
///
/// Failures are thrown from async methods instead of eager
/// `Future.error(...)`: an eager error fires before any listener is
/// attached and is reported as an unhandled async error, which fails
/// the test even when the UI handles it correctly later.
class FakeCourseRepository implements CourseRepository {
  FakeCourseRepository({
    this.courses = const [],
    this.pendingList,
    this.listError,
    this.detailFuture,
    this.detailError,
  });

  List<Course> courses;

  /// When set, [getCourses] never completes — used to observe loading.
  Future<List<Course>>? pendingList;
  Failure? listError;
  Future<CourseDetail>? detailFuture;
  Failure? detailError;

  int listCalls = 0;
  int detailCalls = 0;

  @override
  Future<List<Course>> getCourses() async {
    listCalls++;
    final pending = pendingList;
    if (pending != null) return pending;
    final error = listError;
    if (error != null) throw error;
    return courses;
  }

  @override
  Future<CourseDetail> getCourseDetail(String id) async {
    detailCalls++;
    final error = detailError;
    if (error != null) throw error;
    final future = detailFuture;
    if (future != null) return future;
    throw const Failure(
      type: FailureType.notFound,
      message: 'Kelas tidak ditemukan.',
      retryable: false,
    );
  }
}

/// One course whose title and description are deliberately far longer
/// than real ones, so ellipsis, wrapping and the "Selengkapnya" toggle
/// are exercised on every screen the course appears on.
Course sampleCourse({String id = 'c-1', String? title}) => Course(
  id: id,
  title:
      title ??
      'Flutter untuk Pemula: Dari Install Sampai Terbit di Play Store '
          'dengan Judul yang Sengaja Dibuat Sangat Panjang untuk Menguji '
          'Bagaimana Tata Letak Menangani Teks Berlebih',
  description:
      'Belajar Flutter dari nol sampai aplikasi terbit. Deskripsi ini '
      'dibuat cukup panjang agar tombol Selengkapnya ikut teruji.',
  thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202',
  instructor: 'Rani Kusuma',
  level: Level.pemula,
  totalLessons: 8,
  totalDurationSeconds: 6660,
);

/// Two playable lessons. [secondVideoUrl] lets a test swap in a broken
/// link to prove an invalid URL degrades to an error state.
CourseDetail sampleDetail({String secondVideoUrl = _bunnyUrl}) => CourseDetail(
  course: sampleCourse(),
  lessons: [
    const Lesson(
      id: 'l-1',
      courseId: 'c-1',
      title: 'Memasang Flutter dan VS Code',
      order: 1,
      durationSeconds: 720,
      videoUrl: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      description: 'Prasyarat dan flutter doctor.',
    ),
    Lesson(
      id: 'l-2',
      courseId: 'c-1',
      title: 'Widget dasar',
      order: 2,
      durationSeconds: 660,
      videoUrl: secondVideoUrl,
      description: 'Container, Row, Column.',
    ),
  ],
);

const String _bunnyUrl = 'https://media.w3.org/2010/05/bunny/trailer.mp4';
