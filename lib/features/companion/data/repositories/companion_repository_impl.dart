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

  // 🚀 ACTIVAR API REAL - CAMBIAR A false PARA VOLVER AL MODO LOCAL
  static const bool enableApiMode = true; // 🔥 true = USAR TU API REAL
  static const String defaultUserId = 'user_123';

  CompanionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.tokenManager,
  });

  // ==================== OBTENER MASCOTAS DEL USUARIO ====================
  
  @override
  Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId) async {
    try {
      debugPrint('🐾 [REPO] === OBTENIENDO COMPAÑEROS DEL USUARIO ===');
      debugPrint('👤 [REPO] Usuario ID: $userId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🌐 MODO API: Conectar con tu backend real
        debugPrint('🚀 [REPO] Conectando con API real...');
        
        try {
          // Verificar autenticación
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token válido, usando fallback local');
            return await _getLocalCompanions(userId);
          }

          // 🔥 LLAMADA A TU API REAL
          final remoteCompanions = await remoteDataSource.getUserCompanions(userId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas');
          
          // Guardar en cache para uso offline
          await localDataSource.cacheCompanions(userId, remoteCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache');
          
          return Right(remoteCompanions);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error con API, fallback a local: $e');
          // Si falla la API, usar cache local
          return await _getLocalCompanions(userId);
        }
      } else {
        // 📱 MODO LOCAL/OFFLINE
        debugPrint('📱 [REPO] Usando datos locales');
        return await _getLocalCompanions(userId);
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error general: $e');
      return Left(UnknownFailure('Error obteniendo compañeros: ${e.toString()}'));
    }
  }

  // ==================== TIENDA DE MASCOTAS (TU API) ====================
  
  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REPO] === OBTENIENDO TIENDA DE MASCOTAS ===');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🚀 CONECTAR CON TU ENDPOINT DE TIENDA
        debugPrint('🚀 [REPO] Obteniendo tienda desde API real...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para tienda, usando fallback');
            return await _getLocalAvailableCompanions();
          }

          // 🔥 LLAMADA A TU API: /api/gamification/pets/store
          final storeCompanions = await remoteDataSource.getStoreCompanions(
            userId: defaultUserId, // Usar el userId real aquí
          );
          
          debugPrint('🛍️ [REPO] Tienda API: ${storeCompanions.length} mascotas');
          
          // Log de mascotas específicas para debugging
          for (final companion in storeCompanions) {
            debugPrint('🏪 [REPO] - ${companion.displayName}: ${companion.purchasePrice}★');
          }
          
          return Right(storeCompanions);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error con tienda API: $e');
          return await _getLocalAvailableCompanions();
        }
      } else {
        // Fallback local
        debugPrint('📱 [REPO] Usando tienda local');
        return await _getLocalAvailableCompanions();
      }
    } catch (e) {
      debugPrint('❌ [REPO] Error obteniendo tienda: $e');
      return Left(CacheFailure('Error obteniendo tienda: ${e.toString()}'));
    }
  }

  // ==================== ESTADÍSTICAS (TU API) ====================
  
  @override
  Future<Either<Failure, CompanionStatsEntity>> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REPO] === OBTENIENDO ESTADÍSTICAS ===');
      debugPrint('👤 [REPO] Usuario ID: $userId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🚀 OBTENER STATS DESDE TU API
        debugPrint('🚀 [REPO] Calculando stats desde API...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (hasValidToken) {
            // 🔥 LLAMADA A TU API PARA STATS
            final stats = await remoteDataSource.getCompanionStats(userId);
            await localDataSource.cacheStats(stats);
            
            debugPrint('📊 [REPO] Stats API calculados y guardados');
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

  // ==================== COMPRAR/ADOPTAR MASCOTA (TU API) ====================
  
  @override
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    try {
      debugPrint('🛒 [REPO] === INICIANDO COMPRA/ADOPCIÓN ===');
      debugPrint('👤 [REPO] Usuario: $userId');
      debugPrint('🐾 [REPO] Compañero: $companionId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        // 🚀 ADOPTAR VIA TU API REAL
        debugPrint('🚀 [REPO] Adoptando via API real...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para adopción, usando simulación');
            return await _purchaseCompanionLocal(userId, companionId);
          }

          // 🔥 GENERAR PET ID PARA TU API
          final apiPetId = _generateApiPetId(companionId);
          debugPrint('🔄 [REPO] Companion ID: $companionId -> API Pet ID: $apiPetId');
          
          // 🔥 LLAMADA A TU API: POST /api/gamification/pets/{userId}/adopt
          final adoptedCompanion = await remoteDataSource.adoptCompanion(
            userId: userId,
            petId: apiPetId,
          );
          
          debugPrint('✅ [REPO] Adopción exitosa: ${adoptedCompanion.displayName}');
          
          // Actualizar cache local
          await _updateLocalCacheAfterPurchase(userId, adoptedCompanion);
          
          return Right(adoptedCompanion);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error adoptando via API: $e');
          
          // Fallback a adopción local
          if (e.toString().contains('ya adoptada') || e.toString().contains('already owned')) {
            return Left(ValidationFailure('Ya tienes esta mascota'));
          } else if (e.toString().contains('insufficient') || e.toString().contains('insuficientes')) {
            return Left(ValidationFailure('No tienes suficientes puntos'));
          } else {
            return Left(ServerFailure('Error adoptando mascota: ${e.toString()}'));
          }
        }
      } else {
        // 📱 MODO LOCAL: Simulación de compra
        debugPrint('📱 [REPO] Simulando adopción local');
        return await _purchaseCompanionLocal(userId, companionId);
      }
    } catch (e) {
      debugPrint('💥 [REPO] Error en adopción: $e');
      return Left(UnknownFailure('Error en adopción: ${e.toString()}'));
    }
  }

  // ==================== MÉTODOS LOCALES (NO SOPORTADOS POR TU API AÚN) ====================
  
  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId) async {
    // 🔧 EVOLUCIÓN SIEMPRE LOCAL (TU API NO LO SOPORTA AÚN)
    debugPrint('⭐ [REPO] Evolución local (API no implementada)');
    return await _evolveCompanionLocal(userId, companionId);
  }

  @override
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId) async {
    // 🔧 ACTIVAR SIEMPRE LOCAL (TU API NO LO SOPORTA AÚN)
    debugPrint('⭐ [REPO] Activación local (API no implementada)');
    return await _setActiveCompanionLocal(userId, companionId);
  }

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    // 🔧 ALIMENTAR SIEMPRE LOCAL (TU API NO LO SOPORTA AÚN)
    debugPrint('🍎 [REPO] Alimentación local (API no implementada)');
    return await _feedCompanionLocal(userId, companionId);
  }

  @override
  Future<Either<Failure, CompanionEntity>> loveCompanion(String userId, String companionId) async {
    // 🔧 AMOR SIEMPRE LOCAL (TU API NO LO SOPORTA AÚN)
    debugPrint('💖 [REPO] Amor local (API no implementada)');
    return await _loveCompanionLocal(userId, companionId);
  }

  // ==================== MÉTODOS HELPER PRIVADOS ====================

  Future<Either<Failure, List<CompanionEntity>>> _getLocalCompanions(String userId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      debugPrint('📱 [REPO] Local: ${companions.length} compañeros');
      
      if (companions.isEmpty) {
        debugPrint('🔧 [REPO] Creando Dexter inicial');
        final initialCompanion = await _createEmergencyCompanion(userId);
        await localDataSource.cacheCompanions(userId, [initialCompanion]);
        return Right([initialCompanion]);
      }
      
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error local: $e');
      final emergencyCompanion = await _createEmergencyCompanion(userId);
      return Right([emergencyCompanion]);
    }
  }

  Future<Either<Failure, List<CompanionEntity>>> _getLocalAvailableCompanions() async {
    try {
      const userId = defaultUserId;
      final companions = await localDataSource.getCachedCompanions(userId);
      
      if (companions.isEmpty) {
        final fullSet = await _createEmergencyCompanionSet();
        await localDataSource.cacheCompanions(userId, fullSet);
        return Right(fullSet);
      }
      
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error tienda local: $e');
      final emergencySet = await _createEmergencyCompanionSet();
      return Right(emergencySet);
    }
  }

  /// Generar Pet ID para tu API basado en companion local
  String _generateApiPetId(String companionId) {
    // Mapear IDs locales a IDs de tu API
    final typeStageMap = {
      'dexter_baby': 'perro-bebe-001',
      'dexter_young': 'perro-joven-001', 
      'dexter_adult': 'perro-adulto-001',
      'elly_baby': 'panda-bebe-001',
      'elly_young': 'panda-joven-001',
      'elly_adult': 'panda-adulto-001',
      'paxolotl_baby': 'ajolote-bebe-001',
      'paxolotl_young': 'ajolote-joven-001',
      'paxolotl_adult': 'ajolote-adulto-001',
      'yami_baby': 'jaguar-bebe-001',
      'yami_young': 'jaguar-joven-001',
      'yami_adult': 'jaguar-adulto-001',
    };
    
    return typeStageMap[companionId] ?? 'mascota-generica-001';
  }

  CompanionStatsModel _generateDefaultStats(String userId) {
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12,
      ownedCompanions: 1,
      totalPoints: 1000, // 🔥 PUNTOS GENEROSOS PARA TESTING
      spentPoints: 0,
      activeCompanionId: 'dexter_young',
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  Future<CompanionModel> _createEmergencyCompanion(String userId) async {
    return CompanionModel(
      id: 'dexter_young',
      type: CompanionType.dexter,
      stage: CompanionStage.young,
      name: 'Dexter',
      description: 'Tu primer compañero, un chihuahua joven lleno de energía',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: true,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0,
      evolutionPrice: 100,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating'],
      createdAt: DateTime.now(),
    );
  }

  Future<List<CompanionModel>> _createEmergencyCompanionSet() async {
    final now = DateTime.now();
    
    return [
      // Dexter (gratuito inicial)
      CompanionModel(
        id: 'dexter_young',
        type: CompanionType.dexter,
        stage: CompanionStage.young,
        name: 'Dexter',
        description: 'Tu primer compañero gratuito',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      
      // Elly (compra)
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
        purchasePrice: 200, // 🔥 PRECIO REALISTA PARA TU API
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'eating'],
        createdAt: now,
      ),
      
      // Paxolotl (compra premium)
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un pequeño ajolote de Xochimilco',
        level: 1,
        experience: 0,
        happiness: 90,
        hunger: 85,
        energy: 80,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 300, // 🔥 PRECIO PREMIUM
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'swimming'],
        createdAt: now,
      ),
      
      // Yami (muy premium)
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
        purchasePrice: 500, // 🔥 PRECIO MUY PREMIUM
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'prowling'],
        createdAt: now,
      ),
    ];
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
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionToPurchase = companions.firstWhere(
        (c) => c.id == companionId,
        orElse: () => throw Exception('Compañero no encontrado'),
      );
      
      final stats = await localDataSource.getCachedStats(userId);
      if (stats != null && stats.availablePoints < companionToPurchase.purchasePrice) {
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
      
      return Right(purchasedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error en compra local: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _evolveCompanionLocal(String userId, String companionId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      final companion = companions.firstWhere((c) => c.id == companionId);

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
          description: 'Versión evolucionada de ${companion.name}',
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
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
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
      return Left(UnknownFailure('Error activando: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _feedCompanionLocal(String userId, String companionId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      final companion = companions.firstWhere((c) => c.id == companionId);

      if (!companion.isOwned) {
        return Left(ValidationFailure('Este compañero no te pertenece'));
      }

      final fedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience + 25,
          happiness: (companion.happiness + 15).clamp(0, 100),
          hunger: 100,
          energy: companion.energy,
          isOwned: companion.isOwned,
          isSelected: companion.isSelected,
          purchasedAt: companion.purchasedAt,
          lastFeedTime: DateTime.now(),
          lastLoveTime: companion.lastLoveTime,
          currentMood: CompanionMood.happy,
          purchasePrice: companion.purchasePrice,
          evolutionPrice: companion.evolutionPrice,
          unlockedAnimations: companion.unlockedAnimations,
          createdAt: companion.createdAt,
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

      return Right(fedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error alimentando: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _loveCompanionLocal(String userId, String companionId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      final companion = companions.firstWhere((c) => c.id == companionId);

      if (!companion.isOwned) {
        return Left(ValidationFailure('Este compañero no te pertenece'));
      }

      final lovedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience + 20,
          happiness: 100,
          hunger: companion.hunger,
          energy: (companion.energy + 20).clamp(0, 100),
          isOwned: companion.isOwned,
          isSelected: companion.isSelected,
          purchasedAt: companion.purchasedAt,
          lastFeedTime: companion.lastFeedTime,
          lastLoveTime: DateTime.now(),
          currentMood: CompanionMood.excited,
          purchasePrice: companion.purchasePrice,
          evolutionPrice: companion.evolutionPrice,
          unlockedAnimations: companion.unlockedAnimations,
          createdAt: companion.createdAt,
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

      return Right(lovedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error dando amor: ${e.toString()}'));
    }
  }
}