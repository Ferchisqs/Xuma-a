// 🔧 ACTUALIZACIÓN DEL REPOSITORY PARA MODO DESARROLLO
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
      debugPrint('🐾 [REPO] === OBTENIENDO COMPAÑEROS DEL USUARIO ===');
      debugPrint('👤 [REPO] Usuario ID: $userId');
      
      // 🔧 EN MODO DESARROLLO: SIEMPRE USAR LOCAL CON MOCK
      debugPrint('🎮 [REPO] MODO DESARROLLO: Usando datos locales mock');
      final localCompanions = await localDataSource.getCachedCompanions(userId);
      
      debugPrint('✅ [REPO] Obtenidos ${localCompanions.length} compañeros');
      debugPrint('🔓 [REPO] Compañeros desbloqueados: ${localCompanions.where((c) => c.isOwned).length}');
      
      return Right(localCompanions);
    } on ServerException catch (e) {
      debugPrint('❌ [REPO] ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      debugPrint('❌ [REPO] CacheException: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      debugPrint('❌ [REPO] Error desconocido: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🏪 [REPO] === OBTENIENDO COMPAÑEROS PARA TIENDA ===');
      
      // 🔧 USAR USUARIO DEFAULT PARA CARGAR TODOS LOS COMPAÑEROS
      const userId = 'user_123';
      final companions = await localDataSource.getCachedCompanions(userId);
      
      debugPrint('🛍️ [REPO] Compañeros disponibles en tienda: ${companions.length}');
      debugPrint('🔓 [REPO] Ya desbloqueados: ${companions.where((c) => c.isOwned).length}');
      debugPrint('🔒 [REPO] Por desbloquear: ${companions.where((c) => !c.isOwned).length}');
      
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error obteniendo compañeros disponibles: $e');
      return Left(CacheFailure('Error obteniendo compañeros: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionStatsEntity>> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REPO] === OBTENIENDO ESTADÍSTICAS ===');
      debugPrint('👤 [REPO] Usuario ID: $userId');
      
      // 🔧 EN MODO DESARROLLO: SIEMPRE USAR LOCAL CON STATS GENEROSOS
      debugPrint('🎮 [REPO] MODO DESARROLLO: Usando stats locales generosos');
      final localStats = await localDataSource.getCachedStats(userId);
      
      if (localStats != null) {
        debugPrint('✅ [REPO] Stats obtenidos:');
        debugPrint('💰 [REPO] Puntos disponibles: ${localStats.availablePoints}');
        debugPrint('🐾 [REPO] Compañeros poseídos: ${localStats.ownedCompanions}/${localStats.totalCompanions}');
        
        return Right(localStats);
      } else {
        debugPrint('❌ [REPO] No se encontraron estadísticas');
        return Left(CacheFailure('No se encontraron estadísticas'));
      }
    } on ServerException catch (e) {
      debugPrint('❌ [REPO] ServerException en stats: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      debugPrint('❌ [REPO] CacheException en stats: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      debugPrint('❌ [REPO] Error desconocido en stats: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    try {
      debugPrint('🛒 [REPO] === INICIANDO COMPRA ===');
      debugPrint('👤 [REPO] Usuario: $userId');
      debugPrint('🐾 [REPO] Compañero: $companionId');
      
      // 🎮 EN MODO DESARROLLO: SIMULAR COMPRA EXITOSA INMEDIATA
      debugPrint('🎮 [REPO] MODO DESARROLLO: Simulando compra exitosa');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionToPurchase = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado'),
      );
      
      debugPrint('✅ [REPO] Compañero encontrado: ${companionToPurchase.displayName}');
      
      // 🔧 MARCAR COMO COMPRADO SIN VERIFICAR PUNTOS (MODO DESARROLLO)
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
          isOwned: true,  // 🔓 MARCAR COMO POSEÍDO
          isSelected: false,
          purchasedAt: DateTime.now(),
          currentMood: CompanionMood.happy,
          purchasePrice: companionToPurchase.purchasePrice,
          evolutionPrice: companionToPurchase.evolutionPrice,
          unlockedAnimations: companionToPurchase.unlockedAnimations,
          createdAt: companionToPurchase.createdAt,
        ),
      );

      debugPrint('✅ [REPO] Compañero marcado como comprado');

      // 🔧 ACTUALIZAR LISTA DE COMPAÑEROS
      final updatedCompanions = companions.map((comp) {
        if (comp.id == companionId) {
          return purchasedCompanion;
        }
        return comp;
      }).toList();

      await localDataSource.cacheCompanions(userId, updatedCompanions);
      await localDataSource.cacheCompanion(purchasedCompanion);
      
      debugPrint('💾 [REPO] Compañeros guardados en caché');

      // 🔧 ACTUALIZAR STATS (EN DESARROLLO NO RESTAMOS PUNTOS)
      final currentStats = await localDataSource.getCachedStats(userId);
      if (currentStats != null) {
        final updatedStats = CompanionStatsModel.fromEntity(
          CompanionStatsEntity(
            userId: currentStats.userId,
            totalCompanions: currentStats.totalCompanions,
            ownedCompanions: currentStats.ownedCompanions + 1,
            totalPoints: currentStats.totalPoints,
            spentPoints: currentStats.spentPoints, // 🎮 NO RESTAMOS EN DESARROLLO
            activeCompanionId: currentStats.activeCompanionId,
            totalFeedCount: currentStats.totalFeedCount,
            totalLoveCount: currentStats.totalLoveCount,
            totalEvolutions: currentStats.totalEvolutions,
            lastActivity: DateTime.now(),
          ),
        );
        
        await localDataSource.cacheStats(updatedStats);
        debugPrint('📊 [REPO] Stats actualizados');
      }

      debugPrint('🎉 [REPO] === COMPRA COMPLETADA ===');
      return Right(purchasedCompanion);
    } catch (e) {
      debugPrint('💥 [REPO] Error en compra: $e');
      return Left(UnknownFailure('Error en compra: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId) async {
    try {
      debugPrint('⭐ [REPO] === EVOLUCIÓN INICIADA ===');
      debugPrint('🐾 [REPO] Evolucionando: $companionId');
      
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

      await localDataSource.cacheCompanion(evolvedCompanion);

      final companions = await localDataSource.getCachedCompanions(userId);
      final updatedCompanions = companions.map((comp) {
        if (comp.id == companionId) {
          return evolvedCompanion;
        }
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

      debugPrint('⭐ [REPO] === EVOLUCIÓN COMPLETADA ===');
      return Right(evolvedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error en evolución: $e');
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    try {
      debugPrint('🍎 [REPO] === ALIMENTANDO COMPAÑERO ===');
      debugPrint('🐾 [REPO] Alimentando: $companionId');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionToFeed = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado en la lista'),
      );

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
          experience: companionToFeed.experience + 25,
          happiness: (companionToFeed.happiness + 15).clamp(0, 100),
          hunger: 100,
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

      await localDataSource.cacheCompanion(fedCompanion);

      final updatedCompanions = companions.map((comp) {
        if (comp.id == companionId) {
          return fedCompanion;
        }
        return comp;
      }).toList();
      
      await localDataSource.cacheCompanions(userId, updatedCompanions);

      debugPrint('🍎 [REPO] === ALIMENTACIÓN COMPLETADA ===');
      return Right(fedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error alimentando: $e');
      return Left(UnknownFailure('Error alimentando: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> loveCompanion(String userId, String companionId) async {
    try {
      debugPrint('💖 [REPO] === DANDO AMOR A COMPAÑERO ===');
      debugPrint('🐾 [REPO] Amando a: $companionId');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionToLove = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado en la lista'),
      );

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
          experience: companionToLove.experience + 20,
          happiness: 100,
          hunger: companionToLove.hunger,
          energy: (companionToLove.energy + 20).clamp(0, 100),
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

      await localDataSource.cacheCompanion(lovedCompanion);

      final updatedCompanions = companions.map((comp) {
        if (comp.id == companionId) {
          return lovedCompanion;
        }
        return comp;
      }).toList();
      
      await localDataSource.cacheCompanions(userId, updatedCompanions);

      debugPrint('💖 [REPO] === AMOR COMPLETADO ===');
      return Right(lovedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error dando amor: $e');
      return Left(UnknownFailure('Error dando amor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId) async {
    try {
      debugPrint('⭐ [REPO] === ACTIVANDO COMPAÑERO ===');
      debugPrint('🐾 [REPO] Activando: $companionId');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      
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
            isSelected: comp.id == companionId,
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

      final activeCompanion = updatedCompanions.firstWhere((c) => c.id == companionId);
      
      debugPrint('⭐ [REPO] === ACTIVACIÓN COMPLETADA ===');
      return Right(activeCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error activando compañero: $e');
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