// lib/core/config/api_endpoints.dart
class ApiEndpoints {
  // 🌐 BASE URL - CAMBIAR AQUÍ TU URL DEL BACKEND
  static const String baseUrl = 'https://auth-service-production-e333.up.railway.app'; // 🔧 REEMPLAZA CON TU URL
  // static const String baseUrl = 'http://localhost:3000'; // Para desarrollo local
  // static const String baseUrl = 'http://192.168.1.100:3000'; // Para testing en red local

  // ==================== AUTENTICACIÓN ====================
  // Endpoints básicos de autenticación
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  
  // ==================== TOKENS ====================
  // Gestión y validación de tokens JWT
  static const String validateToken = '/api/auth/validate-token';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String revokeToken = '/api/auth/revoke-token';
  
  // Endpoints alternativos de tokens
  static const String tokensValidate = '/api/tokens/validate';
  static const String tokensRefresh = '/api/tokens/refresh';
  static const String tokensRevoke = '/api/tokens/revoke';
  
  // ==================== CONSENTIMIENTO PARENTAL ====================
  // Gestión de consentimiento parental para menores de 13 años
  static const String parentalConsentRequest = '/api/auth/parental-consent/request';
  static const String parentalConsentApprove = '/api/auth/parental-consent/approve'; // + /{token}
  static const String parentalConsentStatus = '/api/auth/parental-consent/status'; // + /{userId}
  
  // ==================== VERIFICACIÓN DE EMAIL ====================
  // Verificación de email para usuarios
  static const String sendVerification = '/api/auth/send-verification';
  static const String verifyEmail = '/api/auth/verify-email'; // + /{token}
  static const String resendVerification = '/api/auth/resend-verification';
  static const String verificationStatus = '/api/auth/verification-status'; // + /{userId}
  
  // ==================== OTROS ENDPOINTS XUMA'A ====================
  // Endpoints de contenido y funcionalidades
  static const String ecoTips = '/api/eco-tips';
  static const String userStats = '/api/user/stats';
  static const String userActivity = '/api/user/activity';
  static const String news = '/api/news';
  static const String projects = '/api/projects';
  static const String challenges = '/api/challenges';
  
  // ==================== MÉTODOS HELPER ====================
  // Métodos para construir URLs dinámicas
  static String getParentalConsentApprove(String token) {
    return '$parentalConsentApprove/$token';
  }
  
  static String getParentalConsentStatus(String userId) {
    return '$parentalConsentStatus/$userId';
  }
  
  static String getVerifyEmail(String token) {
    return '$verifyEmail/$token';
  }
  
  static String getVerificationStatus(String userId) {
    return '$verificationStatus/$userId';
  }
  
  // Método para obtener URL completa
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // ==================== CONFIGURACIÓN DE TIMEOUTS ====================
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  static const int sendTimeout = 30000; // 30 segundos
  
  // ==================== HEADERS POR DEFECTO ====================
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
  };
}