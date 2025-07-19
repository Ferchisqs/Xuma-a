// lib/core/config/api_endpoints.dart - COMPLETO CON COMPAÑEROS Y MÁS FUNCIONALIDADES
class ApiEndpoints {
  // ==================== SERVICIOS BASE ====================
  
  // 🌐 AUTH SERVICE - Para autenticación
  static const String authServiceUrl = 'https://auth-service-production-e333.up.railway.app';
  
  // 🌐 USER SERVICE - Para perfiles de usuario  
  static const String userServiceUrl = 'https://user-service-xumaa-production.up.railway.app';
  
  // 🌐 CONTENT SERVICE - Para tips, noticias, etc.
  static const String contentServiceUrl = 'https://content-service-xumaa-production.up.railway.app';

  // 🌐 GAMIFICATION SERVICE - Para mascotas y puntos
  static const String gamificationServiceUrl = 'https://gamification-service-production.up.railway.app';

  // 🌐 SOCIAL SERVICE - Para compañeros y funciones sociales
  static const String socialServiceUrl = 'https://social-service-production.up.railway.app';

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
  static const String userPreferences = '/api/users/preferences';
  static const String userAchievements = '/api/users/achievements';
  
  // ==================== CONTENIDO ====================
  static const String allTips = '/api/content/all-tips';
  static const String tips = '/api/content/tips';
  static const String news = '/api/content/news';
  static const String projects = '/api/content/projects';
  static const String challenges = '/api/content/challenges';
  static const String lessons = '/api/content/lessons';
  static const String courses = '/api/content/courses';
  static const String quizzes = '/api/content/quizzes';
  
  // ==================== GAMIFICACIÓN - MASCOTAS ====================
  
  // Mascotas del usuario
  static const String userPets = '/api/gamification/pets';
  
  // Adoptar mascota
  static const String adoptPet = '/api/gamification/pets/{userId}/adopt';
  
  // Destacar mascota (solo una activa a la vez)
  static const String featurePet = '/api/gamification/pets/{userId}/feature';
  
  // Evolucionar mascota
  static const String evolvePet = '/api/gamification/pets/{userId}/evolve';
  static const String evolveOwnedPet = '/api/gamification/pets/owned/{userId}/{petId}/evolve';
  
  // Seleccionar etapa visualizada
  static const String selectPetStage = '/api/gamification/pets/owned/{userId}/{petId}/selected-stage';
  
  // Tienda y disponibles
  static const String availablePets = '/api/gamification/pets/available';
  static const String petStore = '/api/gamification/pets/store';
  
  // Detalles específicos
  static const String petDetails = '/api/gamification/pets/{petId}/details';
  
  // Compra alternativa
  static const String purchasePet = '/api/gamification/pets/purchase';
  
  // CRUD mascotas
  static const String createPet = '/api/gamification/pets';
  static const String getPetById = '/api/gamification/pets/id/{petId}';
  
  // ==================== GAMIFICACIÓN - PUNTOS Y LOGROS ====================
  static const String userPoints = '/api/gamification/points/{userId}';
  static const String addPoints = '/api/gamification/points/{userId}/add';
  static const String spendPoints = '/api/gamification/points/{userId}/spend';
  static const String pointsHistory = '/api/gamification/points/{userId}/history';
  static const String leaderboard = '/api/gamification/leaderboard';
  static const String userRank = '/api/gamification/leaderboard/{userId}/rank';
  
  // Logros
  static const String achievements = '/api/gamification/achievements';
  static const String userAchievementsGamification = '/api/gamification/achievements/{userId}';
  static const String unlockAchievement = '/api/gamification/achievements/{userId}/unlock';
  
  // ==================== 🆕 COMPAÑEROS Y FUNCIONES SOCIALES ====================
  
  // Lista de compañeros
  static const String companions = '/api/social/companions';
  static const String userCompanions = '/api/social/companions/{userId}';
  
  // Enviar solicitud de amistad
  static const String sendFriendRequest = '/api/social/friends/request';
  
