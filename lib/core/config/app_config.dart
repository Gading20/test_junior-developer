/// Single place to switch between mock and real API.
///
/// UI and repository never hardcode a URL: they go through [ApiClient],
/// which reads these values. Going live = flip [useMock] and set [baseUrl].
class AppConfig {
  const AppConfig._();

  /// true  -> courses come from assets/mock/api/courses.json
  /// false -> courses come from [baseUrl] through Dio
  static const bool useMock = true;

  /// Real backend root. Injected at build time so no real URL is invented here:
  /// flutter run --dart-define=BASE_URL=https://api.yourbackend.com/v1
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.example.com/v1',
  );
}
