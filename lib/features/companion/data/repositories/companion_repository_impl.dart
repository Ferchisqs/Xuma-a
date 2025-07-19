// lib/features/companion/data/repositories/companion_repository_impl.dart - COMPLETO Y CORREGIDO
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

  // 🔧 CONFIGURACIÓN DE MODO
  static const bool useApiMode = true; // 🆕 CAMBIAR A true PARA USAR API
  static const String defaultUserId = 'user_123'; // TODO: Obtener del auth service

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
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - USAR DATOS REMOTOS
        debugPrint('🌐 [REPO] Usando API remota para obtener mascotas');
        
        try {
          final remoteCompanions = await remoteDataSource.getUserCompanions(userId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas');
          
          // Guardar en cache para uso offline
          await localDataSource.cacheCompanions(userId, remoteCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache local');
          
          return Right(remoteCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API, intentando cache local: $e');
          
          // Fallback a datos locales si falla la API
          final localCompanions = await localDataSource.getCachedCompanions(userId);
          if (localCompanions.isNotEmpty) {
            debugPrint('📱 [REPO] Usando ${localCompanions.length} mascotas desde cache');
            return Right(localCompanions);
          } else {
            throw e; // Re-lanzar error si no hay cache
          }
        }
      } else {
        // 🔧 MODO LOCAL O SIN CONEXIÓN
        debugPrint('📱 [REPO] Usando datos locales');
        final localCompanions = await localDataSource.getCachedCompanions(userId);
        debugPrint('📱 [REPO] Cache local devolvió ${localCompanions.length} mascotas');
        
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
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🏪 [REPO] === OBTENIENDO COMPAÑEROS DISPONIBLES ===');
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - OBTENER DESDE TIENDA
        debugPrint('🌐 [REPO] Obteniendo mascotas disponibles desde API');
        
        try {
          final storeCompanions = await remoteDataSource.getStoreCompanions();
          debugPrint('🛍️ [REPO] API devolvió ${storeCompanions.length} mascotas en tienda');
          
          return Right(storeCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API store, usando datos locales: $e');
          // Fallback a datos locales
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
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - CALCULAR DESDE MASCOTAS REMOTAS
        debugPrint('🌐 [REPO] Calculando stats desde API');
        
        try {
          final companions = await remoteDataSource.getUserCompanions(userId);
          final stats = _calculateStatsFromCompanions(userId, companions);
          
          // Guardar stats en cache
          await localDataSource.cacheStats(stats);
          debugPrint('✅ [REPO] Stats API calculados y guardados');
          
          return Right(stats);
        } catch (e) {
          debugPrint('❌ [REPO] Error calculando stats desde API: $e');
          // Fallback a cache local
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
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - ADOPTAR/COMPRAR DESDE API
        debugPrint('🌐 [REPO] Adoptando mascota via API');
        
        try {
          // Extraer información del companionId local para la API
          final (petId, speciesType) = _extractApiInfoFromLocalId(companionId);
          
          final adoptedCompanion = await remoteDataSource.adoptCompanion(userId, petId, speciesType);
          debugPrint('✅ [REPO] Mascota adoptada via API: ${adoptedCompanion.displayName}');
          
          // Actualizar cache local
          await _updateLocalCacheAfterPurchase(userId, adoptedCompanion);
          
          return Right(adoptedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error adoptando via API: $e');
          return Left(ServerFailure('Error adoptando mascota: ${e.toString()}'));
        }
      } else {
        // 🔧 MODO LOCAL - SIMULACIÓN
        debugPrint('📱 [REPO] Simulando compra local');
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
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - EVOLUCIONAR VIA API
        debugPrint('🌐 [REPO] Evolucionando via API');
        
        try {
          final (petId, _) = _extractApiInfoFromLocalId(companionId);
          
          final evolvedCompanion = await remoteDataSource.evolveCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota evolucionada via API: ${evolvedCompanion.displayName}');
          
          // Actualizar cache local
          await _updateLocalCacheAfterEvolution(userId, evolvedCompanion);
          
          return Right(evolvedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error evolucionando via API: $e');
          return Left(ServerFailure('Error evolucionando: ${e.toString()}'));
        }
      } else {
        // 🔧 MODO LOCAL - SIMULACIÓN
        debugPrint('📱 [REPO] Simulando evolución local');
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
      debugPrint('🌐 [REPO] Modo API: $useApiMode');
      
      if (useApiMode && await networkInfo.isConnected) {
        // 🆕 MODO API - DESTACAR VIA API
        debugPrint('🌐 [REPO] Destacando mascota via API');
        
        try {
          final (petId, _) = _extractApiInfoFromLocalId(companionId);
          
          final featuredCompanion = await remoteDataSource.featureCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota destacada via API: ${featuredCompanion.displayName}');
          
          // Actualizar cache local
          await _updateLocalCacheAfterFeature(userId, featuredCompanion);
          
          return Right(featuredCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error destacando via API: $e');
          return Left(ServerFailure('Error destacando mascota: ${e.toString()}'));
        }
      } else {
        // 🔧 MODO LOCAL - SIMULACIÓN
        debugPrint('📱 [REPO] Simulando activación local');
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

  // ==================== 🆕 MÉTODOS HELPER PARA API ====================

  /// Extrae información necesaria para la API desde el ID local
  (String petId, String speciesType) _extractApiInfoFromLocalId(String localId) {
    // localId format: "dexter_baby", "elly_young", etc.
    final parts = localId.split('_');
    if (parts.length != 2) {
      throw ArgumentError('Invalid local companion ID format: $localId');
    }
    
    final typeStr = parts[0];
    final stageStr = parts[1];
    
    // Mapear tipo local a species_type de API
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
    
    // Generar petId único para la API
    final petId = '${speciesType}_${stageStr}_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('🔄 [REPO] Mapped $localId -> petId: $petId, speciesType: $speciesType');
    return (petId, speciesType);
  }

  /// Calcula estadísticas desde una lista de mascotas
  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : '';
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: ownedCount,
      totalPoints: 999999, // TODO: Obtener desde API de puntos
      spentPoints: ownedCount * 50, // Estimado
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0, // TODO: Implementar si la API lo soporta
      totalLoveCount: 0, // TODO: Implementar si la API lo soporta
      totalEvolutions: 0, // TODO: Implementar si la API lo soporta
      lastActivity: DateTime.now(),
    );
  }

  /// Actualiza cache local después de una compra
  Future<void> _updateLocalCacheAfterPurchase(String userId, CompanionModel purchasedCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);
    
    // Buscar si ya existe y actualizar, o agregar si no existe
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

  /// Actualiza cache local después de una evolución
  Future<void> _updateLocalCacheAfterEvolution(String userId, CompanionModel evolvedCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);
    
    // Actualizar la mascota evolucionada
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

  /// Actualiza cache local después de destacar una mascota
  Future<void> _updateLocalCacheAfterFeature(String userId, CompanionModel featuredCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);
    
    // Desactivar todas las demás y activar la destacada
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
    // Implementación local existente...
    final companions = await localDataSource.getCachedCompanions(userId);
    final companionToPurchase = companions.firstWhere(
      (c) => c.id == companionId,
      orElse: () => throw Exception('Compañero no encontrado'),
    );
    
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

    await _updateLocalCacheAfterPurchase(userId, purchasedCompanion);
    return Right(purchasedCompanion);
  }

  Future<Either<Failure, CompanionEntity>> _evolveCompanionLocal(String userId, String companionId) async {
    // Implementación local existente para evolución...
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
    // Implementación local existente para activar...
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