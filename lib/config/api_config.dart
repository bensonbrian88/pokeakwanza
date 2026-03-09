import 'package:stynext/config/app_config.dart';

class ApiConfig {
  static String get baseUrl {
    // Force all API calls to use production domain
    return EnvironmentConfig.productionBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const bool enableDebugLogs = true;
}
