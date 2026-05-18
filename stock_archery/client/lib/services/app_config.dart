import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  development,
  production,
}

class AppConfig {
  /// Toggle this to force an environment in Dart code, or leave as null
  /// to load dynamically from your .env file.
  static const AppEnvironment? forceEnvironment = null;

  /// Retrieve the current active environment (checks forceEnvironment, then falls back to .env)
  static AppEnvironment get environment {
    if (forceEnvironment != null) return forceEnvironment!;
    
    final envStr = dotenv.get('APP_ENV', fallback: 'development').toLowerCase();
    if (envStr == 'production' || envStr == 'prod') {
      return AppEnvironment.production;
    }
    return AppEnvironment.development;
  }

  /// Retrieve the current API Base URL based on the active environment
  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.development:
        return dotenv.get('DEV_BASE_URL', fallback: 'http://192.168.1.3:5000/api');
      case AppEnvironment.production:
        return dotenv.get('PROD_BASE_URL', fallback: 'https://stock-archery-main.onrender.com/api');
    }
  }

  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isProduction => environment == AppEnvironment.production;
}
