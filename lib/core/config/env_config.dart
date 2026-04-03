import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;
  EnvConfig._();

  bool _initialized = false;

  String get mattermostBaseUrl => _getEnvVariable('MATTERMOST_BASE_URL');
  String get mattermostWsUrl => _getEnvVariable('MATTERMOST_WS_URL');
  String get livekitUrl => _getEnvVariable('LIVEKIT_URL');
  String get livekitApiKey => _getEnvVariable('LIVEKIT_API_KEY');
  String get livekitApiSecret => _getEnvVariable('LIVEKIT_API_SECRET');

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
      debugPrint('Environment configuration loaded successfully');
    } catch (e) {
      debugPrint('Error loading environment variables: $e');
      _initialized = true;
    }
  }

  String _getEnvVariable(String key) {
    if (!_initialized) {
      throw Exception('Environment configuration not initialized. Call initialize() first.');
    }
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key not found or empty in .env file');
    }
    return value;
  }
}
