// lib/features/trivia/domain/repositories/quiz_repository.dart
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_category_entity.dart';
import '../entities/trivia_question_entity.dart';
import '../entities/trivia_result_entity.dart';
import '../entities/quiz_session_entity.dart';

abstract class QuizRepository {
  // Métodos existentes
  Future<Either<Failure, List<TriviaCategoryEntity>>> getCategories();
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuestionsByCategory(String categoryId);
  Future<Either<Failure, TriviaResultEntity>> submitTriviaResult({
    required String userId,
    required String categoryId,
    required List<String> questionIds,
    required List<int> userAnswers,
    required Duration totalTime,
  });
  Future<Either<Failure, List<TriviaResultEntity>>> getUserTriviaHistory(String userId);

  // 🆕 NUEVOS MÉTODOS PARA QUIZ SESSIONS
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId);
  
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId);
  
  Future<Either<Failure, QuizSessionEntity>> startQuizSession({
    required String quizId,
    required String userId,
  });
  
  Future<Either<Failure, void>> submitQuizAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  });
  
  Future<Either<Failure, Map<String, dynamic>>> getQuizResults({
    required String sessionId,
    required String userId,
  });
  
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuizQuestions(String quizId);
  
  Future<Either<Failure, Map<String, dynamic>>> getUserQuizProgress(String userId);
}