/// Difficulty level of a course. Drives the badge color, so the value
/// must always be one of these three — anything else is broken data.
enum Level {
  pemula,
  menengah,
  lanjut;

  static Level fromJson(Object? raw) {
    if (raw is! String) {
      throw const FormatException('Level must be a string');
    }
    return Level.values.firstWhere(
      (level) => level.name == raw,
      orElse: () => throw FormatException('Unknown level: $raw'),
    );
  }

  /// Badge text in Bahasa Indonesia.
  String get label => switch (this) {
    Level.pemula => 'Pemula',
    Level.menengah => 'Menengah',
    Level.lanjut => 'Lanjut',
  };
}

/// A course as shown in the list and detail screens.
///
/// Immutable by convention: all fields final, const constructor.
/// fromJson lives on the entity on purpose (see docs/decisions.md):
/// for this project the API shape and the domain shape are identical,
/// so a separate DTO class plus a mapper would only duplicate code.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.instructor,
    required this.level,
    required this.totalLessons,
    required this.totalDurationSeconds,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      // id and title are mandatory: without them the UI cannot render
      // anything meaningful, so missing values become a parse failure.
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      // Optional text fields degrade to empty string instead of failing.
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      instructor: json['instructor'] as String? ?? '',
      level: Level.fromJson(json['level']),
      // Missing numbers default to 0; wrong types still throw TypeError,
      // which the repository converts to FailureType.parsing.
      totalLessons: (json['totalLessons'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String instructor;
  final Level level;
  final int totalLessons;
  final int totalDurationSeconds;
}

/// One playable video inside a course.
class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.durationSeconds,
    required this.videoUrl,
    required this.description,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: _requiredString(json, 'id'),
      courseId: _requiredString(json, 'courseId'),
      title: _requiredString(json, 'title'),
      order: (json['order'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      // A lesson without a playable URL is useless, so it fails parsing
      // instead of silently showing a broken player.
      videoUrl: _requiredString(json, 'videoUrl'),
      description: json['description'] as String? ?? '',
    );
  }

  final String id;
  final String courseId;
  final String title;
  final int order;
  final int durationSeconds;
  final String videoUrl;
  final String description;
}

/// Detail payload: a course plus its ordered lesson list.
class CourseDetail {
  const CourseDetail({required this.course, required this.lessons});

  final Course course;
  final List<Lesson> lessons;

  Lesson? lessonById(String id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid "$key"');
  }
  return value;
}