  // Gestionar solicitudes de amistad
  static const String friendRequests = '/api/social/friends/requests/{userId}';
  static const String acceptFriendRequest = '/api/social/friends/request/{requestId}/accept';
  static const String rejectFriendRequest = '/api/social/friends/request/{requestId}/reject';
  
  // Lista de amigos
  static const String friendsList = '/api/social/friends/{userId}';
  static const String removeFriend = '/api/social/friends/{userId}/remove/{friendId}';
  
  // Búsqueda de usuarios
  static const String searchUsers = '/api/social/users/search';
  static const String suggestedFriends = '/api/social/friends/{userId}/suggestions';
  
  // Chat y mensajería
  static const String conversations = '/api/social/conversations/{userId}';
  static const String createConversation = '/api/social/conversations';
  static const String conversationMessages = '/api/social/conversations/{conversationId}/messages';
  static const String sendMessage = '/api/social/conversations/{conversationId}/messages';
  static const String markAsRead = '/api/social/conversations/{conversationId}/read';
  
  // Actividades compartidas
  static const String sharedActivities = '/api/social/activities/{userId}';
  static const String createSharedActivity = '/api/social/activities';
  static const String joinActivity = '/api/social/activities/{activityId}/join';
  static const String leaveActivity = '/api/social/activities/{activityId}/leave';
  
  // Grupos de estudio
  static const String studyGroups = '/api/social/groups';
  static const String userStudyGroups = '/api/social/groups/{userId}';
  static const String createStudyGroup = '/api/social/groups';
  static const String joinStudyGroup = '/api/social/groups/{groupId}/join';
  static const String leaveStudyGroup = '/api/social/groups/{groupId}/leave';
  static const String studyGroupMembers = '/api/social/groups/{groupId}/members';
  
  // ==================== NOTIFICACIONES ====================
  static const String notifications = '/api/notifications/{userId}';
  static const String markNotificationRead = '/api/notifications/{notificationId}/read';
  static const String markAllNotificationsRead = '/api/notifications/{userId}/read-all';
  static const String deleteNotification = '/api/notifications/{notificationId}';
  static const String notificationSettings = '/api/notifications/{userId}/settings';
  
  // ==================== PROGRESO Y APRENDIZAJE ====================
  static const String userProgress = '/api/learning/progress/{userId}';
  static const String lessonProgress = '/api/learning/lessons/{lessonId}/progress/{userId}';
  static const String courseProgress = '/api/learning/courses/{courseId}/progress/{userId}';
  static const String completeLeason = '/api/learning/lessons/{lessonId}/complete';
  static const String completeCourse = '/api/learning/courses/{courseId}/complete';
  static const String quizResults = '/api/learning/quizzes/{quizId}/results/{userId}';
  static const String submitQuiz = '/api/learning/quizzes/{quizId}/submit';
  
  // ==================== MÉTODOS HELPER PARA MASCOTAS ====================
  
  static String getUserPets(String userId) {
    return '/api/gamification/pets/$userId';
  }
  
  static String getAdoptPet(String userId) {
    return adoptPet.replaceAll('{userId}', userId);
  }
  
  static String getFeaturePet(String userId) {
    return featurePet.replaceAll('{userId}', userId);
  }
  
  static String getEvolvePet(String userId) {
    return evolvePet.replaceAll('{userId}', userId);
  }
  
  static String getEvolveOwnedPet(String userId, String petId) {
    return evolveOwnedPet
        .replaceAll('{userId}', userId)
        .replaceAll('{petId}', petId);
  }
  
  static String getSelectPetStage(String userId, String petId) {
    return selectPetStage
        .replaceAll('{userId}', userId)
        .replaceAll('{petId}', petId);
  }
  
  static String getPetDetails(String petId) {
    return petDetails.replaceAll('{petId}', petId);
  }
  
  static String getPetByIdPath(String petId) {
    return getPetById.replaceAll('{petId}', petId);
  }
  
  // ==================== 🆕 MÉTODOS HELPER PARA GAMIFICACIÓN ====================
  
