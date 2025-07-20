// lib/features/companion/data/repositories/companion_repository_impl.dart - COMPLETO
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/token_manager.dart';
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
  final TokenManager tokenManager;

  // 🔧 ACTIVAR API REAL - CAMBIAR A false PARA VOLVER AL MODO LOCAL
  static const bool enableApiMode = true; // 🚀 true = USAR API REAL
  static const String defaultUserId = 'user_123';

  CompanionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.tokenManager,
  });

  @override
  Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId) async {
    try {
      debugPrint('🐾 [REPO] === OBTENIENDO COMPAÑEROS DEL USUARIO ===');
      debugPrint('👤 [REPO] Usuario ID: $userId');
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Intentar obtener desde la API real
        debugPrint('🌐 [REPO] Usando API de gamificación...');
        
        try {
          // Verificar si hay token válido
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] No hay token válido, usando datos locales como fallback');
            return await _getLocalCompanions(userId);
          }

          final remoteCompanions = await remoteDataSource.getUserCompanions(userId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas');
          
          // Guardar en cache local para uso offline
          await localDataSource.cacheCompanions(userId, remoteCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache local');
          
          return Right(remoteCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API, fallback a local: $e');
          return await _getLocalCompanions(userId);
        }
      } else {
        // 📱 MODO LOCAL: Usar datos locales
        if (!enableApiMode) {
          debugPrint('📱 [REPO] API Mode deshabilitado, usando datos locales');
        } else {
          debugPrint('📱 [REPO] Sin conexión, usando datos locales');
        }
        return await _getLocalCompanions(userId);
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error general obteniendo compañeros: $e');
      return Left(UnknownFailure('Error obteniendo compañeros: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REPO] === OBTENIENDO COMPAÑEROS DISPONIBLES ===');
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Obtener desde tienda real
        debugPrint('🌐 [REPO] Obteniendo tienda desde API...');
        
        try {
          final storeCompanions = await remoteDataSource.getStoreCompanions();
          debugPrint('🛍️ [REPO] API devolvió ${storeCompanions.length} mascotas en tienda');
          
          return Right(storeCompanions);
        } catch (e) {
          debugPrint('❌ [REPO] Error con API tienda, usando datos locales: $e');
        }
      }
      
      // 📱 MODO LOCAL: Fallback a datos locales
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
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Calcular stats desde API
        debugPrint('🌐 [REPO] Calculando stats desde API');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (hasValidToken) {
            final stats = await remoteDataSource.getCompanionStats(userId);
            await localDataSource.cacheStats(stats);
            debugPrint('✅ [REPO] Stats API calculados y guardados');
            return Right(stats);
          } else {
            debugPrint('⚠️ [REPO] Sin token válido para stats, usando cache local');
          }
        } catch (e) {
          debugPrint('❌ [REPO] Error obteniendo stats desde API: $e');
        }
      }
      
      // 📱 MODO LOCAL: Usar cache local
      debugPrint('📱 [REPO] Usando stats desde cache local');
      final localStats = await localDataSource.getCachedStats(userId);
      
      if (localStats != null) {
        debugPrint('✅ [REPO] Stats locales encontrados');
        return Right(localStats);
      } else {
        debugPrint('🔧 [REPO] Generando stats por defecto');
        final defaultStats = _generateDefaultStats(userId);
        await localDataSource.cacheStats(defaultStats);
        return Right(defaultStats);
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error obteniendo stats: $e');
      return Left(UnknownFailure('Error obteniendo estadísticas: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    try {
      debugPrint('🛒 [REPO] === INICIANDO COMPRA ===');
      debugPrint('👤 [REPO] Usuario: $userId');
      debugPrint('🐾 [REPO] Compañero: $companionId');
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Compra real a través de la API
        debugPrint('🌐 [REPO] Comprando via API de gamificación');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] No hay token válido para compra, usando simulación local');
            return await _purchaseCompanionLocal(userId, companionId);
          }

          // Extraer petId de la API desde el companionId local
          final petId = await _findApiPetId(companionId);
          if (petId == null) {
            debugPrint('❌ [REPO] No se encontró petId para companionId: $companionId');
            return Left(ValidationFailure('Mascota no encontrada'));
          }

          // Intentar adopción primero, luego compra como fallback
          CompanionModel purchasedCompanion;
          try {
            purchasedCompanion = await remoteDataSource.adoptCompanion(userId, petId);
            debugPrint('✅ [REPO] Mascota adoptada via API: ${purchasedCompanion.displayName}');
          } catch (adoptError) {
            debugPrint('⚠️ [REPO] Adopción falló, intentando compra: $adoptError');
            purchasedCompanion = await remoteDataSource.purchaseCompanion(userId, petId);
            debugPrint('✅ [REPO] Mascota comprada via API: ${purchasedCompanion.displayName}');
          }
          
          await _updateLocalCacheAfterPurchase(userId, purchasedCompanion);
          
          return Right(purchasedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error comprando via API: $e');
          return Left(ServerFailure('Error comprando mascota: ${e.toString()}'));
        }
      } else {
        // 📱 MODO LOCAL: Simulación de compra
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
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Evolución real
        debugPrint('🌐 [REPO] Evolucionando via API');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para evolución, usando simulación local');
            return await _evolveCompanionLocal(userId, companionId);
          }

          final petId = await _findApiPetId(companionId);
          if (petId == null) {
            debugPrint('❌ [REPO] No se encontró petId para evolución: $companionId');
            return await _evolveCompanionLocal(userId, companionId);
          }
          
          final evolvedCompanion = await remoteDataSource.evolveCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota evolucionada via API: ${evolvedCompanion.displayName}');
          
          await _updateLocalCacheAfterEvolution(userId, evolvedCompanion);
          
          return Right(evolvedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error evolucionando via API: $e');
          return await _evolveCompanionLocal(userId, companionId);
        }
      } else {
        // 📱 MODO LOCAL: Simulación de evolución
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
      debugPrint('🌐 [REPO] API Mode habilitado: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Destacar via API
        debugPrint('🌐 [REPO] Destacando mascota via API');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para activar, usando simulación local');
            return await _setActiveCompanionLocal(userId, companionId);
          }

          final petId = await _findApiPetId(companionId);
          if (petId == null) {
            debugPrint('❌ [REPO] No se encontró petId para activar: $companionId');
            return await _setActiveCompanionLocal(userId, companionId);
          }
          
          final featuredCompanion = await remoteDataSource.featureCompanion(userId, petId);
          debugPrint('✅ [REPO] Mascota destacada via API: ${featuredCompanion.displayName}');
          
          await _updateLocalCacheAfterFeature(userId, featuredCompanion);
          
          return Right(featuredCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error destacando via API: $e');
          return await _setActiveCompanionLocal(userId, companionId);
        }
      } else {
        // 📱 MODO LOCAL: Activación local
        debugPrint('📱 [REPO] Activando localmente');
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

  // ==================== 🔧 MÉTODOS HELPER PRIVADOS ====================

  Future<Either<Failure, List<CompanionEntity>>> _getLocalCompanions(String userId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      debugPrint('📱 [REPO] Local devolvió ${companions.length} compañeros');
      
      // 🔧 SI NO HAY COMPAÑEROS LOCALES, CREAR AL MENOS DEXTER INICIAL
      if (companions.isEmpty) {
        debugPrint('🔧 [REPO] No hay compañeros locales, creando Dexter inicial');
        final initialCompanion = await _createEmergencyCompanion(userId);
        await localDataSource.cacheCompanions(userId, [initialCompanion]);
        return Right([initialCompanion]);
      }
      
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error obteniendo compañeros locales: $e');
      
      // 🔧 ÚLTIMO RECURSO: CREAR DEXTER INICIAL
      final emergencyCompanion = await _createEmergencyCompanion(userId);
      return Right([emergencyCompanion]);
    }
  }

  Future<Either<Failure, List<CompanionEntity>>> _getLocalAvailableCompanions() async {
    try {
      // 🔧 SIEMPRE DEVOLVER SET COMPLETO DE MASCOTAS DISPONIBLES
      const userId = defaultUserId;
      final companions = await localDataSource.getCachedCompanions(userId);
      
      if (companions.isEmpty) {
        debugPrint('🔧 [REPO] No hay mascotas locales, creando set completo');
        final fullSet = await _createEmergencyCompanionSet();
        await localDataSource.cacheCompanions(userId, fullSet);
        return Right(fullSet);
      }
      
      debugPrint('🛍️ [REPO] Tienda local: ${companions.length} mascotas disponibles');
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error obteniendo tienda local: $e');
      
      // 🔧 ÚLTIMO RECURSO: CREAR SET BÁSICO
      final emergencySet = await _createEmergencyCompanionSet();
      return Right(emergencySet);
    }
  }

  CompanionStatsModel _generateDefaultStats(String userId) {
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12,
      ownedCompanions: 1, // Al menos Dexter inicial
      totalPoints: 500,   // Puntos generosos para empezar
      spentPoints: 0,
      activeCompanionId: 'dexter_baby',
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  /// Crear Dexter inicial como mascota de emergencia
  Future<CompanionModel> _createEmergencyCompanion(String userId) async {
    debugPrint('🚨 [REPO] Creando Dexter de emergencia para usuario: $userId');
    
    return CompanionModel(
      id: 'dexter_baby',
      type: CompanionType.dexter,
      stage: CompanionStage.baby,
      name: 'Dexter',
      description: 'Tu primer compañero, un adorable chihuahua bebé',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,  // 🔧 MASCOTA INICIAL GRATUITA
      isSelected: true, // 🔧 ACTIVA POR DEFECTO
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔧 GRATIS
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
      createdAt: DateTime.now(),
    );
  }

  /// Crear set completo de mascotas para emergencias
  Future<List<CompanionModel>> _createEmergencyCompanionSet() async {
    debugPrint('🚨 [REPO] Creando set completo de emergencia');
    
    final now = DateTime.now();
    
    return [
      // 🐕 DEXTER - Gratuito como inicial
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un adorable chihuahua bebé lleno de energía',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 0, // 🔧 GRATIS COMO INICIAL
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      
      // 🐼 ELLY - Primera opción de compra
      CompanionModel(
        id: 'elly_baby',
        type: CompanionType.elly,
        stage: CompanionStage.baby,
        name: 'Elly',
        description: 'Una tierna panda bebé que ama el bambú',
        level: 1,
        experience: 0,
        happiness: 95,
        hunger: 80,
        energy: 90,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 100,
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'eating'],
        createdAt: now,
      ),
      
      // 🦎 PAXOLOTL - Segunda opción
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un pequeño ajolote lleno de curiosidad',
        level: 1,
        experience: 0,
        happiness: 90,
        hunger: 85,
        energy: 80,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 150,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'swimming'],
        createdAt: now,
      ),
      
      // 🐆 YAMI - Opción premium
      CompanionModel(
        id: 'yami_baby',
        type: CompanionType.yami,
        stage: CompanionStage.baby,
        name: 'Yami',
        description: 'Un jaguar bebé feroz pero tierno',
        level: 1,
        experience: 0,
        happiness: 85,
        hunger: 75,
        energy: 95,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 200,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'prowling'],
        createdAt: now,
      ),
    ];
  }

  Future<String?> _findApiPetId(String localCompanionId) async {
    try {
      // TODO: Implementar mapeo local ID → API Pet ID
      // Por ahora, generar un ID basado en el tipo y etapa
      final parts = localCompanionId.split('_');
      if (parts.length == 2) {
        final type = parts[0];
        final stage = parts[1];
        return 'api_${type}_${stage}_${DateTime.now().millisecondsSinceEpoch}';
      }
      return null;
    } catch (e) {
      debugPrint('❌ [REPO] Error buscando API Pet ID: $e');
      return null;
    }
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
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      final companion = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado'),
      );

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
    } catch (e) {
      debugPrint('❌ [REPO] Error en evolución local: $e');
      return Left(UnknownFailure('Error en evolución local: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _setActiveCompanionLocal(String userId, String companionId) async {
    try {
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
    } catch (e) {
      debugPrint('❌ [REPO] Error activando compañero local: $e');
      return Left(UnknownFailure('Error activando compañero local: ${e.toString()}'));
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