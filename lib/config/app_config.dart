class EnvironmentConfig {
  /// Base URL ya Laravel API.
  /// Mfano: https://pokeakwanza.com/api
  static const String productionBaseUrl = 'https://pokeakwanza.com/api';
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: productionBaseUrl,
  );
  static const bool preferLocalApiInDebug = bool.fromEnvironment(
    'PREFER_LOCAL_API_IN_DEBUG',
    defaultValue: false,
  );
  static const bool forceWebLocalApi = bool.fromEnvironment(
    'FORCE_WEB_LOCAL_API',
    defaultValue: false,
  );
  static const bool disableOtp = bool.fromEnvironment(
    'DISABLE_OTP',
    defaultValue: true,
  );
  static const bool disableGoogleSignIn = bool.fromEnvironment(
    'DISABLE_GOOGLE_SIGN_IN',
    defaultValue: true,
  );
}
