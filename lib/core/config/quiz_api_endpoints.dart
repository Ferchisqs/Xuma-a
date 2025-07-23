// lib/core/config/quiz_api_endpoints.dart - CORREGIDO
class QuizApiEndpoints {
  // ==================== QUIZ BASE ENDPOINTS - CORREGIDOS ====================
  
  // 🔧 TODOS AHORA TIENEN EL PREFIJO /api/quiz/
  
  // Obtener quizzes por tema
  static const String quizzesByTopic = '/api/quiz/by-topic/{topicId}';
  
  // Obtener quiz específico por ID
  static const String quizById = '/api/quiz/{id}';
  
  // Iniciar nueva sesión de quiz
  static const String startQuizSession = '/api/quiz/start';
  
  // Enviar respuesta de pregunta
  static const String submitAnswer = '/api/quiz/submit-answer';
  
  // Obtener resultados de sesión
  static const String quizResults = '/api/quiz/results/{sessionId}';
  
  // Obtener preguntas de un quiz
  static const String quizQuestions = '/api/quiz/questions/quiz/{quizId}';
  
  // 🆕 NUEVO: Obtener pregunta por ID
  static const String questionById = '/api/quiz/questions/{questionId}';
  
  // Progreso del usuario
  static const String userProgress = '/api/quiz/user-progress/{userId}';
  
  // ==================== MÉTODOS HELPER - ACTUALIZADOS ====================
  
  static String getQuizzesByTopic(String topicId) {
    return quizzesByTopic.replaceAll('{topicId}', topicId);
  }
  
  static String getQuizById(String quizId) {
    return quizById.replaceAll('{id}', quizId);
  }
  
  static String getQuizResults(String sessionId) {
    return quizResults.replaceAll('{sessionId}', sessionId);
  }
  
  static String getQuizQuestions(String quizId) {
    return quizQuestions.replaceAll('{quizId}', quizId);
  }
  
  // 🆕 NUEVO MÉTODO
  static String getQuestionById(String questionId) {
    return questionById.replaceAll('{questionId}', questionId);
  }
  
  static String getUserProgress(String userId) {
    return userProgress.replaceAll('{userId}', userId);
  }
  
  // ==================== VALIDACIONES - ACTUALIZADAS ====================
  
  static bool isQuizEndpoint(String endpoint) {
    return endpoint.contains('/api/quiz/by-topic/') ||
           endpoint.contains('/api/quiz/start') ||
           endpoint.contains('/api/quiz/submit-answer') ||
           endpoint.contains('/api/quiz/results/') ||
           endpoint.contains('/api/quiz/questions/quiz/') ||
           endpoint.contains('/api/quiz/questions/') ||
           endpoint.contains('/api/quiz/user-progress/');
  }
  
  // ==================== CONFIGURACIÓN ====================
  
  static const Map<String, String> quizHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'quiz',
  };
}