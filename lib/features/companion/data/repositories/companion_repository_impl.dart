// lib/features/companion/data/repositories/companion_repository_impl.dart
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

  // 🔥 ACTIVAR API REAL Y QUITAR DEFAULT USER ID
  static const bool enableApiMode = true;

  CompanionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.tokenManager,
  });

  // 🔧 MÉTODO PARA OBTENER USER ID REAL
  Future<String> _getRealUserId() async {
    final userId = await tokenManager.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Usuario no autenticado');
    }
    return userId;
  }

  // ==================== OBTENER MASCOTAS DEL USUARIO ====================
  
  @override
  Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId) async {
    try {
      debugPrint('🐾 [REPO] === OBTENIENDO COMPAÑEROS DEL USUARIO ===');
      
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🚀 [REPO] Conectando con API real...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token válido, usando fallback local');
            return await _getLocalCompanions(realUserId);
          }

          // 🔥 LLAMADA A TU API REAL CON USER ID REAL
          final remoteCompanions = await remoteDataSource.getUserCompanions(realUserId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas');
          
          // Guardar en cache para uso offline
          await localDataSource.cacheCompanions(realUserId, remoteCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache');
          
          return Right(remoteCompanions);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error con API, fallback a local: $e');
          return await _getLocalCompanions(realUserId);
        }
      } else {
        debugPrint('📱 [REPO] Usando datos locales');
        return await _getLocalCompanions(realUserId);
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
        debugPrint('🚀 [REPO] Obteniendo tienda desde API real...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para tienda, usando fallback');
            return await _getLocalAvailableCompanions();
          }

          // 🔥 USAR USER ID REAL PARA LA TIENDA
          final realUserId = await _getRealUserId();
          
          final storeCompanions = await remoteDataSource.getStoreCompanions(
            userId: realUserId, // 🔥 USER ID REAL
          );
          
          debugPrint('🛍️ [REPO] Tienda API: ${storeCompanions.length} mascotas');
          
          for (final companion in storeCompanions) {
            debugPrint('🏪 [REPO] - ${companion.displayName}: ${companion.purchasePrice}★');
          }
          
          return Right(storeCompanions);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error con tienda API: $e');
          return await _getLocalAvailableCompanions();
        }
      } else {
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
      
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🚀 [REPO] Calculando stats desde API...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (hasValidToken) {
            // 🔥 LLAMADA A TU API PARA STATS CON USER ID REAL
            final stats = await remoteDataSource.getCompanionStats(realUserId);
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
      
      // 📱 MODO LOCAL: Usar cache local CON USER ID REAL
      debugPrint('📱 [REPO] Usando stats desde cache local');
      final localStats = await localDataSource.getCachedStats(realUserId);
      
      if (localStats != null) {
        debugPrint('✅ [REPO] Stats locales encontrados');
        return Right(localStats);
      } else {
        debugPrint('🔧 [REPO] Generando stats por defecto');
        final defaultStats = _generateDefaultStats(realUserId);
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
      
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario REAL: $realUserId');
      debugPrint('🐾 [REPO] Compañero: $companionId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');
      
      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🚀 [REPO] Adoptando via API real...');
        
        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token para adopción, usando simulación');
            return await _purchaseCompanionLocal(realUserId, companionId);
          }

          // 🔥 LLAMADA A TU API CON USER ID REAL Y PET ID REAL
          final adoptedCompanion = await remoteDataSource.adoptCompanion(
            userId: realUserId,    // 🔥 USER ID REAL
            petId: companionId,    // 🔥 SERÁ MAPEADO INTERNAMENTE AL PET ID REAL
          );
          
          debugPrint('✅ [REPO] Adopción exitosa: ${adoptedCompanion.displayName}');
          
          // Actualizar cache local
          await _updateLocalCacheAfterPurchase(realUserId, adoptedCompanion);
          
          return Right(adoptedCompanion);
          
        } catch (e) {
          debugPrint('❌ [REPO] Error adoptando via API: $e');
          
          if (e.toString().contains('ya adoptada') || e.toString().contains('already owned')) {
            return Left(ValidationFailure('Ya tienes esta mascota'));
          } else if (e.toString().contains('insufficient') || e.toString().contains('insuficientes')) {
            return Left(ValidationFailure('No tienes suficientes puntos'));
          } else {
            return Left(ServerFailure('Error adoptando mascota: ${e.toString()}'));
          }
        }
      } else {
        debugPrint('📱 [REPO] Simulando adopción local');
        return await _purchaseCompanionLocal(realUserId, companionId);
      }
    } catch (e) {
      debugPrint('💥 [REPO] Error en adopción: $e');
      return Left(UnknownFailure('Error en adopción: ${e.toString()}'));
    }
  }

  // ==================== MÉTODOS LOCALES (NO SOPORTADOS POR TU API AÚN) ====================
  
  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL INCLUSO EN MÉTODOS LOCALES
      final realUserId = await _getRealUserId();
      debugPrint('⭐ [REPO] Evolución local con USER ID REAL: $realUserId (API no implementada)');
      return await _evolveCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en evolución: $e');
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> setActiveCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('⭐ [REPO] Activación local con USER ID REAL: $realUserId (API no implementada)');
      return await _setActiveCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en activación: $e');
      return Left(UnknownFailure('Error en activación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('🍎 [REPO] Alimentación local con USER ID REAL: $realUserId (API no implementada)');
      return await _feedCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en alimentación: $e');
      return Left(UnknownFailure('Error en alimentación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> loveCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('💖 [REPO] Amor local con USER ID REAL: $realUserId (API no implementada)');
      return await _loveCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en amor: $e');
      return Left(UnknownFailure('Error en amor: ${e.toString()}'));
    }
  }

  // ==================== MÉTODOS HELPER PRIVADOS ====================

  Future<Either<Failure, List<CompanionEntity>>> _getLocalCompanions(String userId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      debugPrint('📱 [REPO] Local: ${companions.length} compañeros para usuario $userId');
      
      if (companions.isEmpty) {
        debugPrint('🔧 [REPO] Creando Dexter inicial para usuario $userId');
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
      // 🔥 USAR USER ID REAL INCLUSO PARA TIENDA LOCAL
      final realUserId = await _getRealUserId();
      debugPrint('🛍️ [REPO] Cargando tienda local para usuario: $realUserId');
      
      final companions = await localDataSource.getCachedCompanions(realUserId);
      
      if (companions.isEmpty) {
        final fullSet = await _createEmergencyCompanionSet();
        await localDataSource.cacheCompanions(realUserId, fullSet);
        return Right(fullSet);
      }
      
      return Right(companions);
    } catch (e) {
      debugPrint('❌ [REPO] Error tienda local: $e');
      final emergencySet = await _createEmergencyCompanionSet();
      return Right(emergencySet);
    }
  }

  CompanionStatsModel _generateDefaultStats(String userId) {
    debugPrint('📊 [REPO] Generando stats por defecto para usuario: $userId');
    return CompanionStatsModel(
      userId: userId, // 🔥 USER ID REAL
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
    debugPrint('🆘 [REPO] Creando compañero de emergencia para usuario: $userId');
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
    
    debugPrint('💾 [REPO] Cache local actualizado después de compra para usuario: $userId');
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
    
    debugPrint('💾 [REPO] Cache local actualizado después de evolución para usuario: $userId');
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
    
    debugPrint('💾 [REPO] Cache local actualizado después de destacar para usuario: $userId');
  }

  // ==================== MÉTODOS LOCALES DE FALLBACK ====================

  Future<Either<Failure, CompanionEntity>> _purchaseCompanionLocal(String userId, String companionId) async {
    try {
      debugPrint('💰 [REPO] Compra local para usuario: $userId, mascota: $companionId');
      
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
      debugPrint('⭐ [REPO] Evolución local para usuario: $userId, mascota: $companionId');
      
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
      debugPrint('⭐ [REPO] Activación local para usuario: $userId, mascota: $companionId');
      
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