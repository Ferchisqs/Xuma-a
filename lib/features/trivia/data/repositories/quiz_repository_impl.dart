// lib/features/trivia/data/repositories/quiz_repository_impl.dart
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_result_entity.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/quiz_session_entity.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';
import '../datasources/trivia_local_datasource.dart';
import '../models/quiz_session_model.dart';

@Injectable(as: QuizRepository)
class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;
  final TriviaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  QuizRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) {
    print('✅ [QUIZ REPOSITORY] Constructor - Quiz repository initialized');
  }

  @override
  Future<Either<Failure, List<TriviaCategoryEntity>>> getCategories() async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting categories (topics) for quiz');
      
      if (await networkInfo.isConnected) {
        try {
          // Obtener topics y convertirlos a categorías
          final topics = await remoteDataSource.getTopics();
          
          // Convertir topics a categorías de trivia
          final categories = topics.map((topic) {
            return TriviaCategoryEntity(
              id: topic.id,
              title: topic.title,
              description: topic.description,
              imageUrl: topic.imageUrl ?? '',
              iconCode: _getIconForCategory(topic.category),
              questionsCount: 10, // Default
              completedTrivias: 0,
              difficulty: TriviaDifficulty.medium,
              pointsPerQuestion: 5,
              timePerQuestion: 30,
              createdAt: topic.createdAt,
            );
          }).toList();
          
          print('✅ [QUIZ REPOSITORY] Successfully converted ${categories.length} topics to categories');
          return Right(categories);
        } catch (e) {
          print('⚠️ [QUIZ REPOSITORY] Remote fetch failed: $e');
          return Left(ServerFailure('Error obteniendo categorías: ${e.toString()}'));
        }
      } else {
        print('📱 [QUIZ REPOSITORY] No network available');
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } catch (e) {
      print('❌ [QUIZ REPOSITORY] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuestionsByCategory(String categoryId) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting questions for category: $categoryId');
      
      if (await networkInfo.isConnected) {
        try {
          // Por ahora usar datos locales, después conectar con quiz API
          final localQuestions = await localDataSource.getCachedQuestions(categoryId);
          return Right(localQuestions);
        } catch (e) {
          print('⚠️ [QUIZ REPOSITORY] Error getting questions: $e');
          return Left(ServerFailure('Error obteniendo preguntas: ${e.toString()}'));
        }
      } else {
        final localQuestions = await localDataSource.getCachedQuestions(categoryId);
        return Right(localQuestions);
      }
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting quizzes for topic: $topicId');
      
      if (await networkInfo.isConnected) {
        final quizzes = await remoteDataSource.getQuizzesByTopic(topicId);
        print('✅ [QUIZ REPOSITORY] Successfully fetched ${quizzes.length} quizzes for topic');
        return Right(quizzes);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo quizzes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting quiz by ID: $quizId');
      
      if (await networkInfo.isConnected) {
        final quiz = await remoteDataSource.getQuizById(quizId);
        print('✅ [QUIZ REPOSITORY] Successfully fetched quiz: $quizId');
        return Right(quiz);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo quiz: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, QuizSessionEntity>> startQuizSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Starting quiz session: $quizId for user: $userId');
      
      if (await networkInfo.isConnected) {
        final session = await remoteDataSource.startQuizSession(
          quizId: quizId,
          userId: userId,
        );
        print('✅ [QUIZ REPOSITORY] Successfully started quiz session: ${session.sessionId}');
        return Right(session);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error iniciando sesión de quiz: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> submitQuizAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  }) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Submitting answer for session: $sessionId');
      
      if (await networkInfo.isConnected) {
        await remoteDataSource.submitAnswer(
          sessionId: sessionId,
          questionId: questionId,
          userId: userId,
          selectedOptionId: selectedOptionId,
          timeTakenSeconds: timeTakenSeconds,
          answerConfidence: answerConfidence,
        );
        print('✅ [QUIZ REPOSITORY] Answer submitted successfully');
        return const Right(null);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error enviando respuesta: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQuizResults({
    required String sessionId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting quiz results for session: $sessionId');
      
      if (await networkInfo.isConnected) {
        final results = await remoteDataSource.getQuizResults(
          sessionId: sessionId,
          userId: userId,
        );
        print('✅ [QUIZ REPOSITORY] Successfully fetched quiz results');
        return Right(results);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo resultados: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuizQuestions(String quizId) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting questions for quiz: $quizId');
      
      if (await networkInfo.isConnected) {
        final questions = await remoteDataSource.getQuizQuestions(quizId);
        print('✅ [QUIZ REPOSITORY] Successfully fetched ${questions.length} questions');
        return Right(questions);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo preguntas del quiz: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserQuizProgress(String userId) async {
    try {
      print('🎯 [QUIZ REPOSITORY] Getting user progress: $userId');
      
      if (await networkInfo.isConnected) {
        final progress = await remoteDataSource.getUserProgress(userId);
        print('✅ [QUIZ REPOSITORY] Successfully fetched user progress');
        return Right(progress);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo progreso del usuario: ${e.toString()}'));
    }
  }

  // Métodos heredados de TriviaRepository
  @override
  Future<Either<Failure, TriviaResultEntity>> submitTriviaResult({
    required String userId,
    required String categoryId,
    required List<String> questionIds,
    required List<int> userAnswers,
    required Duration totalTime,
  }) async {
    // Implementación básica - se puede mejorar después
    return Left(UnknownFailure('Método no implementado aún'));
  }

  @override
  Future<Either<Failure, List<TriviaResultEntity>>> getUserTriviaHistory(String userId) async {
    // Implementación básica - se puede mejorar después
    return Left(UnknownFailure('Método no implementado aún'));
  }

  // ==================== HELPER METHODS ====================

  int _getIconForCategory(String category) {
    final categoryLower = category.toLowerCase();
    
    switch (categoryLower) {
      case 'reciclaje':
      case 'recycling':
        return 0xe567; // Icons.recycling
      case 'agua':
      case 'water':
        return 0xe798; // Icons.water_drop
      case 'energia':
      case 'energy':
        return 0xe1ac; // Icons.energy_savings_leaf
      case 'clima':
      case 'climate':
        return 0xe1b0; // Icons.co2
      case 'conservacion':
      case 'conservation':
        return 0xe1d8; // Icons.auto_fix_high
      default:
        return 0xe1b1; // Icons.compost
    }
  }
}