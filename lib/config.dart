import 'config_local.dart';

/// Application configuration for ExpenseSnap.
///
/// Holds the backend n8n webhook base URL and API key.
/// Values can be supplied at compile time using `--dart-define`:
/// ```bash
/// flutter run --dart-define=EXPENSESNAP_API_KEY=your_key --dart-define=EXPENSESNAP_BASE_URL=http://10.0.2.2:5678/webhook
/// ```
///
/// Or loaded automatically from [LocalConfig] or overridden at runtime.
class AppConfig {
  /// Default base URL for n8n webhooks when running on an Android emulator.
  /// (The Android emulator uses 10.0.2.2 to access the host computer's localhost).
  static const String defaultBaseUrl = 'http://10.0.2.2:5678/webhook';

  static const String _envBaseUrl = String.fromEnvironment(
    'EXPENSESNAP_BASE_URL',
    defaultValue: LocalConfig.baseUrl,
  );

  static const String _envApiKey = String.fromEnvironment(
    'EXPENSESNAP_API_KEY',
    defaultValue: LocalConfig.apiKey,
  );

  /// Configurable base URL (can be customized for real device IP or emulator).
  static String baseUrl = _envBaseUrl;

  /// Configurable API key sent in the `x-api-key` header.
  static String apiKey = _envApiKey;

  /// Header key expected by the n8n webhook backend.
  static const String apiKeyHeader = 'x-api-key';
}