  static String getUserPoints(String userId) {
    return userPoints.replaceAll('{userId}', userId);
  }
  
  static String getAddPoints(String userId) {
    return addPoints.replaceAll('{userId}', userId);
  }
  
  static String getSpendPoints(String userId) {
    return spendPoints.replaceAll('{userId}', userId);
  }
  
  static String getPointsHistory(String userId) {
    return pointsHistory.replaceAll('{userId}', userId);
  }
  
  static String getUserRank(String userId) {
    return userRank.replaceAll('{userId}', userId);
  }
  
  static String getUserAchievementsGamification(String userId) {
    return userAchievementsGamification.replaceAll('{userId}', userId);
  }
  
  static String getUnlockAchievement(String userId) {
    return unlockAchievement.replaceAll('{userId}', userId);
  }
  
  // ==================== 🆕 MÉTODOS HELPER PARA COMPAÑEROS Y SOCIAL ====================
  
  static String getUserCompanions(String userId) {
    return userCompanions.replaceAll('{userId}', userId);
  }
  
  static String getFriendRequests(String userId) {
    return friendRequests.replaceAll('{userId}', userId);
  }
  
  static String getAcceptFriendRequest(String requestId) {
    return acceptFriendRequest.replaceAll('{requestId}', requestId);
  }
  
  static String getRejectFriendRequest(String requestId) {
    return rejectFriendRequest.replaceAll('{requestId}', requestId);
  }
  
  static String getFriendsList(String userId) {
    return friendsList.replaceAll('{userId}', userId);
  }
  
  static String getRemoveFriend(String userId, String friendId) {
    return removeFriend
        .replaceAll('{userId}', userId)
        .replaceAll('{friendId}', friendId);
  }
  
  static String getSuggestedFriends(String userId) {
    return suggestedFriends.replaceAll('{userId}', userId);
  }
  
  static String getConversations(String userId) {
    return conversations.replaceAll('{userId}', userId);
  }
  
  static String getConversationMessages(String conversationId) {
    return conversationMessages.replaceAll('{conversationId}', conversationId);
  }
  
  static String getSendMessage(String conversationId) {
    return sendMessage.replaceAll('{conversationId}', conversationId);
  }
  
  static String getMarkAsRead(String conversationId) {
    return markAsRead.replaceAll('{conversationId}', conversationId);
  }
  
  static String getSharedActivities(String userId) {
    return sharedActivities.replaceAll('{userId}', userId);
  }
  
  static String getJoinActivity(String activityId) {
    return joinActivity.replaceAll('{activityId}', activityId);
  }
  
  static String getLeaveActivity(String activityId) {
    return leaveActivity.replaceAll('{activityId}', activityId);
  }
  
  static String getUserStudyGroups(String userId) {
    return userStudyGroups.replaceAll('{userId}', userId);
  }
  
  static String getJoinStudyGroup(String groupId) {
    return joinStudyGroup.replaceAll('{groupId}', groupId);
  }
  
  static String getLeaveStudyGroup(String groupId) {
    return leaveStudyGroup.replaceAll('{groupId}', groupId);
  }
  
  static String getStudyGroupMembers(String groupId) {
    return studyGroupMembers.replaceAll('{groupId}', groupId);
  }
  
  // ==================== 🆕 MÉTODOS HELPER PARA NOTIFICACIONES ====================
  
  static String getNotifications(String userId) {
    return notifications.replaceAll('{userId}', userId);
  }
  
  static String getMarkNotificationRead(String notificationId) {
    return markNotificationRead.replaceAll('{notificationId}', notificationId);
  }
  
  static String getMarkAllNotificationsRead(String userId) {
    return markAllNotificationsRead.replaceAll('{userId}', userId);
  }
  
  static String getDeleteNotification(String notificationId) {
    return deleteNotification.replaceAll('{notificationId}', notificationId);
  }
  
  static String getNotificationSettings(String userId) {
    return notificationSettings.replaceAll('{userId}', userId);
  }
  
  // ==================== 🆕 MÉTODOS HELPER PARA APRENDIZAJE ====================
  
