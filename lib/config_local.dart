// Local configuration for development.
// Replace with your local x-api-key if not using --dart-define.

class LocalConfig {
  /// Your local n8n x-api-key secret.
  static const String apiKey = 'YOUR_X_API_KEY_HERE';

  /// Your local backend webhook URL.
  /// - Use http://10.0.2.2:5678/webhook on Android Emulator.
  /// - Use http://localhost:5678/webhook on iOS Simulator / Web / Desktop.
  /// - Use http://`YOUR_PC_LAN_IP`:5678/webhook on a physical device.
  static const String baseUrl = 'http://10.0.2.2:5678/webhook';
}
