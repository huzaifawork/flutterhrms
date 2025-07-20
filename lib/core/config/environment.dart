class Environment {
  // Stripe Configuration
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51RQDO0QHBrXA72xgYssbECOe9bubZ2bWHA4m0T6EY6AvvmAfCzIDmKUCkRjpwVVIJ4IMaOiQBUawECn5GD8ADHbn00GRVmjExI', // Fallback for development
  );

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080', // Fallback for development
  );

  // Socket Configuration
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:8080', // Fallback for development
  );

  // Environment Detection
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isDevelopment = !isProduction;

  // Debug Configuration
  static const bool enableLogging =
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);

  // Get environment-specific values
  static String get currentStripeKey {
    if (isProduction) {
      // In production, this should come from environment variables
      return stripePublishableKey;
    } else {
      // Development/test key
      return stripePublishableKey;
    }
  }

  static String get currentApiUrl {
    if (isProduction) {
      return apiBaseUrl;
    } else {
      return apiBaseUrl;
    }
  }

  static String get currentSocketUrl {
    if (isProduction) {
      return socketUrl;
    } else {
      return socketUrl;
    }
  }

  // Validation
  static bool get isValidConfiguration {
    return stripePublishableKey.isNotEmpty &&
        apiBaseUrl.isNotEmpty &&
        socketUrl.isNotEmpty;
  }

  // Debug info
  static Map<String, dynamic> get debugInfo {
    return {
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'stripeKeySet': stripePublishableKey.isNotEmpty,
      'apiUrlSet': apiBaseUrl.isNotEmpty,
      'socketUrlSet': socketUrl.isNotEmpty,
      'enableLogging': enableLogging,
    };
  }
}