  static String getUserProgress(String userId) {
    return userProgress.replaceAll('{userId}', userId);
  }
  
  static String getLessonProgress(String lessonId, String userId) {
    return lessonProgress
        .replaceAll('{lessonId}', lessonId)
        .replaceAll('{userId}', userId);
  }
  
  static String getCourseProgress(String courseId, String userId) {
    return courseProgress
        .replaceAll('{courseId}', courseId)
        .replaceAll('{userId}', userId);
  }
  
  static String getCompleteLeason(String lessonId) {
    return completeLeason.replaceAll('{lessonId}', lessonId);
  }
  
  static String getCompleteCourse(String courseId) {
    return completeCourse.replaceAll('{courseId}', courseId);
  }
  
  static String getQuizResults(String quizId, String userId) {
    return quizResults
        .replaceAll('{quizId}', quizId)
        .replaceAll('{userId}', userId);
  }
  
  static String getSubmitQuiz(String quizId) {
    return submitQuiz.replaceAll('{quizId}', quizId);
  }
  
  // ==================== MÉTODOS HELPER PARA CONTENIDO ====================
  
  static String getTipById(String id) {
    return '$tips/$id';
  }
  
  static String updateTip(String id) {
    return '$tips/$id';
  }
  
  static String deleteTip(String id) {
    return '$tips/$id';
  }
  
  static String getNewsById(String id) {
    return '$news/$id';
  }
  
  static String getProjectById(String id) {
    return '$projects/$id';
  }
  
  static String getChallengeById(String id) {
    return '$challenges/$id';
  }
  
  static String getLessonById(String id) {
    return '$lessons/$id';
  }
  
  static String getCourseById(String id) {
    return '$courses/$id';
  }
  
  static String getQuizById(String id) {
    return '$quizzes/$id';
  }
  
  // ==================== MÉTODOS HELPER PARA AUTH ====================
  
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
  
  // ==================== MÉTODOS DE SERVICIOS ====================
  
  // Método para obtener URL completa según el servicio
  static String getFullUrl(String endpoint, {String? service}) {
    switch (service?.toLowerCase()) {
      case 'auth':
        return '$authServiceUrl$endpoint';
      case 'user':
        return '$userServiceUrl$endpoint';
      case 'content':
        return '$contentServiceUrl$endpoint';
      case 'gamification':
        return '$gamificationServiceUrl$endpoint';
      case 'social':
        return '$socialServiceUrl$endpoint';
      default:
        // Por defecto usar auth service para compatibilidad
        return '$authServiceUrl$endpoint';
    }
  }
  
  // Métodos específicos para cada servicio
  static String getAuthUrl(String endpoint) => '$authServiceUrl$endpoint';
  static String getUserUrl(String endpoint) => '$userServiceUrl$endpoint';
  static String getContentUrl(String endpoint) => '$contentServiceUrl$endpoint';
  static String getGamificationUrl(String endpoint) => '$gamificationServiceUrl$endpoint';
  static String getSocialUrl(String endpoint) => '$socialServiceUrl$endpoint';
  
  // ==================== VALIDACIONES ====================
  
  static bool isAuthEndpoint(String endpoint) {
    return endpoint.contains('/auth/') || 
           endpoint.contains('/tokens/') ||
           endpoint == login ||
           endpoint == register ||
           endpoint == logout;
  }
  
  static bool isUserEndpoint(String endpoint) {
    return endpoint.contains('/users/') ||
           endpoint == userProfile ||
           endpoint == userStats ||
           endpoint == userActivity ||
           endpoint == userPreferences ||
           endpoint == userAchievements;
  }
  
  static bool isContentEndpoint(String endpoint) {
    return endpoint.contains('/content/') ||
           endpoint == allTips ||
           endpoint.startsWith(tips) ||
           endpoint.startsWith(news) ||
           endpoint.startsWith(projects) ||
           endpoint.startsWith(challenges) ||
           endpoint.startsWith(lessons) ||
           endpoint.startsWith(courses) ||
           endpoint.startsWith(quizzes);
  }
  
