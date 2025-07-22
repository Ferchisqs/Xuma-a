// lib/features/trivia/data/repositories/quiz_repository_impl.dart
import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/trivia_result_entity.dart';
import '../../domain/entities/quiz_session_entity.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/trivia_local_datasource.dart';
import '../datasources/quiz_remote_datasource.dart';
import '../models/trivia_result_model.dart';

@Injectable(as: QuizRepository)
class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;
  final TriviaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  QuizRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ==================== MÉTODOS EXISTENTES ====================
  
  @override
  Future<Either<Failure, List<TriviaCategoryEntity>>> getCategories() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          // Por ahora usar datos locales hasta que tengamos endpoint de categorías
          final localCategories = await localDataSource.getCachedCategories();
          return Right(localCategories);
        } catch (e) {
          final localCategories = await localDataSource.getCachedCategories();
          return Right(localCategories);
        }
      } else {
        final localCategories = await localDataSource.getCachedCategories();
        return Right(localCategories);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuestionsByCategory(String categoryId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final localQuestions = await localDataSource.getCachedQuestions(categoryId);
          return Right(localQuestions);
        } catch (e) {
          final localQuestions = await localDataSource.getCachedQuestions(categoryId);
          return Right(localQuestions);
        }
      } else {
        final localQuestions = await localDataSource.getCachedQuestions(categoryId);
        return Right(localQuestions);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TriviaResultEntity>> submitTriviaResult({
    required String userId,
    required String categoryId,
    required List<String> questionIds,
    required List<int> userAnswers,
    required Duration totalTime,
  }) async {
    try {
      final questionsResult = await getQuestionsByCategory(categoryId);
      
      return questionsResult.fold(
        (failure) => Left(failure),
        (questions) async {
          final correctAnswers = <bool>[];
          int correctCount = 0;
          
          for (int i = 0; i < userAnswers.length; i++) {
            final isCorrect = userAnswers[i] == questions[i].correctAnswerIndex;
            correctAnswers.add(isCorrect);
            if (isCorrect) correctCount++;
          }
          
          final totalPoints = questions.fold<int>(0, (sum, q) => sum + q.points);
          final earnedPoints = (correctCount / questions.length * totalPoints).round();
          
          final result = TriviaResultModel(
            id: 'result_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            categoryId: categoryId,
            questionIds: questionIds,
            userAnswers: userAnswers,
            correctAnswers: correctAnswers,
            totalQuestions: questions.length,
            correctCount: correctCount,
            totalPoints: totalPoints,
            earnedPoints: earnedPoints,
            totalTime: totalTime,
            completedAt: DateTime.now(),
          );
          
          await localDataSource.cacheResult(result);
          return Right(result);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Error procesando resultado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TriviaResultEntity>>> getUserTriviaHistory(String userId) async {
    try {
      final results = await localDataSource.getCachedResults(userId);
      return Right(results);
    } catch (e) {
      return Left(CacheFailure('Error obteniendo historial: ${e.toString()}'));
    }
  }

  // ==================== 🆕 NUEVOS MÉTODOS PARA QUIZ SESSIONS ====================

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId) async {
    try {
      if (await networkInfo.isConnected) {
        final quizzes = await remoteDataSource.getQuizzesByTopic(topicId);
        return Right(quizzes);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo quizzes por tema: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId) async {
    try {
      if (await networkInfo.isConnected) {
        final quiz = await remoteDataSource.getQuizById(quizId);
        return Right(quiz);
      } else {
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error obteniendo quiz por ID: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, QuizSessionEntity>> startQuizSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final session = await remoteDataSource.startQuizSession(
          quizId: quizId,
          userId: userId,
        );
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
      if (await networkInfo.isConnected) {
        await remoteDataSource.submitAnswer(
          sessionId: sessionId,
          questionId: questionId,
          userId: userId,
          selectedOptionId: selectedOptionId,
          timeTakenSeconds: timeTakenSeconds,
          answerConfidence: answerConfidence,
        );
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
      if (await networkInfo.isConnected) {
        final results = await remoteDataSource.getQuizResults(
          sessionId: sessionId,
          userId: userId,
        );
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
      if (await networkInfo.isConnected) {
        final questions = await remoteDataSource.getQuizQuestions(quizId);
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
      if (await networkInfo.isConnected) {
        final progress = await remoteDataSource.getUserProgress(userId);
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
}