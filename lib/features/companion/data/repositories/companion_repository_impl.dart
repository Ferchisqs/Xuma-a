// lib/features/companion/data/repositories/companion_repository_impl.dart
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/repositories/companion_repository.dart';
import '../datasources/companion_local_datasource.dart';
import '../datasources/companion_remote_datasource.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';

@Injectable(as: CompanionRepository)
class CompanionRepositoryImpl implements CompanionRepository {
  final CompanionRemoteDataSource remoteDataSource;
  final CompanionLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CompanionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteCompanions = await remoteDataSource.getUserCompanions(userId);
          await localDataSource.cacheCompanions(userId, remoteCompanions);
          return Right(remoteCompanions);
        } catch (e) {
          final localCompanions = await localDataSource.getCachedCompanions(userId);
          return Right(localCompanions);
        }
      } else {
        final localCompanions = await localDataSource.getCachedCompanions(userId);
        return Right(localCompanions);
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
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    // Para el shop - todos los compañeros disponibles
    try {
      const userId = 'user_123'; // Default para cargar todos
      final companions = await localDataSource.getCachedCompanions(userId);
      return Right(companions);
    } catch (e) {
      return Left(CacheFailure('Error obteniendo compañeros: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionStatsEntity>> getCompanionStats(String userId) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteStats = await remoteDataSource.getCompanionStats(userId);
          await localDataSource.cacheStats(remoteStats);
          return Right(remoteStats);
        } catch (e) {
          final localStats = await localDataSource.getCachedStats(userId);
          if (localStats != null) {
            return Right(localStats);
          } else {
            return Left(CacheFailure('No se encontraron estadísticas'));
          }
        }
      } else {
        final localStats = await localDataSource.getCachedStats(userId);
        if (localStats != null) {
          return Right(localStats);
        } else {
          return Left(CacheFailure('Sin conexión y sin datos locales'));
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
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    try {
      // Verificar si tiene suficientes puntos
      final statsResult = await getCompanionStats(userId);
      return statsResult.fold(
        (failure) => Left(failure),
        (stats) async {
          final companions = await localDataSource.getCachedCompanions(userId);
          final companionToPurchase = companions.firstWhere(
            (c) => c.id == companionId,
            orElse: () => throw Exception('Compañero no encontrado'),
          );
          
          if (stats.availablePoints < companionToPurchase.purchasePrice) {
            return Left(ValidationFailure('No tienes suficientes puntos'));
          }

          // Simular compra local
          final purchasedCompanion = CompanionModel.fromEntity(
            CompanionEntity(
              id: companionToPurchase.id,
              type: companionToPurchase.type,
              stage: companionToPurchase.stage,
              name: companionToPurchase.name,
              description: companionToPurchase.description,
              level: 1,
              experience: 0,
              happiness: 100,
              hunger: 100,
              energy: 100,
              isOwned: true,
              isSelected: false,
              purchasedAt: DateTime.now(),
              currentMood: CompanionMood.happy,
              purchasePrice: companionToPurchase.purchasePrice,
              evolutionPrice: companionToPurchase.evolutionPrice,
              unlockedAnimations: companionToPurchase.unlockedAnimations,
              createdAt: companionToPurchase.createdAt,
            ),
          );

          // Actualizar la lista completa de compañeros
          final updatedCompanions = companions.map((comp) {
            if (comp.id == companionId) {
              return purchasedCompanion;
            }
            return comp;
          }).toList();

          await localDataSource.cacheCompanions(userId, updatedCompanions);
          await localDataSource.cacheCompanion(purchasedCompanion);

          // Actualizar stats
          final updatedStats = CompanionStatsModel.fromEntity(
            CompanionStatsEntity(
              userId: stats.userId,
              totalCompanions: stats.totalCompanions,
              ownedCompanions: stats.ownedCompanions + 1,
              totalPoints: stats.totalPoints,
              spentPoints: stats.spentPoints + companionToPurchase.purchasePrice,
              activeCompanionId: stats.activeCompanionId,
              totalFeedCount: stats.totalFeedCount,
              totalLoveCount: stats.totalLoveCount,
              totalEvolutions: stats.totalEvolutions,
              lastActivity: DateTime.now(),
            ),
          );
          await localDataSource.cacheStats(updatedStats);

          return Right(purchasedCompanion);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Error en compra: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId) async {
    try {
      final companion = await localDataSource.getCachedCompanion(companionId);
      if (companion == null) {
        return Left(CacheFailure('Compañero no encontrado'));
      }

      if (!companion.canEvolve) {
        return Left(ValidationFailure('No se puede evolucionar aún'));
      }

      final nextStage = companion.nextStage;
      if (nextStage == null) {
        return Left(ValidationFailure('Ya está en su máxima evolución'));
      }

      // Crear el compañero evolucionado
      final evolvedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: '${companion.type.name}_${nextStage.name}',
          type: companion.type,
          stage: nextStage,
          name: companion.name,
          description: _getEvolutionDescription(companion.name, nextStage),
          level: companion.level + 1,
          experience: 0,
          happiness: companion.happiness,
          hunger: companion.hunger,
          energy: companion.energy,
          isOwned: true,
          isSelected: companion.isSelected,
          purchasedAt: companion.purchasedAt,
          currentMood: CompanionMood.excited,
          purchasePrice: 0,
          evolutionPrice: nextStage == CompanionStage.adult ? 0 : companion.evolutionPrice + 50,
          unlockedAnimations: [...companion.unlockedAnimations, 'excited'],
          createdAt: companion.createdAt,
        ),
      );

      // Actualizar la caché
      await localDataSource.cacheCompanion(evolvedCompanion);

      // Actualizar la lista de compañeros
      final companions = await localDataSource.getCachedCompanions(userId);
      final updatedCompanions = companions.map((comp) {
        if (comp.id == companionId) {
          return evolvedCompanion;
        }
        // Si este compañero evolucionado ya existe en la lista, marcarlo como poseído
        if (comp.id == evolvedCompanion.id) {
          return CompanionModel.fromEntity(
            CompanionEntity(
              id: comp.id,
              type: comp.type,
              stage: comp.stage,
              name: comp.name,
              description: comp.description,
              level: evolvedCompanion.level,
              experience: evolvedCompanion.experience,
              happiness: evolvedCompanion.happiness,
              hunger: evolvedCompanion.hunger,
              energy: evolvedCompanion.energy,
              isOwned: true,
              isSelected: evolvedCompanion.isSelected,
              purchasedAt: evolvedCompanion.purchasedAt,
              lastFeedTime: evolvedCompanion.lastFeedTime,
              lastLoveTime: evolvedCompanion.lastLoveTime,
              currentMood: evolvedCompanion.currentMood,
              purchasePrice: comp.purchasePrice,
              evolutionPrice: comp.evolutionPrice,
              unlockedAnimations: evolvedCompanion.unlockedAnimations,
              createdAt: comp.createdAt,
            ),
          );
        }
        return comp;
      }).toList();

      await localDataSource.cacheCompanions(userId, updatedCompanions);

      // Actualizar estadísticas
      final statsResult = await getCompanionStats(userId);
      await statsResult.fold(
        (failure) async {},
        (stats) async {
          final updatedStats = CompanionStatsModel.fromEntity(
            CompanionStatsEntity(
              userId: stats.userId,
              totalCompanions: stats.totalCompanions,
              ownedCompanions: stats.ownedCompanions,
              totalPoints: stats.totalPoints,
              spentPoints: stats.spentPoints,
              activeCompanionId: stats.activeCompanionId,
              totalFeedCount: stats.totalFeedCount,
              totalLoveCount: stats.totalLoveCount,
              totalEvolutions: stats.totalEvolutions + 1,
              lastActivity: DateTime.now(),
            ),
          );
          await localDataSource.cacheStats(updatedStats);
        },
      );

      return Right(evolvedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
    }
  }

  @override
Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
  try {
    // 🔧 BUSCAR EL COMPAÑERO EN LA LISTA COMPLETA PRIMERO
    final companions = await localDataSource.getCachedCompanions(userId);
    final companionToFeed = companions.firstWhere(
      (c) => c.id == companionId,
      orElse: () => throw Exception('Compañero no encontrado en la lista'),
    );

    // 🔧 Verificar que el compañero está en posesión del usuario
    if (!companionToFeed.isOwned) {
      return Left(ValidationFailure('Este compañero no te pertenece'));
    }

    final fedCompanion = CompanionModel.fromEntity(
      CompanionEntity(
        id: companionToFeed.id,
        type: companionToFeed.type,
        stage: companionToFeed.stage,
        name: companionToFeed.name,
        description: companionToFeed.description,
        level: companionToFeed.level,
        experience: companionToFeed.experience + 5,
        happiness: (companionToFeed.happiness + 10).clamp(0, 100),
        hunger: 100, // Lleno después de comer
        energy: companionToFeed.energy,
        isOwned: companionToFeed.isOwned,
        isSelected: companionToFeed.isSelected,
        purchasedAt: companionToFeed.purchasedAt,
        lastFeedTime: DateTime.now(),
        lastLoveTime: companionToFeed.lastLoveTime,
        currentMood: CompanionMood.happy,
        purchasePrice: companionToFeed.purchasePrice,
        evolutionPrice: companionToFeed.evolutionPrice,
        unlockedAnimations: companionToFeed.unlockedAnimations,
        createdAt: companionToFeed.createdAt,
      ),
    );

    // 🔧 ACTUALIZAR EN CACHÉ INDIVIDUAL
    await localDataSource.cacheCompanion(fedCompanion);

    // 🔧 ACTUALIZAR EN LA LISTA COMPLETA
    final updatedCompanions = companions.map((comp) {
      if (comp.id == companionId) {
        return fedCompanion;
      }
      return comp;
    }).toList();
    
    await localDataSource.cacheCompanions(userId, updatedCompanions);

    // Actualizar estadísticas
    final statsResult = await getCompanionStats(userId);
    await statsResult.fold(
      (failure) async {},
      (stats) async {
        final updatedStats = CompanionStatsModel.fromEntity(
          CompanionStatsEntity(
            userId: stats.userId,
            totalCompanions: stats.totalCompanions,
            ownedCompanions: stats.ownedCompanions,
            totalPoints: stats.totalPoints,
            spentPoints: stats.spentPoints,
            activeCompanionId: stats.activeCompanionId,
            totalFeedCount: stats.totalFeedCount + 1,
            totalLoveCount: stats.totalLoveCount,
            totalEvolutions: stats.totalEvolutions,
            lastActivity: DateTime.now(),
          ),
        );
        await localDataSource.cacheStats(updatedStats);
      },
    );

    return Right(fedCompanion);
  } catch (e) {
    debugPrint('🔧 Error en feedCompanion: $e');
    return Left(UnknownFailure('Error alimentando: ${e.toString()}'));
  }
}


  @override
Future<Either<Failure, CompanionEntity>> loveCompanion(String userId, String companionId) async {
  try {
    // 🔧 BUSCAR EL COMPAÑERO EN LA LISTA COMPLETA PRIMERO
    final companions = await localDataSource.getCachedCompanions(userId);
    final companionToLove = companions.firstWhere(
      (c) => c.id == companionId,
      orElse: () => throw Exception('Compañero no encontrado en la lista'),
    );

    // 🔧 Verificar que el compañero está en posesión del usuario
    if (!companionToLove.isOwned) {
      return Left(ValidationFailure('Este compañero no te pertenece'));
    }

    final lovedCompanion = CompanionModel.fromEntity(
      CompanionEntity(
        id: companionToLove.id,
        type: companionToLove.type,
        stage: companionToLove.stage,
        name: companionToLove.name,
        description: companionToLove.description,
        level: companionToLove.level,
        experience: companionToLove.experience + 3,
        happiness: 100, // Máxima felicidad
        hunger: companionToLove.hunger,
        energy: (companionToLove.energy + 15).clamp(0, 100),
        isOwned: companionToLove.isOwned,
        isSelected: companionToLove.isSelected,
        purchasedAt: companionToLove.purchasedAt,
        lastFeedTime: companionToLove.lastFeedTime,
        lastLoveTime: DateTime.now(),
        currentMood: CompanionMood.excited,
        purchasePrice: companionToLove.purchasePrice,
        evolutionPrice: companionToLove.evolutionPrice,
        unlockedAnimations: companionToLove.unlockedAnimations,
        createdAt: companionToLove.createdAt,
      ),
    );

    // 🔧 ACTUALIZAR EN CACHÉ INDIVIDUAL
    await localDataSource.cacheCompanion(lovedCompanion);

    // 🔧 ACTUALIZAR EN LA LISTA COMPLETA
    final updatedCompanions = companions.map((comp) {
      if (comp.id == companionId) {
        return lovedCompanion;
      }
      return comp;
    }).toList();
    
    await localDataSource.cacheCompanions(userId, updatedCompanions);

    // Actualizar estadísticas
    final statsResult = await getCompanionStats(userId);
    await statsResult.fold(
      (failure) async {},
      (stats) async {
        final updatedStats = CompanionStatsModel.fromEntity(
          CompanionStatsEntity(
            userId: stats.userId,
            totalCompanions: stats.totalCompanions,
            ownedCompanions: stats.ownedCompanions,
            totalPoints: stats.totalPoints,
            spentPoints: stats.spentPoints,
            activeCompanionId: stats.activeCompanionId,
            totalFeedCount: stats.totalFeedCount,
            totalLoveCount: stats.totalLoveCount + 1,
            totalEvolutions: stats.totalEvolutions,
            lastActivity: DateTime.now(),
          ),
        );
        await localDataSource.cacheStats(updatedStats);
      },
    );

    return Right(lovedCompanion);
  } catch (e) {
    debugPrint('🔧 Error en loveCompanion: $e');
    return Left(UnknownFailure('Error dando amor: ${e.toString()}'));
  }
}

  @override
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      
      // Desactivar todos los compañeros y activar el seleccionado
      final updatedCompanions = companions.map((comp) {
        return CompanionModel.fromEntity(
          CompanionEntity(
            id: comp.id,
            type: comp.type,
            stage: comp.stage,
            name: comp.name,
            description: comp.description,
            level: comp.level,
            experience: comp.experience,
            happiness: comp.happiness,
            hunger: comp.hunger,
            energy: comp.energy,
            isOwned: comp.isOwned,
            isSelected: comp.id == companionId, // Solo el seleccionado estará activo
            purchasedAt: comp.purchasedAt,
            lastFeedTime: comp.lastFeedTime,
            lastLoveTime: comp.lastLoveTime,
            currentMood: comp.currentMood,
            purchasePrice: comp.purchasePrice,
            evolutionPrice: comp.evolutionPrice,
            unlockedAnimations: comp.unlockedAnimations,
            createdAt: comp.createdAt,
          ),
        );
      }).toList();

      await localDataSource.cacheCompanions(userId, updatedCompanions);

      // Actualizar estadísticas
      final statsResult = await getCompanionStats(userId);
      await statsResult.fold(
        (failure) async {},
        (stats) async {
          final updatedStats = CompanionStatsModel.fromEntity(
            CompanionStatsEntity(
              userId: stats.userId,
              totalCompanions: stats.totalCompanions,
              ownedCompanions: stats.ownedCompanions,
              totalPoints: stats.totalPoints,
              spentPoints: stats.spentPoints,
              activeCompanionId: companionId,
              totalFeedCount: stats.totalFeedCount,
              totalLoveCount: stats.totalLoveCount,
              totalEvolutions: stats.totalEvolutions,
              lastActivity: DateTime.now(),
            ),
          );
          await localDataSource.cacheStats(updatedStats);
        },
      );

      final activeCompanion = updatedCompanions.firstWhere((c) => c.id == companionId);
      return Right(activeCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error activando compañero: ${e.toString()}'));
    }
  }

  String _getEvolutionDescription(String name, CompanionStage stage) {
    switch (stage) {
      case CompanionStage.young:
        return '$name ha crecido y es más juguetón';
      case CompanionStage.adult:
        return '$name adulto, el compañero perfecto';
      default:
        return '$name en su forma básica';
    }
  }
}