  static bool isGamificationEndpoint(String endpoint) {
    return endpoint.contains('/gamification/') ||
           endpoint.contains('/pets/') ||
           endpoint.contains('/points/') ||
           endpoint.contains('/achievements/') ||
           endpoint.startsWith(userPets) ||
           endpoint.startsWith('/api/gamification/');
  }
  
  // 🆕 Validar si un endpoint pertenece a social service
  static bool isSocialEndpoint(String endpoint) {
    return endpoint.contains('/social/') ||
           endpoint.contains('/companions/') ||
           endpoint.contains('/friends/') ||
           endpoint.contains('/conversations/') ||
           endpoint.contains('/activities/') ||
           endpoint.contains('/groups/') ||
           endpoint.startsWith('/api/social/');
  }
  
  // 🆕 Validar si un endpoint pertenece a learning/progress
  static bool isLearningEndpoint(String endpoint) {
    return endpoint.contains('/learning/') ||
           endpoint.startsWith('/api/learning/');
  }
  
  // 🆕 Validar si un endpoint pertenece a notifications
  static bool isNotificationEndpoint(String endpoint) {
    return endpoint.contains('/notifications/') ||
           endpoint.startsWith('/api/notifications/');
  }
  
  // ==================== CONFIGURACIÓN ====================
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
  };
  
  static const Map<String, String> contentHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'content',
  };
  
  static const Map<String, String> gamificationHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'gamification',
  };
  
  // 🆕 Headers para social service
  static const Map<String, String> socialHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'social',
  };
  
  // ==================== PARÁMETROS DE CONSULTA ====================
  
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
  
  // Parámetros para filtros de contenido
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
  
  // 🆕 Parámetros para búsqueda de usuarios
  static Map<String, dynamic> getUserSearchParams({
    String? query,
    int? ageMin,
    int? ageMax,
    List<String>? interests,
    bool? onlineOnly,
  }) {
    final params = <String, dynamic>{};
    
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (ageMin != null) params['ageMin'] = ageMin;
    if (ageMax != null) params['ageMax'] = ageMax;
    if (interests != null && interests.isNotEmpty) params['interests'] = interests.join(',');
    if (onlineOnly != null) params['onlineOnly'] = onlineOnly;
    
    return params;
  }
  
  // 🆕 Parámetros para mensajes
  static Map<String, dynamic> getMessageParams({
    int? limit,
    String? before,
    String? after,
  }) {
    final params = <String, dynamic>{};
    
    if (limit != null) params['limit'] = limit;
    if (before != null) params['before'] = before;
    if (after != null) params['after'] = after;
    
    return params;
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
    } else if (isGamificationEndpoint(endpoint)) {
      service = 'gamification';
      baseUrl = gamificationServiceUrl;
    } else if (isSocialEndpoint(endpoint)) {
      service = 'social';
      baseUrl = socialServiceUrl;
    }
    
    return {
      'service': service,
      'baseUrl': baseUrl,
      'fullUrl': '$baseUrl$endpoint',
      'endpoint': endpoint,
    };
  }
  
  // Método para debug de endpoints
  static void debugEndpoint(String endpoint) {
    final info = getEndpointInfo(endpoint);
    print('🔍 [ENDPOINT DEBUG] ==================');
    print('🔍 Service: ${info['service']}');
    print('🔍 Base URL: ${info['baseUrl']}');
    print('🔍 Endpoint: ${info['endpoint']}');
    print('🔍 Full URL: ${info['fullUrl']}');
    print('🔍 =====================================');
  }
  
  // 🆕 Obtener headers apropiados según el servicio
  static Map<String, String> getServiceHeaders(String endpoint) {
    if (isSocialEndpoint(endpoint)) {
      return socialHeaders;
    } else if (isGamificationEndpoint(endpoint)) {
      return gamificationHeaders;
    } else if (isContentEndpoint(endpoint)) {
      return contentHeaders;
    } else {
      return defaultHeaders;
    }
  }
}