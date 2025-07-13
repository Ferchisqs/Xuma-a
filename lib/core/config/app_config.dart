// lib/core/config/app_configuration.dart
import 'dart:io';

class AppConfiguration {
  // ==================== CONFIGURACIÓN DE AMBIENTE ====================
  
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static bool get isStaging => _environment == 'staging';
  
  // ==================== URLS DEL BACKEND ====================
  
  // 🔧 CONFIGURA AQUÍ TUS URLS
  static const String _productionUrl = 'https://api.xuma-a.com';
  static const String _stagingUrl = 'https://staging-api.xuma-a.com';
  static const String _developmentUrl = 'http://localhost:3000';
  
  // Para testing en dispositivo físico, usar IP local:
  // static const String _developmentUrl = 'http://192.168.1.100:3000';
  
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _productionUrl;
      case 'staging':
        return _stagingUrl;
      case 'development':
      default:
        return _developmentUrl;
    }
  }
  
  // ==================== CONFIGURACIÓN DE RED ====================
  
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // Configuración específica por plataforma
  static Map<String, int> get timeouts {
    if (Platform.isIOS) {
      return {
        'connect': 25000, // iOS puede ser más lento
        'receive': 25000,
        'send': 25000,
      };
    } else {
      return {
        'connect': connectTimeout,
        'receive': receiveTimeout,
        'send': sendTimeout,
      };
    }
  }
  
  // ==================== CONFIGURACIÓN DE CACHE ====================
  
  static const Duration tokenCacheDuration = Duration(hours: 24);
  static const Duration userCacheDuration = Duration(hours: 12);
  static const Duration generalCacheDuration = Duration(hours: 6);
  
  // ==================== CONFIGURACIÓN DE LOGGING ====================
  
  static bool get enableNetworkLogging => isDevelopment;
  static bool get enableDetailedLogs => isDevelopment;
  static bool get enableCrashReporting => isProduction;
  
  // ==================== CONFIGURACIÓN DE FUNCIONALIDADES ====================
  
  static bool get enableOfflineMode => true;
  static bool get enableAutoRefreshToken => true;
  static bool get enableBiometricAuth => true;
  static bool get enablePushNotifications => true;
  
  // Configuración específica de autenticación
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  
  // ==================== HEADERS Y AUTENTICACIÓN ====================
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Platform': Platform.isIOS ? 'ios' : 'android',
    'X-App-Version': '1.0.0', // Obtener de package_info_plus
  };
  
  // ==================== CONFIGURACIÓN DE ERRORES ====================
  
  static const Map<String, String> errorMessages = {
    'network_error': 'Sin conexión a internet',
    'server_error': 'Error del servidor',
    'timeout_error': 'Tiempo de espera agotado',
    'auth_error': 'Error de autenticación',
    'validation_error': 'Datos inválidos',
    'unknown_error': 'Error inesperado',
  };
  
  // ==================== MÉTODOS HELPER ====================
  
  /// Obtiene la URL completa para un endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Verifica si estamos en modo debug
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  /// Obtiene configuración específica para el ambiente actual
  static Map<String, dynamic> get environmentConfig => {
    'baseUrl': baseUrl,
    'environment': _environment,
    'isDevelopment': isDevelopment,
    'isProduction': isProduction,
    'enableLogging': enableNetworkLogging,
    'enableOfflineMode': enableOfflineMode,
    'timeouts': timeouts,
  };
  
  // ==================== CONFIGURACIÓN DE DESARROLLO ====================
  
  /// Configuraciones solo para desarrollo
  static const bool enableMockData = false; // Activar solo para testing
  static const bool skipEmailVerification = false; // Solo para desarrollo
  static const bool skipParentalConsent = false; // Solo para desarrollo
  
  // ==================== CONFIGURACIÓN DE SEGURIDAD ====================
  
  static const bool enableCertificatePinning = true; // Para producción
  static const bool enableRequestSigning = false; // Implementar si es necesario
  
  /// Lista de dominios confiables
  static const List<String> trustedDomains = [
    'xuma-a.com',
    'api.xuma-a.com',
    'staging-api.xuma-a.com',
  ];
  
  // ==================== CONFIGURACIÓN DE MONITOREO ====================
  
  static const bool enableAnalytics = true;
  static const bool enablePerformanceMonitoring = true;
  static const String analyticsId = 'XUMA_A_ANALYTICS_ID';
  
  /// Configuración para debugging de red
  static Map<String, dynamic> get debugConfig => {
    'logRequests': enableNetworkLogging,
    'logResponses': enableNetworkLogging,
    'logHeaders': isDevelopment,
    'logErrors': true,
    'prettyPrint': isDevelopment,
  };
}