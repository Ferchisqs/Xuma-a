// lib/features/trivia/domain/repositories/quiz_repository.dart - ACTUALIZADO
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_category_entity.dart';
import '../entities/trivia_question_entity.dart';
import '../entities/trivia_result_entity.dart';
import '../entities/quiz_session_entity.dart';

abstract class QuizRepository {
  // ==================== FLUJO PRINCIPAL DEL QUIZ ====================
  // 1. /api/content/topics (YA EXISTÍA)
  Future<Either<Failure, List<TriviaCategoryEntity>>> getCategories();
  
  // 2. /api/quiz/by-topic/{topicId} (NUEVO)
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId);
  
  // 3. /api/quiz/{id} (NUEVO)
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId);
  
  // 4. /api/quiz/questions/quiz/{quizId} (YA EXISTÍA - MEJORADO)
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuizQuestions(String quizId);
  
  // 5. /api/quiz/questions/{questionId} (NUEVO)
  Future<Either<Failure, Map<String, dynamic>>> getQuestionById(String questionId);

  // ==================== FUNCIONALIDADES DE SESIÓN ====================
  // Iniciar sesión de quiz
  Future<Either<Failure, QuizSessionEntity>> startQuizSession({
    required String quizId,
    required String userId,
  });
  
  // Enviar respuesta
  Future<Either<Failure, void>> submitQuizAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  });
  
  // Obtener resultados
  Future<Either<Failure, Map<String, dynamic>>> getQuizResults({
    required String sessionId,
    required String userId,
  });
  
  // Progreso del usuario
  Future<Either<Failure, Map<String, dynamic>>> getUserQuizProgress(String userId);

  // ==================== MÉTODOS LEGACY (PARA COMPATIBILIDAD) ====================
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuestionsByCategory(String categoryId);
  Future<Either<Failure, TriviaResultEntity>> submitTriviaResult({
    required String userId,
    required String categoryId,
    required List<String> questionIds,
    required List<int> userAnswers,
    required Duration totalTime,
  });
  Future<Either<Failure, List<TriviaResultEntity>>> getUserTriviaHistory(String userId);
}

