// lib/features/challenges/data/repositories/challenges_repository_impl.dart - ACTUALIZADO PARA API
import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/user_challenge_stats_entity.dart';
import '../../domain/entities/challenge_progress_entity.dart';
import '../../domain/repositories/challenges_repository.dart';
import '../datasources/challenges_local_datasource.dart';
import '../datasources/challenges_remote_datasource.dart';
import '../models/challenge_model.dart';
import '../../../learning/data/models/topic_model.dart';

@Injectable(as: ChallengesRepository)
class ChallengesRepositoryImpl implements ChallengesRepository {
  final ChallengesRemoteDataSource remoteDataSource;
  final ChallengesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ChallengesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) {
    print('✅ [CHALLENGES REPOSITORY] Constructor - Now using API endpoints');
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getChallenges({
    ChallengeType? type,
    String? category,
  }) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting challenges from API');
      print('🎯 [CHALLENGES REPOSITORY] Type: $type, Category: $category');
      
      if (await networkInfo.isConnected) {
        try {
          // 🔧 USAR API REAL
          final remoteChallenges = await remoteDataSource.getChallenges(
            type: type,
            category: category,
          );
          
          // Cache los challenges obtenidos
          await localDataSource.cacheChallenges(remoteChallenges);
          
          print('✅ [CHALLENGES REPOSITORY] Successfully fetched ${remoteChallenges.length} challenges from API');
          return Right(remoteChallenges);
          
        } catch (e) {
          print('⚠️ [CHALLENGES REPOSITORY] API fetch failed, using local cache: $e');
          final localChallenges = await localDataSource.getCachedChallenges();
          return Right(localChallenges);
        }
      } else {
        print('📱 [CHALLENGES REPOSITORY] No network, using local cache');
        final localChallenges = await localDataSource.getCachedChallenges();
        return Right(localChallenges);
      }
    } on ServerException catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Server exception: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChallengeEntity>> getChallengeById(String id) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting challenge by ID: $id');
      
      if (await networkInfo.isConnected) {
        try {
          // 🔧 USAR API REAL
          final remoteChallenge = await remoteDataSource.getChallengeById(id);
          await localDataSource.cacheChallenge(remoteChallenge);
          
          print('✅ [CHALLENGES REPOSITORY] Successfully fetched challenge from API: ${remoteChallenge.title}');
          return Right(remoteChallenge);
          
        } catch (e) {
          print('⚠️ [CHALLENGES REPOSITORY] API fetch failed, using local cache: $e');
          final localChallenge = await localDataSource.getCachedChallenge(id);
          if (localChallenge != null) {
            return Right(localChallenge);
          } else {
            return Left(CacheFailure('Challenge not found locally'));
          }
        }
      } else {
        print('📱 [CHALLENGES REPOSITORY] No network, using local cache');
        final localChallenge = await localDataSource.getCachedChallenge(id);
        if (localChallenge != null) {
          return Right(localChallenge);
        } else {
          return Left(CacheFailure('Challenge not found and no network'));
        }
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error getting challenge by ID: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserChallengeStatsEntity>> getUserStats(String userId) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting user stats for: $userId');
      
      if (await networkInfo.isConnected) {
        try {
          // 🔧 USAR API REAL
          final remoteStats = await remoteDataSource.getUserStats(userId);
          await localDataSource.cacheUserStats(userId, remoteStats);
          
          print('✅ [CHALLENGES REPOSITORY] Successfully fetched user stats from API');
          return Right(remoteStats);
          
        } catch (e) {
          print('⚠️ [CHALLENGES REPOSITORY] API stats fetch failed, using local cache: $e');
          final localStats = await localDataSource.getCachedUserStats(userId);
          if (localStats != null) {
            return Right(localStats);
          } else {
            return Left(CacheFailure('User stats not found locally'));
          }
        }
      } else {
        print('📱 [CHALLENGES REPOSITORY] No network, using local cache for stats');
        final localStats = await localDataSource.getCachedUserStats(userId);
        if (localStats != null) {
          return Right(localStats);
        } else {
          return Left(CacheFailure('User stats not found and no network'));
        }
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error getting user stats: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> joinChallenge(String challengeId, String userId) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Joining challenge: $challengeId for user: $userId');
      
      if (await networkInfo.isConnected) {
        // 🔧 USAR API REAL
        await remoteDataSource.joinChallenge(challengeId, userId);
        
        // Actualizar en caché local
        final challenge = await localDataSource.getCachedChallenge(challengeId);
        if (challenge != null) {
          final updatedChallenge = ChallengeModel.fromEntity(
            ChallengeEntity(
              id: challenge.id,
              title: challenge.title,
              description: challenge.description,
              category: challenge.category,
              imageUrl: challenge.imageUrl,
              iconCode: challenge.iconCode,
              type: challenge.type,
              difficulty: challenge.difficulty,
              totalPoints: challenge.totalPoints,
              currentProgress: 0,
              targetProgress: challenge.targetProgress,
              status: ChallengeStatus.active,
              startDate: challenge.startDate,
              endDate: challenge.endDate,
              requirements: challenge.requirements,
              rewards: challenge.rewards,
              isParticipating: true,
              completedAt: challenge.completedAt,
              createdAt: challenge.createdAt,
            ),
          );
          await localDataSource.cacheChallenge(updatedChallenge);
        }
        
        print('✅ [CHALLENGES REPOSITORY] Successfully joined challenge via API');
        return const Right(null);
        
      } else {
        return Left(NetworkFailure('No network connection to join challenge'));
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error joining challenge: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProgress(String challengeId, String userId, int progress) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Updating progress for challenge: $challengeId');
      print('🎯 [CHALLENGES REPOSITORY] User: $userId, Progress: $progress');
      
      // Por ahora solo actualizar localmente
      // TODO: Implementar endpoint de actualización de progreso si existe
      final challenge = await localDataSource.getCachedChallenge(challengeId);
      if (challenge != null) {
        final updatedChallenge = ChallengeModel.fromEntity(
          ChallengeEntity(
            id: challenge.id,
            title: challenge.title,
            description: challenge.description,
            category: challenge.category,
            imageUrl: challenge.imageUrl,
            iconCode: challenge.iconCode,
            type: challenge.type,
            difficulty: challenge.difficulty,
            totalPoints: challenge.totalPoints,
            currentProgress: progress,
            targetProgress: challenge.targetProgress,
            status: progress >= challenge.targetProgress 
                ? ChallengeStatus.completed 
                : challenge.status,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            requirements: challenge.requirements,
            rewards: challenge.rewards,
            isParticipating: challenge.isParticipating,
            completedAt: progress >= challenge.targetProgress 
                ? DateTime.now() 
                : challenge.completedAt,
            createdAt: challenge.createdAt,
          ),
        );
        await localDataSource.cacheChallenge(updatedChallenge);
      }
      
      print('✅ [CHALLENGES REPOSITORY] Progress updated locally');
      return const Right(null);
      
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error updating progress: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  // 🆕 NUEVO MÉTODO PARA ENVIAR EVIDENCIA
  Future<Either<Failure, void>> submitEvidence({
    required String userChallengeId,
    required String submissionType,
    required String contentText,
    required List<String> mediaUrls,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? measurementData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Submitting evidence for: $userChallengeId');
      
      if (await networkInfo.isConnected) {
        // 🔧 USAR API REAL
        await remoteDataSource.submitEvidence(
          userChallengeId: userChallengeId,
          submissionType: submissionType,
          contentText: contentText,
          mediaUrls: mediaUrls,
          locationData: locationData,
          measurementData: measurementData,
          metadata: metadata,
        );
        
        print('✅ [CHALLENGES REPOSITORY] Evidence submitted successfully via API');
        return const Right(null);
        
      } else {
        return Left(NetworkFailure('No network connection to submit evidence'));
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error submitting evidence: $e');
      return Left(UnknownFailure('Error submitting evidence: ${e.toString()}'));
    }
  }

  // 🆕 NUEVO MÉTODO PARA OBTENER TOPICS COMO CATEGORÍAS
  Future<Either<Failure, List<TopicModel>>> getChallengeCategories() async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting challenge categories from topics');
      
      if (await networkInfo.isConnected) {
        final topics = await remoteDataSource.getTopics();
        print('✅ [CHALLENGES REPOSITORY] Successfully fetched ${topics.length} categories');
        return Right(topics);
      } else {
        return Left(NetworkFailure('No network connection to fetch categories'));
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error fetching categories: $e');
      return Left(UnknownFailure('Error fetching categories: ${e.toString()}'));
    }
  }

  // 🆕 NUEVO MÉTODO PARA OBTENER CHALLENGES ACTIVOS
  Future<Either<Failure, List<ChallengeEntity>>> getActiveChallengesFromAPI() async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting active challenges from API');
      
      if (await networkInfo.isConnected) {
        final activeChallenges = await remoteDataSource.getActiveChallenges();
        
        // Cache los challenges activos
        if (activeChallenges.isNotEmpty) {
          await localDataSource.cacheChallenges(activeChallenges);
        }
        
        print('✅ [CHALLENGES REPOSITORY] Successfully fetched ${activeChallenges.length} active challenges');
        return Right(activeChallenges);
      } else {
        // Fallback to local cache
        final localChallenges = await localDataSource.getCachedChallenges();
        final activeChallenges = localChallenges.where((c) => c.isActive).toList();
        return Right(activeChallenges);
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error fetching active challenges: $e');
      return Left(UnknownFailure('Error fetching active challenges: ${e.toString()}'));
    }
  }

  // 🆕 NUEVO MÉTODO PARA OBTENER CHALLENGES DEL USUARIO
  Future<Either<Failure, List<ChallengeEntity>>> getUserChallengesFromAPI(String userId) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting user challenges from API: $userId');
      
      if (await networkInfo.isConnected) {
        final userChallenges = await remoteDataSource.getUserChallenges(userId);
        
        // Cache user challenges with specific user prefix
        await localDataSource.cacheActiveChallenges(userId, userChallenges);
        
        print('✅ [CHALLENGES REPOSITORY] Successfully fetched ${userChallenges.length} user challenges');
        return Right(userChallenges);
      } else {
        // Fallback to local cache
        final localChallenges = await localDataSource.getCachedActiveChallenges(userId);
        return Right(localChallenges);
      }
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error fetching user challenges: $e');
      return Left(UnknownFailure('Error fetching user challenges: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChallengeProgressEntity>> getChallengeProgress(String challengeId, String userId) async {
    // TODO: Implementar si hay un endpoint específico para el progreso
    print('⚠️ [CHALLENGES REPOSITORY] getChallengeProgress not implemented yet');
    return const Left(UnknownFailure('Challenge progress endpoint not implemented'));
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getActiveChallenges(String userId) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting active challenges for user: $userId');
      
      // Primero intentar obtener del API
      final apiResult = await getActiveChallengesFromAPI();
      
      return apiResult.fold(
        (failure) async {
          // Si falla el API, usar cache local
          print('⚠️ [CHALLENGES REPOSITORY] API failed, using local cache for active challenges');
          final localChallenges = await localDataSource.getCachedActiveChallenges(userId);
          return Right(localChallenges);
        },
        (challenges) {
          // Filtrar challenges activos para el usuario
          final userActiveChallenges = challenges.where((c) => 
            c.isParticipating && c.isActive
          ).toList();
          return Right(userActiveChallenges);
        },
      );
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error getting active challenges: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getCompletedChallenges(String userId) async {
    try {
      print('🎯 [CHALLENGES REPOSITORY] Getting completed challenges for user: $userId');
      
      // Obtener challenges del usuario y filtrar completados
      final userChallengesResult = await getUserChallengesFromAPI(userId);
      
      return userChallengesResult.fold(
        (failure) => Left(failure),
        (challenges) {
          final completedChallenges = challenges.where((c) => c.isCompleted).toList();
          print('✅ [CHALLENGES REPOSITORY] Found ${completedChallenges.length} completed challenges');
          return Right(completedChallenges);
        },
      );
    } catch (e) {
      print('❌ [CHALLENGES REPOSITORY] Error getting completed challenges: $e');
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }
}