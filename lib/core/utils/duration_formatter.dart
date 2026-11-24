/// Duration formatting helpers.
///
/// Hand-written instead of the intl package: the app needs exactly two
/// formats, so a dependency would be heavier than the code it replaces.
abstract class DurationFormatter {
  /// Player clock: 7:05, 12:00, 1:02:33.
  static String clock(int seconds) {
    final total = seconds < 0 ? 0 : seconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
  }

  /// Human summary for course cards: 45 m, 1 j 30 m, 2 j 5 m.
  static String human(int seconds) {
    final total = seconds < 0 ? 0 : seconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours == 0) return '$minutes m';
    if (minutes == 0) return '$hours j';
    return '$hours j $minutes m';
  }
}
