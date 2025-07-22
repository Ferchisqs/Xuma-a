// lib/core/config/quiz_api_endpoints.dart
class QuizApiEndpoints {
  // ==================== QUIZ BASE ENDPOINTS ====================
  
  // Obtener quizzes por tema
  static const String quizzesByTopic = '/by-topic/{topicId}';
  
  // Obtener quiz específico por ID
  static const String quizById = '/{id}';
  
  // Iniciar nueva sesión de quiz
  static const String startQuizSession = '/start';
  
  // Enviar respuesta de pregunta
  static const String submitAnswer = '/submit-answer';
  
  // Obtener resultados de sesión
  static const String quizResults = '/results/{sessionId}';
  
  // Obtener preguntas de un quiz
  static const String quizQuestions = '/questions/quiz/{quizId}';
  
  // Progreso del usuario
  static const String userProgress = '/user-progress/{userId}';
  
  // ==================== MÉTODOS HELPER ====================
  
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
  
  static String getUserProgress(String userId) {
    return userProgress.replaceAll('{userId}', userId);
  }
  
  // ==================== VALIDACIONES ====================
  
  static bool isQuizEndpoint(String endpoint) {
    return endpoint.contains('/by-topic/') ||
           endpoint.contains('/start') ||
           endpoint.contains('/submit-answer') ||
           endpoint.contains('/results/') ||
           endpoint.contains('/questions/quiz/') ||
           endpoint.contains('/user-progress/');
  }
  
  // ==================== CONFIGURACIÓN ====================
  
  static const Map<String, String> quizHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': '1.0',
    'X-Service': 'quiz',
  };
}