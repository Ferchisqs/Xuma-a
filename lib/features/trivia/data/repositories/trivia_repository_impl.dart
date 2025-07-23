// lib/features/trivia/data/repositories/trivia_repository_impl.dart - ACTUALIZADO
import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/trivia_result_entity.dart';
import '../../domain/repositories/trivia_repository.dart';
import '../datasources/trivia_local_datasource.dart';
import '../datasources/trivia_remote_datasource.dart';
import '../models/trivia_result_model.dart';

@Injectable(as: TriviaRepository)
class TriviaRepositoryImpl implements TriviaRepository {
  final TriviaRemoteDataSource remoteDataSource;
  final TriviaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TriviaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) {
    print('✅ [TRIVIA REPOSITORY] Constructor - Now using topics endpoint for categories');
  }

  @override
  Future<Either<Failure, List<TriviaCategoryEntity>>> getCategories() async {
    try {
      print('🎯 [TRIVIA REPOSITORY] Getting trivia categories from topics endpoint');
      
      if (await networkInfo.isConnected) {
        try {
          // 🔧 AHORA USA EL ENDPOINT DE TOPICS
          final remoteCategories = await remoteDataSource.getCategories();
          await localDataSource.cacheCategories(remoteCategories);
          
          print('✅ [TRIVIA REPOSITORY] Successfully fetched ${remoteCategories.length} categories from topics');
          return Right(remoteCategories);
        } catch (e) {
          print('⚠️ [TRIVIA REPOSITORY] Remote fetch failed, using local cache: $e');
          final localCategories = await localDataSource.getCachedCategories();
          return Right(localCategories);
        }
      } else {
        print('📱 [TRIVIA REPOSITORY] No network, using local cache');
        final localCategories = await localDataSource.getCachedCategories();
        return Right(localCategories);
      }
    } on ServerException catch (e) {
      print('❌ [TRIVIA REPOSITORY] Server exception: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ [TRIVIA REPOSITORY] Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [TRIVIA REPOSITORY] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> getQuestionsByCategory(String categoryId) async {
    try {
      print('🎯 [TRIVIA REPOSITORY] Getting questions for category: $categoryId');
      
      if (await networkInfo.isConnected) {
        try {
          final remoteQuestions = await remoteDataSource.getQuestionsByCategory(categoryId);
          await localDataSource.cacheQuestions(categoryId, remoteQuestions);
          
          print('✅ [TRIVIA REPOSITORY] Successfully fetched ${remoteQuestions.length} questions');
          return Right(remoteQuestions);
        } catch (e) {
          print('⚠️ [TRIVIA REPOSITORY] Remote questions fetch failed, using local cache: $e');
          final localQuestions = await localDataSource.getCachedQuestions(categoryId);
          return Right(localQuestions);
        }
      } else {
        print('📱 [TRIVIA REPOSITORY] No network, using local questions cache');
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
      // Obtener preguntas para calcular respuestas correctas
      final questionsResult = await getQuestionsByCategory(categoryId);
      
      return questionsResult.fold(
        (failure) => Left(failure),
        (questions) async {
          // Calcular resultados
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
          
          // Guardar resultado localmente
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

  // 🆕 NUEVOS MÉTODOS PARA QUIZ ENDPOINTS

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [TRIVIA REPOSITORY] Getting quizzes for topic: $topicId');
      
      if (await networkInfo.isConnected) {
        final quizzes = await remoteDataSource.getQuizzesByTopic(topicId);
        print('✅ [TRIVIA REPOSITORY] Successfully fetched ${quizzes.length} quizzes for topic');
        return Right(quizzes);
      } else {
        print('📱 [TRIVIA REPOSITORY] No network for quiz fetch');
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      print('❌ [TRIVIA REPOSITORY] Server exception getting quizzes: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [TRIVIA REPOSITORY] Unknown error getting quizzes: $e');
      return Left(UnknownFailure('Error obteniendo quizzes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getQuizById(String quizId) async {
    try {
      print('🎯 [TRIVIA REPOSITORY] Getting quiz by ID: $quizId');
      
      if (await networkInfo.isConnected) {
        final quiz = await remoteDataSource.getQuizById(quizId);
        print('✅ [TRIVIA REPOSITORY] Successfully fetched quiz: $quizId');
        return Right(quiz);
      } else {
        print('📱 [TRIVIA REPOSITORY] No network for quiz by ID fetch');
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      print('❌ [TRIVIA REPOSITORY] Server exception getting quiz by ID: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [TRIVIA REPOSITORY] Unknown error getting quiz by ID: $e');
      return Left(UnknownFailure('Error obteniendo quiz: ${e.toString()}'));
    }
  }
}