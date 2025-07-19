// lib/features/companion/data/repositories/companion_repository_impl.dart - FALLBACK MEJORADO
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

  // 🔧 MODO LOCAL HASTA QUE LA API FUNCIONE
  static const bool forceLocalMode = true; // 🔧 true = SOLO LOCAL
  static const String defaultUserId = 'user_123';

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
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 USAR SOLO DATOS LOCALES HASTA QUE LA API FUNCIONE
        debugPrint('📱 [REPO] MODO LOCAL FORZADO - usando datos locales');
        final localCompanions = await localDataSource.getCachedCompanions(userId);
        debugPrint('✅ [REPO] Local devolvió ${localCompanions.length} compañeros');
        return Right(localCompanions);
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Intentando API remota...');
        
        try {
          final remoteCompanions = await remoteDataSource.getUserCompanions(userId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas');
          
          await localDataSource.cacheCompanions(userId, remoteCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache local');
          
          return Right(remoteCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API, fallback a local: $e');
          
          final localCompanions = await localDataSource.getCachedCompanions(userId);
          if (localCompanions.isNotEmpty) {
            debugPrint('📱 [REPO] Usando ${localCompanions.length} mascotas desde cache');
            return Right(localCompanions);
          } else {
            // 🔧 SI NO HAY CACHE, USAR DATOS MOCK
            debugPrint('🔧 [REPO] No hay cache, generando datos mock');
            return Right(await _getMockCompanionsForFallback(userId));
          }
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión, usando datos locales');
        final localCompanions = await localDataSource.getCachedCompanions(userId);
        return Right(localCompanions);
      }
    } on ServerException catch (e) {
      debugPrint('❌ [REPO] ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      debugPrint('❌ [REPO] CacheException: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      debugPrint('❌ [REPO] Error desconocido: $e');
      // 🔧 EN CASO DE ERROR, DEVOLVER DATOS MOCK PARA QUE LA APP FUNCIONE
      try {
        final mockCompanions = await _getMockCompanionsForFallback(userId);
        return Right(mockCompanions);
      } catch (mockError) {
        return Left(UnknownFailure('Error generando datos mock: ${mockError.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🏪 [REPO] === OBTENIENDO COMPAÑEROS DISPONIBLES ===');
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 MODO LOCAL: OBTENER TODOS LOS COMPAÑEROS LOCALES
        debugPrint('📱 [REPO] MODO LOCAL - obteniendo todos los compañeros locales');
        const userId = defaultUserId;
        final companions = await localDataSource.getCachedCompanions(userId);
        debugPrint('🛍️ [REPO] Local devolvió ${companions.length} compañeros');
        return Right(companions);
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Obteniendo mascotas disponibles desde API');
        
        try {
          final storeCompanions = await remoteDataSource.getStoreCompanions();
          debugPrint('🛍️ [REPO] API devolvió ${storeCompanions.length} mascotas en tienda');
          return Right(storeCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API store, usando datos locales: $e');
        }
      }
      
      // Fallback a datos locales
      debugPrint('📱 [REPO] Usando datos locales para tienda');
      const userId = defaultUserId;
      final companions = await localDataSource.getCachedCompanions(userId);
      
      debugPrint('🛍️ [REPO] Tienda local: ${companions.length} mascotas disponibles');
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
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 MODO LOCAL: USAR STATS LOCALES
        debugPrint('📱 [REPO] MODO LOCAL - obteniendo stats locales');
        final localStats = await localDataSource.getCachedStats(userId);
        
        if (localStats != null) {
          debugPrint('✅ [REPO] Stats locales encontrados');
          return Right(localStats);
        } else {
          debugPrint('🔧 [REPO] Generando stats por defecto');
          // 🔧 GENERAR STATS POR DEFECTO SI NO HAY CACHE
          final defaultStats = CompanionStatsModel(
            userId: userId,
            totalCompanions: 12,
            ownedCompanions: 1,
            totalPoints: 500,
            spentPoints: 0,
            activeCompanionId: 'dexter_baby',
            totalFeedCount: 0,
            totalLoveCount: 0,
            totalEvolutions: 0,
            lastActivity: DateTime.now(),
          );
          return Right(defaultStats);
        }
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Calculando stats desde API');
        
        try {
          final companions = await remoteDataSource.getUserCompanions(userId);
          final stats = _calculateStatsFromCompanions(userId, companions);
          
          await localDataSource.cacheStats(stats);
          debugPrint('✅ [REPO] Stats API calculados y guardados');
          
          return Right(stats);
        } catch (e) {
          debugPrint('❌ [REPO] Error calculando stats desde API: $e');
        }
      }
      
      // Usar cache local
      debugPrint('📱 [REPO] Usando stats desde cache local');
      final localStats = await localDataSource.getCachedStats(userId);
      
      if (localStats != null) {
        debugPrint('✅ [REPO] Stats locales encontrados');
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
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 MODO LOCAL: SIMULACIÓN DE COMPRA
        debugPrint('📱 [REPO] MODO LOCAL - simulando compra');
        return await _purchaseCompanionLocal(userId, companionId);
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Adoptando mascota via API');
        
        try {
          final (petId, speciesType) = _extractApiInfoFromLocalId(companionId);
          
          final adoptedCompanion = await remoteDataSource.adoptCompanion(userId, petId, speciesType);
          debugPrint('✅ [REPO] Mascota adoptada via API: ${adoptedCompanion.displayName}');
          
          await _updateLocalCacheAfterPurchase(userId, adoptedCompanion);
          
          return Right(adoptedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error adoptando via API: $e');
          return Left(ServerFailure('Error adoptando mascota: ${e.toString()}'));
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión - simulando compra local');
        return await _purchaseCompanionLocal(userId, companionId);
      }
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
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 MODO LOCAL: SIMULACIÓN DE EVOLUCIÓN
        debugPrint('📱 [REPO] MODO LOCAL - simulando evolución');
        return await _evolveCompanionLocal(userId, companionId);
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Evolucionando via API');
        
        try {
          final (petId, _) = _extractApiInfoFromLocalId(companionId);
          
          final evolvedCompanion = await remoteDataSource.evolveCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota evolucionada via API: ${evolvedCompanion.displayName}');
          
          await _updateLocalCacheAfterEvolution(userId, evolvedCompanion);
          
          return Right(evolvedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error evolucionando via API: $e');
          return Left(ServerFailure('Error evolucionando: ${e.toString()}'));
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión - simulando evolución local');
        return await _evolveCompanionLocal(userId, companionId);
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error en evolución: $e');
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId) async {
    try {
      debugPrint('⭐ [REPO] === ACTIVANDO COMPAÑERO ===');
      debugPrint('🐾 [REPO] Activando: $companionId');
      debugPrint('🔧 [REPO] Modo forzado local: $forceLocalMode');
      
      if (forceLocalMode) {
        // 🔧 MODO LOCAL: ACTIVACIÓN LOCAL
        debugPrint('📱 [REPO] MODO LOCAL - activando localmente');
        return await _setActiveCompanionLocal(userId, companionId);
      }

      // 🔧 CÓDIGO ORIGINAL PARA CUANDO LA API FUNCIONE
      if (await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Destacando mascota via API');
        
        try {
          final (petId, _) = _extractApiInfoFromLocalId(companionId);
          
          final featuredCompanion = await remoteDataSource.featureCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota destacada via API: ${featuredCompanion.displayName}');
          
          await _updateLocalCacheAfterFeature(userId, featuredCompanion);
          
          return Right(featuredCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error destacando via API: $e');
          return Left(ServerFailure('Error destacando mascota: ${e.toString()}'));
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión - activando localmente');
        return await _setActiveCompanionLocal(userId, companionId);
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error activando compañero: $e');
      return Left(UnknownFailure('Error activando compañero: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    try {
      debugPrint('🍎 [REPO] === ALIMENTANDO COMPAÑERO ===');
      debugPrint('🐾 [REPO] Alimentando: $companionId');
      
      // 🔧 ALIMENTAR SIEMPRE ES LOCAL (LA API NO LO SOPORTA AÚN)
      debugPrint('📱 [REPO] Alimentando localmente (API no soporta esta función)');
      
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
      
      // 🔧 AMOR SIEMPRE ES LOCAL (LA API NO LO SOPORTA AÚN)
      debugPrint('📱 [REPO] Dando amor localmente (API no soporta esta función)');
      
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

  // ==================== 🔧 MÉTODOS HELPER LOCALES ====================

  Future<List<CompanionEntity>> _getMockCompanionsForFallback(String userId) async {
    debugPrint('🔧 [REPO] Generando compañeros mock de emergencia');
    final companions = await localDataSource.getCachedCompanions(userId);
    return companions.cast<CompanionEntity>();
  }

  (String petId, String speciesType) _extractApiInfoFromLocalId(String localId) {
    final parts = localId.split('_');
    if (parts.length != 2) {
      throw ArgumentError('Invalid local companion ID format: $localId');
    }
    
    final typeStr = parts[0];
    final stageStr = parts[1];
    
    String speciesType;
    switch (typeStr) {
      case 'dexter':
        speciesType = 'dog';
        break;
      case 'elly':
        speciesType = 'panda';
        break;
      case 'paxolotl':
        speciesType = 'axolotl';
        break;
      case 'yami':
        speciesType = 'jaguar';
        break;
      default:
        throw ArgumentError('Unknown companion type: $typeStr');
    }
    
    final petId = '${speciesType}_${stageStr}_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('🔄 [REPO] Mapped $localId -> petId: $petId, speciesType: $speciesType');
    return (petId, speciesType);
  }

  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : '';
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12,
      ownedCompanions: ownedCount,
      totalPoints: 500,
      spentPoints: ownedCount * 50,
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  Future<void> _updateLocalCacheAfterPurchase(String userId, CompanionModel purchasedCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);
    
    final index = companions.indexWhere((c) => c.id == purchasedCompanion.id);
    if (index != -1) {
      companions[index] = purchasedCompanion;
    } else {
      companions.add(purchasedCompanion);
    }
    
    await localDataSource.cacheCompanions(userId, companions);
    await localDataSource.cacheCompanion(purchasedCompanion);
    
    debugPrint('💾 [REPO] Cache local actualizado después de compra');
  }

  Future<void> _updateLocalCacheAfterEvolution(String userId, CompanionModel evolvedCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);
    
    final updatedCompanions = companions.map((comp) {
      if (comp.id == evolvedCompanion.id) {
        return evolvedCompanion;
      }
      return comp;
    }).toList();
    
    await localDataSource.cacheCompanions(userId, updatedCompanions);
    await localDataSource.cacheCompanion(evolvedCompanion);
    
    debugPrint('💾 [REPO] Cache local actualizado después de evolución');
  }

  Future<void> _updateLocalCacheAfterFeature(String userId, CompanionModel featuredCompanion) async {
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
          isSelected: comp.id == featuredCompanion.id,
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
    
    debugPrint('💾 [REPO] Cache local actualizado después de destacar');
  }

  // ==================== MÉTODOS LOCALES DE FALLBACK ====================

  Future<Either<Failure, CompanionEntity>> _purchaseCompanionLocal(String userId, String companionId) async {
    try {
      debugPrint('🛒 [REPO] === COMPRA LOCAL ===');
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionToPurchase = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado'),
      );
      
      // 🔧 VERIFICAR SI PUEDE COMPRAR (PUNTOS SUFICIENTES)
      final stats = await localDataSource.getCachedStats(userId);
      if (stats != null && stats.availablePoints < companionToPurchase.purchasePrice) {
        debugPrint('❌ [REPO] Puntos insuficientes: ${stats.availablePoints} < ${companionToPurchase.purchasePrice}');
        return Left(ValidationFailure('No tienes suficientes puntos'));
      }
      
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
          isOwned: true, // 🔧 AHORA ES PROPIEDAD DEL USUARIO
          isSelected: false,
          purchasedAt: DateTime.now(),
          currentMood: CompanionMood.happy,
          purchasePrice: companionToPurchase.purchasePrice,
          evolutionPrice: companionToPurchase.evolutionPrice,
          unlockedAnimations: companionToPurchase.unlockedAnimations,
          createdAt: companionToPurchase.createdAt,
        ),
      );

      await _updateLocalCacheAfterPurchase(userId, purchasedCompanion);
      
      // 🔧 ACTUALIZAR STATS (GASTAR PUNTOS)
      if (stats != null) {
        final updatedStats = CompanionStatsModel(
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
        );
        await localDataSource.cacheStats(updatedStats);
        debugPrint('💰 [REPO] Stats actualizados: puntos gastados ${companionToPurchase.purchasePrice}');
      }
      
      debugPrint('✅ [REPO] === COMPRA LOCAL COMPLETADA ===');
      return Right(purchasedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error en compra local: $e');
      return Left(UnknownFailure('Error en compra local: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _evolveCompanionLocal(String userId, String companionId) async {
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

    await _updateLocalCacheAfterEvolution(userId, evolvedCompanion);
    return Right(evolvedCompanion);
  }

  Future<Either<Failure, CompanionEntity>> _setActiveCompanionLocal(String userId, String companionId) async {
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
    
    return Right(activeCompanion);
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