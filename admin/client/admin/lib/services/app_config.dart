import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, production }

class AppConfig {
  static const AppEnvironment? forceEnvironment = null;

  static AppEnvironment get environment {
    if (forceEnvironment != null) return forceEnvironment!;
    final envStr = dotenv.get('APP_ENV', fallback: 'development').toLowerCase();
    if (envStr == 'production' || envStr == 'prod') {
      return AppEnvironment.production;
    }
    return AppEnvironment.development;
  }

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.development:
        return dotenv.get('DEV_BASE_URL', fallback: 'http://192.168.0.14:3000');
      case AppEnvironment.production:
        return dotenv.get('PROD_BASE_URL', fallback: 'https://stock-archery.onrender.com');
    }
  }


  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isProduction => environment == AppEnvironment.production;
}
