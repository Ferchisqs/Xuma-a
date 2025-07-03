import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/eco_tip_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../datasources/home_local_datasource.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  HomeRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, EcoTipEntity>> getDailyTip() async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteTip = await _remoteDataSource.getDailyTip();
        await _localDataSource.cacheDailyTip(remoteTip);
        return Right(remoteTip);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final localTip = await _localDataSource.getCachedDailyTip();
        if (localTip != null) {
          return Right(localTip);
        } else {
          return _getMockDailyTip();
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, UserStatsEntity>> getUserStats() async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteStats = await _remoteDataSource.getUserStats();
        await _localDataSource.cacheUserStats(remoteStats);
        return Right(remoteStats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      try {
        final localStats = await _localDataSource.getCachedUserStats();
        if (localStats != null) {
          return Right(localStats);
        } else {
          return _getMockUserStats();
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> updateUserActivity(String activityType) async {
    if (await _networkInfo.isConnected) {
      try {
        final result = await _remoteDataSource.updateUserActivity(activityType);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  // Mock data para desarrollo/offline
  Either<Failure, EcoTipEntity> _getMockDailyTip() {
    final mockTip = EcoTipEntity(
      id: 'mock_tip_1',
      title: '💡 Apaga luces y dispositivos',
      description: 'Apaga luces y dispositivos que no uses, usa bombillas LED y ajusta el termostato para ahorrar energía y reducir emisiones. ¡Pequeños cambios, gran impacto!',
      category: 'energia',
      iconName: 'lightbulb_outline',
      createdAt: DateTime.now(),
      difficulty: 2,
      tags: ['energia', 'ahorro', 'facil'],
    );
    return Right(mockTip);
  }

  Either<Failure, UserStatsEntity> _getMockUserStats() {
    final mockStats = UserStatsEntity(
      totalPoints: 1250,
      completedActivities: 23,
      streak: 7,
      currentLevel: 'Protector Verde',
      recycledItems: 45,
      carbonSaved: 12.5,
      achievements: ['Primera Semana', 'Reciclador Pro', 'Ahorrador de Energía'],
    );
    return Right(mockStats);
  }
}