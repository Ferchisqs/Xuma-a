// lib/core/config/api_endpoints.dart - ACTUALIZADO CON CONTENT SERVICE
class ApiEndpoints {
  // ==================== SERVICIOS BASE ====================
  
  // 🌐 AUTH SERVICE - Para autenticación
  static const String authServiceUrl = 'https://auth-service-production-e333.up.railway.app';
  
  // 🌐 USER SERVICE - Para perfiles de usuario  
  static const String userServiceUrl = 'https://user-service-xumaa-production.up.railway.app';
  
  // 🌐 CONTENT SERVICE - Para tips, noticias, etc. 🆕
  static const String contentServiceUrl = 'https://content-service-xumaa-production.up.railway.app';

  // ==================== AUTENTICACIÓN ====================
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  
  // ==================== TOKENS ====================
  static const String validateToken = '/api/auth/validate-token';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String revokeToken = '/api/auth/revoke-token';
  
  static const String tokensValidate = '/api/tokens/validate';
  static const String tokensRefresh = '/api/tokens/refresh';
  static const String tokensRevoke = '/api/tokens/revoke';
  
  // ==================== CONSENTIMIENTO PARENTAL ====================
  static const String parentalConsentRequest = '/api/auth/parental-consent/request';
  static const String parentalConsentApprove = '/api/auth/parental-consent/approve';
  static const String parentalConsentStatus = '/api/auth/parental-consent/status';
  
  // ==================== VERIFICACIÓN DE EMAIL ====================
  static const String sendVerification = '/api/auth/send-verification';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String verificationStatus = '/api/auth/verification-status';
  
  // ==================== PERFILES DE USUARIO ====================
  static const String userProfile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile';
  static const String userStats = '/api/users/stats';
  static const String userActivity = '/api/users/activity';
  
  // ==================== CONTENIDO - TIPS 🆕 ====================
  static const String allTips = '/api/content/all-tips';
  static const String tips = '/api/content/tips';
  static const String createTip = '/api/content/tips';
  
  // ==================== CONTENIDO - OTROS 🆕 ====================
  static const String news = '/api/content/news';
  static const String projects = '/api/content/projects';
  static const String challenges = '/api/content/challenges';
  static const String lessons = '/api/content/lessons';
  
  // ==================== MÉTODOS HELPER ====================
  
  // Helpers para consentimiento parental
  static String getParentalConsentApprove(String token) {
    return '$parentalConsentApprove/$token';
  }
  
  static String getParentalConsentStatus(String userId) {
    return '$parentalConsentStatus/$userId';
  }
  
  // Helpers para verificación de email
  static String getVerifyEmail(String token) {
    return '$verifyEmail/$token';
  }
  
  static String getVerificationStatus(String userId) {
    return '$verificationStatus/$userId';
  }
  
  // 🆕 Helpers para tips
  static String getTipById(String id) {
    return '$tips/$id';
  }
  
  static String updateTip(String id) {
    return '$tips/$id';
  }
  
  static String deleteTip(String id) {
    return '$tips/$id';
  }
  
  // 🆕 Helpers para contenido general
  static String getNewsById(String id) {
    return '$news/$id';
  }
  
  static String getProjectById(String id) {
    return '$projects/$id';
  }
  
  static String getChallengeById(String id) {
    return '$challenges/$id';
  }
  
  // Método para obtener URL completa según el servicio
  static String getFullUrl(String endpoint, {String? service}) {
    switch (service?.toLowerCase()) {
      case 'auth':
        return '$authServiceUrl$endpoint';
      case 'user':
        return '$userServiceUrl$endpoint';
      case 'content':
        return '$contentServiceUrl$endpoint';
      default:
        // Por defecto usar auth service para compatibilidad
        return '$authServiceUrl$endpoint';
    }
  }
  
  // 🆕 Métodos específicos para cada servicio
  static String getAuthUrl(String endpoint) => '$authServiceUrl$endpoint';
  static String getUserUrl(String endpoint) => '$userServiceUrl$endpoint';
  static String getContentUrl(String endpoint) => '$contentServiceUrl$endpoint';
  
  // ==================== CONFIGURACIÓN DE TIMEOUTS ====================
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  // ==================== HEADERS POR DEFECTO ====================
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
  };
  
  // 🆕 Headers específicos para content service
  static const Map<String, String> contentHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'content',
  };
  
  // ==================== PARÁMETROS DE CONSULTA COMUNES ====================
  
  // Parámetros de paginación
  static Map<String, dynamic> getPaginationParams({
    int page = 1,
    int limit = 20,
  }) {
    return {
      'page': page,
      'limit': limit,
    };
  }
  
  // 🆕 Parámetros para filtros de contenido
  static Map<String, dynamic> getContentFilterParams({
    String? category,
    bool? isActive,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, dynamic>{};
    
    if (category != null) params['category'] = category;
    if (isActive != null) params['isActive'] = isActive;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortOrder != null) params['sortOrder'] = sortOrder;
    
    return params;
  }
  
  // ==================== VALIDACIONES ====================
  
  // Validar si un endpoint pertenece a auth service
  static bool isAuthEndpoint(String endpoint) {
    return endpoint.contains('/auth/') || 
           endpoint.contains('/tokens/') ||
           endpoint == login ||
           endpoint == register ||
           endpoint == logout;
  }
  
  // Validar si un endpoint pertenece a user service
  static bool isUserEndpoint(String endpoint) {
    return endpoint.contains('/users/') ||
           endpoint == userProfile ||
           endpoint == userStats ||
           endpoint == userActivity;
  }
  
  // 🆕 Validar si un endpoint pertenece a content service
  static bool isContentEndpoint(String endpoint) {
    return endpoint.contains('/content/') ||
           endpoint == allTips ||
           endpoint.startsWith(tips) ||
           endpoint.startsWith(news) ||
           endpoint.startsWith(projects) ||
           endpoint.startsWith(challenges) ||
           endpoint.startsWith(lessons);
  }
  
  // ==================== DEBUG Y LOGGING ====================
  
  // Obtener información del servicio para un endpoint
  static Map<String, dynamic> getEndpointInfo(String endpoint) {
    String service = 'unknown';
    String baseUrl = '';
    
    if (isAuthEndpoint(endpoint)) {
      service = 'auth';
      baseUrl = authServiceUrl;
    } else if (isUserEndpoint(endpoint)) {
      service = 'user';
      baseUrl = userServiceUrl;
    } else if (isContentEndpoint(endpoint)) {
      service = 'content';
      baseUrl = contentServiceUrl;
    }
    
    return {
      'service': service,
      'baseUrl': baseUrl,
      'fullUrl': '$baseUrl$endpoint',
      'endpoint': endpoint,
    };
  }
  
  // 🆕 Método para debug de endpoints
  static void debugEndpoint(String endpoint) {
    final info = getEndpointInfo(endpoint);
    print('🔍 [ENDPOINT DEBUG] ==================');
    print('🔍 Service: ${info['service']}');
    print('🔍 Base URL: ${info['baseUrl']}');
    print('🔍 Endpoint: ${info['endpoint']}');
    print('🔍 Full URL: ${info['fullUrl']}');
    print('🔍 =====================================');
  }
}