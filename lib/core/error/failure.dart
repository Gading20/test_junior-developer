/// Why an operation failed, in terms the UI can react to.
enum FailureType {
  /// No network at all (device offline, DNS failure).
  offline,

  /// Request exceeded connect/receive/send timeout.
  timeout,

  /// Server answered 5xx, or response body was unreadable.
  server,

  /// Resource does not exist (404).
  notFound,

  /// Response body arrived but JSON/fields are broken.
  parsing,

  /// Anything else.
  unknown,
}

/// Error type shared across data layer and UI.
///
/// Data layer THROWS [Failure] instead of returning Result objects:
/// Riverpod's AsyncValue already models success/error, so a Result
/// wrapper would only add boilerplate.
class Failure {
  const Failure({
    required this.type,
    required this.message,
    this.retryable = true,
  });

  final FailureType type;

  /// User-facing message (Bahasa Indonesia), shown by StateView.
  final String message;

  /// Whether showing a "Coba lagi" button makes sense.
  final bool retryable;

  @override
  String toString() => 'Failure($type, $message)';
}
