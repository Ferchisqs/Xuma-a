// lib/features/trivia/domain/repositories/trivia_repository.dart - ACTUALIZADO
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_category_entity.dart';
import '../entities/trivia_question_entity.dart';
import '../entities/trivia_result_entity.dart';

abstract class TriviaRepository {
  // 🔧 MÉTODOS EXISTENTES - ahora getCategories usa topics endpoint
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

  // 🆕 NUEVOS MÉTODOS PARA QUIZ ENDPOINTS
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId);
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId);
}