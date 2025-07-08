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

@Injectable(as: ChallengesRepository)
class ChallengesRepositoryImpl implements ChallengesRepository {
  final ChallengesRemoteDataSource remoteDataSource;
  final ChallengesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  // 🔧 CONSTRUCTOR CORREGIDO - usar parámetros nombrados requeridos
  ChallengesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getChallenges({
    ChallengeType? type,
    String? category,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteChallenges = await remoteDataSource.getChallenges(
            type: type,
            category: category,
          );
          await localDataSource.cacheChallenges(remoteChallenges);
          return Right(remoteChallenges);
        } catch (e) {
          final localChallenges = await localDataSource.getCachedChallenges();
          return Right(localChallenges);
        }
      } else {
        final localChallenges = await localDataSource.getCachedChallenges();
        return Right(localChallenges);
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
  Future<Either<Failure, ChallengeEntity>> getChallengeById(String id) async {
    try {
      final localChallenge = await localDataSource.getCachedChallenge(id);
      if (localChallenge != null) {
        return Right(localChallenge);
      } else {
        return Left(CacheFailure('Desafío no encontrado'));
      }
    } catch (e) {
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserChallengeStatsEntity>> getUserStats(String userId) async {
    try {
      final localStats = await localDataSource.getCachedUserStats(userId);
      if (localStats != null) {
        return Right(localStats);
      } else {
        return Left(CacheFailure('Estadísticas no encontradas'));
      }
    } catch (e) {
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> joinChallenge(String challengeId, String userId) async {
    try {
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
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProgress(String challengeId, String userId, int progress) async {
    try {
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
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ChallengeProgressEntity>> getChallengeProgress(String challengeId, String userId) async {
    return const Left(UnknownFailure('No implementado aún'));
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getActiveChallenges(String userId) async {
    try {
      final localChallenges = await localDataSource.getCachedActiveChallenges(userId);
      return Right(localChallenges);
    } catch (e) {
      return Left(UnknownFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getCompletedChallenges(String userId) async {
    return const Left(UnknownFailure('No implementado aún'));
  }
}
