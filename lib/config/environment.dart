enum Environment { development, production }

class EnvironmentConfig {
  static Environment _environment = Environment.development;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static void toggleEnvironment() {
    _environment = _environment == Environment.development
        ? Environment.production
        : Environment.development;
  }

  static Environment get environment => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;

  static String get baseUrl {
    // 🏠 FOR LOCAL DEVELOPMENT - Uncomment the local URL and comment the production URL
    // return 'http://192.168.0.110:3001/api'; // Local development //my network

    // return 'http://10.0.2.2:3001/api';
    return 'https://updatedbackend-bqg8.onrender.com/api';
  }

  // Add other environment-specific configurations here
  static int get connectionTimeout =>
      isDevelopment ? 30000 : 15000; // 30s for dev, 15s for prod
  static int get receiveTimeout => isDevelopment ? 30000 : 15000;

  static String get environmentName {
    return isDevelopment ? 'Development (Local)' : 'Production';
  }

  static String get environmentStatus {
    return '${environmentName} - ${baseUrl}';
  }
}
