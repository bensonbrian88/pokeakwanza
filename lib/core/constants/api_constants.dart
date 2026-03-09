class ApiConstants {
  /// Deprecated: most code should now use `ApiConfig.baseUrl` or
  /// `AppConfig.baseUrl` instead.  This field remains for backwards
  /// compatibility (some legacy imports still reference it) but it no longer
  /// includes the `/api` suffix.
  static String get baseUrl {
    // kept for legacy imports; mirror AppConfig.baseUrl without the `/api`.
    return 'https://pokeakwanza.com';
  }

  static const String updateProfile = "/user/update-profile";
}
