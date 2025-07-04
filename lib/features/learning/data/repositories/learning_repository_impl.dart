import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../domain/repositories/learning_repository.dart';
import '../datasources/learning_local_datasource.dart';
import '../datasources/learning_remote_datasource.dart';
import '../models/lesson_progress_model.dart';

@Injectable(as: LearningRepository)
class LearningRepositoryImpl implements LearningRepository {
  final LearningRemoteDataSource remoteDataSource;
  final LearningLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LearningRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteCategories = await remoteDataSource.getCategories();
          await localDataSource.cacheCategories(remoteCategories);
          return Right(remoteCategories);
        } catch (e) {
          // Si falla la conexión remota, usar caché
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
  Future<Either<Failure, List<LessonEntity>>> getLessonsByCategory(String categoryId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteLessons = await remoteDataSource.getLessonsByCategory(categoryId);
          await localDataSource.cacheLessonsByCategory(categoryId, remoteLessons);
          return Right(remoteLessons);
        } catch (e) {
          // Si falla la conexión remota, usar caché
          final localLessons = await localDataSource.getCachedLessonsByCategory(categoryId);
          return Right(localLessons);
        }
      } else {
        final localLessons = await localDataSource.getCachedLessonsByCategory(categoryId);
        return Right(localLessons);
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
  Future<Either<Failure, LessonEntity>> getLessonContent(String lessonId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteLesson = await remoteDataSource.getLessonContent(lessonId);
          await localDataSource.cacheLessonContent(remoteLesson);
          return Right(remoteLesson);
        } catch (e) {
          // Si falla la conexión remota, usar caché
          final localLesson = await localDataSource.getCachedLessonContent(lessonId);
          if (localLesson != null) {
            return Right(localLesson);
          } else {
            return Left(CacheFailure('Lección no encontrada en caché'));
          }
        }
      } else {
        final localLesson = await localDataSource.getCachedLessonContent(lessonId);
        if (localLesson != null) {
          return Right(localLesson);
        } else {
          return Left(CacheFailure('Lección no disponible sin conexión'));
        }
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
  Future<Either<Failure, LessonProgressEntity>> getLessonProgress(String lessonId, String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteProgress = await remoteDataSource.getLessonProgress(lessonId, userId);
          await localDataSource.cacheLessonProgress(remoteProgress);
          return Right(remoteProgress);
        } catch (e) {
          // Si falla la conexión remota, usar caché
          final localProgress = await localDataSource.getCachedLessonProgress(lessonId, userId);
          if (localProgress != null) {
            return Right(localProgress);
          } else {
            // Crear progreso inicial si no existe
            final initialProgress = LessonProgressModel(
              userId: userId,
              lessonId: lessonId,
              categoryId: '', // Se actualizará cuando se tenga la información
              progress: 0.0,
              isCompleted: false,
              timeSpent: 0,
              updatedAt: DateTime.now(),
            );
            return Right(initialProgress);
          }
        }
      } else {
        final localProgress = await localDataSource.getCachedLessonProgress(lessonId, userId);
        if (localProgress != null) {
          return Right(localProgress);
        } else {
          // Crear progreso inicial si no existe
          final initialProgress = LessonProgressModel(
            userId: userId,
            lessonId: lessonId,
            categoryId: '',
            progress: 0.0,
            isCompleted: false,
            timeSpent: 0,
            updatedAt: DateTime.now(),
          );
          return Right(initialProgress);
        }
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
  Future<Either<Failure, void>> updateLessonProgress(LessonProgressEntity progress) async {
    try {
      final progressModel = LessonProgressModel.fromEntity(progress);
      
      // Siempre guardar en caché local primero
      await localDataSource.cacheLessonProgress(progressModel);
      
      // Si hay conexión, sincronizar con servidor
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.updateLessonProgress(progressModel);
        } catch (e) {
          // Aunque falle la sincronización remota, el progreso local se mantiene
          // TODO: Implementar cola de sincronización para cuando vuelva la conexión
        }
      }
      
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> completeLesson(String lessonId, String userId) async {
    try {
      // Crear progreso de lección completada
      final completedProgress = LessonProgressModel(
        userId: userId,
        lessonId: lessonId,
        categoryId: '', // Se actualizará con la información correcta
        progress: 1.0,
        isCompleted: true,
        completedAt: DateTime.now(),
        timeSpent: 0, // Se podría calcular el tiempo real
        updatedAt: DateTime.now(),
      );
      
      // Guardar localmente
      await localDataSource.cacheLessonProgress(completedProgress);
      
      // Si hay conexión, sincronizar con servidor
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.completeLesson(lessonId, userId);
        } catch (e) {
          // Aunque falle la sincronización remota, la completación local se mantiene
        }
      }
      
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<LessonEntity>>> searchLessons(String query, String? categoryId) async {
    try {
      if (query.trim().isEmpty) {
        return const Right([]);
      }
      
      if (await networkInfo.isConnected) {
        try {
          final remoteLessons = await remoteDataSource.searchLessons(query, categoryId);
          return Right(remoteLessons);
        } catch (e) {
          // Si falla la búsqueda remota, usar búsqueda local
          final localLessons = await localDataSource.searchCachedLessons(query, categoryId);
          return Right(localLessons);
        }
      } else {
        final localLessons = await localDataSource.searchCachedLessons(query, categoryId);
        return Right(localLessons);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }
}