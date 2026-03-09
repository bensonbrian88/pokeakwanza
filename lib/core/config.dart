import 'package:stynext/config/api_config.dart';

class AppConfig {
  static String get baseUrl {
    return ApiConfig.baseUrl;
  }

  static String normalizeImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final base = ApiConfig.baseUrl;
    final baseUri = Uri.parse(base);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    if (raw.startsWith('http')) {
      final u = Uri.tryParse(raw);
      if (u == null) return raw;
      final h = u.host.toLowerCase();
      if (h == 'localhost' || h == '127.0.0.1' || h == '10.0.2.2') {
        final replaced = u.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        );
        return replaced.toString();
      }
      return raw;
    }
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$origin/$trimmed';
  }

  static String get imageBaseUrl {
    final base = ApiConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/';
    return '${origin}storage/';
  }
}
