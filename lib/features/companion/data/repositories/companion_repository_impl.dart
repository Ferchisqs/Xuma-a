// lib/features/companion/data/repositories/companion_repository_impl.dart
// 🔥 REPOSITORIO MEJORADO CON API REAL CONECTADA + ACCIONES LOCALES ARREGLADAS

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
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

  // 🔥 ACTIVAR API REAL
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
 @override
  Future<Either<Failure, CompanionEntity>> increasePetStats({
    required String userId,
    required String petId,
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📈 [REPO] === AUMENTANDO STATS VIA API REAL ===');
      // Usar user ID real del token
      final realUserId = await _getRealUserId();

      if (enableApiMode && await networkInfo.isConnected) {
        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          // 🔥 LLAMAR AL ENDPOINT REAL DE INCREASE STATS
          final updatedCompanion = await remoteDataSource.increasePetStats(
            petId: petId,
            happiness: happiness,
            health: health,
          );

          // Guardar en cache local
          await localDataSource.cacheCompanion(updatedCompanion);
          await _updateLocalCacheAfterStatsChange(realUserId, updatedCompanion);

          return Right(updatedCompanion);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return await _increaseStatsLocal(realUserId, petId, happiness, health);
      }
    } catch (e) {
      return Left(UnknownFailure('Error aumentando estadísticas: ${e.toString()}'));
    }
  }

  // ==================== 🔥 REDUCIR ESTADÍSTICAS VIA API REAL - MEJORADO ====================
  @override
  Future<Either<Failure, CompanionEntity>> decreasePetStats({
    required String userId,
    required String petId,
    int? happiness,
    int? health,
  }) async {
    try {
      debugPrint('📉 [REPO] === REDUCIENDO STATS VIA API REAL ===');
      // Usar user ID real del token
      final realUserId = await _getRealUserId();

      if (enableApiMode && await networkInfo.isConnected) {
        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          // 🔥 LLAMAR AL ENDPOINT REAL DE DECREASE STATS (CORRECCIÓN IMPORTANTE)
          final updatedCompanion = await remoteDataSource.decreasePetStats(
            petId: petId,
            happiness: happiness,
            health: health,
          );

          // Guardar en cache local
          await localDataSource.cacheCompanion(updatedCompanion);
          await _updateLocalCacheAfterStatsChange(realUserId, updatedCompanion);

          return Right(updatedCompanion);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return await _decreaseStatsLocal(realUserId, petId, happiness, health);
      }
    } catch (e) {
      return Left(UnknownFailure('Error reduciendo estadísticas: ${e.toString()}'));
    }
  }
  // ==================== OBTENER MASCOTAS DEL USUARIO ====================
 @override
Future<Either<Failure, List<CompanionEntity>>> getUserCompanions(String userId) async {
  try {
    // 🔥 USAR USER ID REAL DEL TOKEN
    final realUserId = await _getRealUserId();

    if (enableApiMode && await networkInfo.isConnected) {
      try {
        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          return await _getLocalCompanions(realUserId);
        }

        // 🔥 OBTENER MASCOTAS CON ESTADÍSTICAS REALES DESDE LA API
        final remoteCompanions = await remoteDataSource.getUserCompanions(realUserId);

        List<CompanionModel> finalCompanions = [];
        
        // 🔥 PROCESAR CADA MASCOTA PARA OBTENER SUS idUserPet
        for (int i = 0; i < remoteCompanions.length; i++) {
          final companion = remoteCompanions[i];
          
          try {
            // 🔥 OBTENER DETALLES COMPLETOS CON AMBOS IDs
            if (companion is CompanionModelWithPetId) {
              final originalPetId = companion.petId;
              debugPrint('🔄 [REPO] Obteniendo detalles para pet_id: $originalPetId');
              
              // 🔥 LLAMAR A getPetDetails CON EL pet_id ORIGINAL
              final detailedCompanion = await remoteDataSource.getPetDetails(
                petId: originalPetId,  // ✅ pet_id PARA DETALLES
                userId: realUserId,
              );
              
              // 🔥 VERIFICAR QUE SEA CompanionModelWithBothIds
              if (detailedCompanion is CompanionModelWithBothIds) {
                debugPrint('✅ [REPO] Companion con ambos IDs:');
                debugPrint('   pet_id: ${detailedCompanion.originalPetId}');
                debugPrint('   idUserPet: ${detailedCompanion.idUserPet}');
                
                finalCompanions.add(detailedCompanion.copyWith(
                  isOwned: true,
                  isSelected: i == 0,
                ));
              } else {
                debugPrint('⚠️ [REPO] Companion sin ambos IDs, usando básico');
                finalCompanions.add(companion.copyWith(
                  isOwned: true,
                  isSelected: i == 0,
                ));
              }
            } else {
              finalCompanions.add(companion.copyWith(
                isOwned: true,
                isSelected: i == 0,
              ));
            }
          } catch (detailsError) {
            debugPrint('⚠️ [REPO] Error obteniendo detalles: $detailsError');
            // Usar companion básico como fallback
            finalCompanions.add(companion.copyWith(
              isOwned: true,
              isSelected: i == 0,
            ));
          }
        }

        // 🔧 ASEGURAR QUE AL MENOS UNA ESTÉ ACTIVA
        if (finalCompanions.isNotEmpty && !finalCompanions.any((c) => c.isSelected)) {
          finalCompanions[0] = finalCompanions[0].copyWith(isSelected: true);
        }

        // Guardar en cache
        await localDataSource.cacheCompanions(realUserId, finalCompanions);
        
        debugPrint('✅ [REPO] === MASCOTAS CON AMBOS IDs PROCESADAS ===');
        for (int i = 0; i < finalCompanions.length; i++) {
          final companion = finalCompanions[i];
          if (companion is CompanionModelWithBothIds) {
            debugPrint('[$i] ${companion.displayName}:');
            debugPrint('    pet_id: ${companion.originalPetId}');
            debugPrint('    idUserPet: ${companion.idUserPet}');
          } else {
            debugPrint('[$i] ${companion.displayName}: Sin ambos IDs');
          }
        }
        
        return Right(finalCompanions);
      } catch (e) {
        return await _getLocalCompanions(realUserId);
      }
    } else {
      return await _getLocalCompanions(realUserId);
    }
  } catch (e) {
    return Left(UnknownFailure('Error obteniendo compañeros: ${e.toString()}'));
  }
}

 @override
Future<Either<Failure, CompanionEntity>> feedCompanionViaApi({
  required String userId,
  required String petId,  // ✅ AHORA RECIBE idUserPet
}) async {
  debugPrint('🍎 [REPO] === ALIMENTANDO VIA API CON idUserPet ===');
  debugPrint('👤 [REPO] User ID: $userId');
  debugPrint('🔑 [REPO] idUserPet (para stats): $petId');
  
  // 🔥 ENVIAR TANTO HAPPINESS COMO HEALTH SEGÚN TU API
  return increasePetStats(
    userId: userId,
    petId: petId,        // ✅ ESTE ES EL idUserPet
    happiness: 5,        // 🔥 AGREGAR 5 DE FELICIDAD
    health: 15,          // 🔥 AGREGAR 15 DE SALUD
  );
}

@override
Future<Either<Failure, CompanionEntity>> loveCompanionViaApi({
  required String userId,
  required String petId,  // ✅ AHORA RECIBE idUserPet
}) async {
  debugPrint('💖 [REPO] === DANDO AMOR VIA API CON idUserPet ===');
  debugPrint('👤 [REPO] User ID: $userId');
  debugPrint('🔑 [REPO] idUserPet (para stats): $petId');
  
  // 🔥 ENVIAR TANTO HAPPINESS COMO HEALTH SEGÚN TU API  
  return increasePetStats(
    userId: userId,
    petId: petId,        // ✅ ESTE ES EL idUserPet
    happiness: 10,       // 🔥 AGREGAR 10 DE FELICIDAD
    health: 5,           // 🔥 AGREGAR 5 DE SALUD
  );
}

@override
Future<Either<Failure, CompanionEntity>> simulateTimePassage({
  required String userId,
  required String petId,  // ✅ AHORA RECIBE idUserPet
}) async {
  debugPrint('⏰ [REPO] === SIMULANDO PASO DEL TIEMPO ===');
  debugPrint('🔑 [REPO] idUserPet (para reducir stats): $petId');
  
  // 🔥 REDUCIR AMBAS ESTADÍSTICAS
  return decreasePetStats(
    userId: userId,
    petId: petId,        // ✅ ESTE ES EL idUserPet
    happiness: 5,        // 🔥 REDUCIR 5 DE FELICIDAD
    health: 8,           // 🔥 REDUCIR 8 DE SALUD
  );
}


  // ==================== 🔧 MÉTODOS HELPER PARA CACHE ====================
  Future<void> _updateLocalCacheAfterStatsChange(String userId, CompanionModel updatedCompanion) async {
    final companions = await localDataSource.getCachedCompanions(userId);

    final updatedCompanions = companions.map((comp) {
      if (comp.id == updatedCompanion.id) {
        return updatedCompanion;
      }
      return comp;
    }).toList();

    await localDataSource.cacheCompanions(userId, updatedCompanions);
    await localDataSource.cacheCompanion(updatedCompanion);

    debugPrint('💾 [REPO] Cache local actualizado después de cambio de stats');
  }

   Future<Either<Failure, CompanionEntity>> _decreaseStatsLocal(
      String userId, String petId, int? happiness, int? health) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionIndex = companions.indexWhere((c) => 
          _extractPetIdFromCompanion(c) == petId || c.id == petId);
      
      if (companionIndex == -1) {
        return Left(ValidationFailure('Mascota no encontrada'));
      }
      
      final companion = companions[companionIndex];
      
      final newHappiness = happiness != null 
          ? (companion.happiness - happiness).clamp(10, 100)
          : companion.happiness;
      final newHunger = health != null 
          ? (companion.hunger - health).clamp(10, 100)
          : companion.hunger;
      
      final updatedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience,
          happiness: newHappiness,
          hunger: newHunger,
          energy: companion.energy,
          isOwned: companion.isOwned,
          isSelected: companion.isSelected,
          purchasedAt: companion.purchasedAt,
          lastFeedTime: companion.lastFeedTime,
          lastLoveTime: companion.lastLoveTime,
          currentMood: _determineMoodFromStats(newHappiness, newHunger),
          purchasePrice: companion.purchasePrice,
          evolutionPrice: companion.evolutionPrice,
          unlockedAnimations: companion.unlockedAnimations,
          createdAt: companion.createdAt,
        ),
      );
      
      companions[companionIndex] = updatedCompanion;
      await localDataSource.cacheCompanions(userId, companions);
      
      return Right(updatedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error en reducción local: ${e.toString()}'));
    }
  }

  Future<Either<Failure, CompanionEntity>> _increaseStatsLocal(
      String userId, String petId, int? happiness, int? health) async {
    try {
      debugPrint('📈 [REPO] Aumento local de stats');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      final companionIndex = companions.indexWhere((c) => 
          _extractPetIdFromCompanion(c) == petId || c.id == petId);
      
      if (companionIndex == -1) {
        return Left(ValidationFailure('Mascota no encontrada'));
      }
      
      final companion = companions[companionIndex];
      
      final newHappiness = happiness != null 
          ? (companion.happiness + happiness).clamp(10, 100)
          : companion.happiness;
      final newHunger = health != null 
          ? (companion.hunger + health).clamp(10, 100)
          : companion.hunger;
      
      final updatedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience + 25, // Experiencia por interacción
          happiness: newHappiness,
          hunger: newHunger,
          energy: companion.energy,
          isOwned: companion.isOwned,
          isSelected: companion.isSelected,
          purchasedAt: companion.purchasedAt,
          lastFeedTime: health != null ? DateTime.now() : companion.lastFeedTime,
          lastLoveTime: happiness != null ? DateTime.now() : companion.lastLoveTime,
          currentMood: CompanionMood.happy,
          purchasePrice: companion.purchasePrice,
          evolutionPrice: companion.evolutionPrice,
          unlockedAnimations: companion.unlockedAnimations,
          createdAt: companion.createdAt,
        ),
      );
      
      companions[companionIndex] = updatedCompanion;
      await localDataSource.cacheCompanions(userId, companions);
      
      return Right(updatedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error en aumento local: ${e.toString()}'));
    }
  }

  // Helper para extraer Pet ID de un companion
  String _extractPetIdFromCompanion(CompanionModel companion) {
    if (companion is CompanionModelWithPetId) {
      return companion.petId;
    }
    // Fallback al ID local
    return companion.id;
  }

  // Helper para determinar mood
  CompanionMood _determineMoodFromStats(int happiness, int hunger) {
    if (happiness >= 80 && hunger >= 80) {
      return CompanionMood.excited;
    } else if (happiness >= 60 && hunger >= 60) {
      return CompanionMood.happy;
    } else if (happiness <= 30 || hunger <= 30) {
      return CompanionMood.sad;
    } else if (hunger <= 40) {
      return CompanionMood.hungry;
    } else {
      return CompanionMood.normal;
    }
  }

  // ==================== TIENDA DE MASCOTAS ====================
  @override
  Future<Either<Failure, List<CompanionEntity>>> getAvailableCompanions() async {
    try {
      debugPrint('🛍️ [REPO] === OBTENIENDO TIENDA DE MASCOTAS CON USER ID ===');

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
          debugPrint('👤 [REPO] Usuario ID REAL para tienda: $realUserId');
          
          final storeCompanions = await remoteDataSource.getStoreCompanions(userId: realUserId);
          debugPrint('🛍️ [REPO] Tienda API: ${storeCompanions.length} mascotas');

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

  // ==================== ESTADÍSTICAS ====================
  @override
  Future<Either<Failure, CompanionStatsEntity>> getCompanionStats(String userId) async {
    try {
      debugPrint('📊 [REPO] === OBTENIENDO ESTADÍSTICAS ===');

      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');

      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🚀 [REPO] Calculando stats desde API...');

        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (hasValidToken) {
            // 🔥 OBTENER PUNTOS REALES DE LA API
            final realUserPoints = await remoteDataSource.getUserPoints(realUserId);
            debugPrint('💰 [REPO] Puntos REALES del usuario: $realUserPoints');

            // 🔥 OBTENER MASCOTAS REALES DEL USUARIO
            final userCompanions = await remoteDataSource.getUserCompanions(realUserId);
            debugPrint('🐾 [REPO] Mascotas REALES del usuario: ${userCompanions.length}');

            // 🔥 OBTENER TODAS LAS MASCOTAS DISPONIBLES
            final allCompanions = await remoteDataSource.getAvailableCompanions();
            debugPrint('🛍️ [REPO] Total mascotas disponibles: ${allCompanions.length}');

            final ownedCount = userCompanions.length;
            final totalCount = allCompanions.length + 1; // +1 por Dexter joven
            final activeCompanionId = userCompanions.isNotEmpty
                ? userCompanions.first.id
                : 'dexter_young';

            // Calcular puntos gastados (estimado basado en precios)
            int spentPoints = 0;
            for (final companion in userCompanions) {
              spentPoints += companion.purchasePrice;
            }

            final stats = CompanionStatsModel(
              userId: realUserId,
              totalCompanions: totalCount,
              ownedCompanions: ownedCount,
              totalPoints: realUserPoints + spentPoints, // Total real + gastados
              spentPoints: spentPoints,
              activeCompanionId: activeCompanionId,
              totalFeedCount: 0, // No disponible en API actual
              totalLoveCount: 0, // No disponible en API actual
              totalEvolutions: 0, // No disponible en API actual
              lastActivity: DateTime.now(),
            );

            await localDataSource.cacheStats(stats);

            debugPrint('📊 [REPO] Stats API calculados y guardados');
            debugPrint('💰 [REPO] Puntos disponibles: ${stats.availablePoints}');
            debugPrint('🐾 [REPO] Mascotas: ${stats.ownedCompanions}/${stats.totalCompanions}');

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

  // ==================== 🔥 ADOPCIÓN MEJORADA ====================
   @override
  Future<Either<Failure, CompanionEntity>> adoptCompanion({
    required String userId,
    required String petId,
    String? nickname,
  }) async {
    try {
      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();

      if (enableApiMode && await networkInfo.isConnected) {
        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          final adoptedCompanion = await remoteDataSource.adoptCompanion(
            userId: realUserId,
            petId: petId,
            nickname: nickname,
          );

          await localDataSource.cacheCompanion(adoptedCompanion);
          await _updateLocalCacheAfterPurchase(realUserId, adoptedCompanion);

          return Right(adoptedCompanion);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      } else {
        return await _adoptCompanionLocal(realUserId, petId, nickname);
      }
    } catch (e) {
      return Left(UnknownFailure('Error en adopción: ${e.toString()}'));
    }
  }

  // ==================== 🔥 EVOLUCIÓN VIA API REAL ====================
  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanionViaApi({
    required String userId,
    required String petId,
  }) async {
    try {
      debugPrint('🦋 [REPO] === EVOLUCIONANDO VIA API REAL ===');
      debugPrint('👤 [REPO] User ID: $userId');
      debugPrint('🆔 [REPO] Pet ID: $petId');

      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');

      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Evolucionando via API real...');

        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          debugPrint('❌ [REPO] Sin token válido para evolución');
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          // 🔥 LLAMAR AL ENDPOINT REAL DE EVOLUCIÓN
          final evolvedCompanion = await remoteDataSource.evolvePetViaApi(
            userId: realUserId,
            petId: petId,
          );

          debugPrint('✅ [REPO] Evolución exitosa desde API: ${evolvedCompanion.displayName}');

          // 💾 GUARDAR EN CACHE LOCAL
          await localDataSource.cacheCompanion(evolvedCompanion);
          await _updateLocalCacheAfterEvolution(realUserId, evolvedCompanion);

          return Right(evolvedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error en API de evolución: $e');
          
          // 🔥 LOS ERRORES YA VIENEN FORMATEADOS DEL DATASOURCE
          return Left(ServerFailure(e.toString()));
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión, usando evolución local');
        return await _evolveCompanionLocal(realUserId, petId);
      }
    } catch (e) {
      debugPrint('💥 [REPO] Error general en evolución: $e');
      return Left(UnknownFailure('Error en evolución: ${e.toString()}'));
    }
  }

  // ==================== 🔥 DESTACAR MASCOTA VIA API REAL ====================
  @override
  Future<Either<Failure, CompanionEntity>> featureCompanion({
    required String userId,
    required String petId,
  }) async {
    try {
      debugPrint('⭐ [REPO] === DESTACANDO MASCOTA VIA API ===');
      debugPrint('👤 [REPO] User ID: $userId');
      debugPrint('🆔 [REPO] Pet ID: $petId');

      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');

      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Destacando via API real...');

        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          debugPrint('❌ [REPO] Sin token válido para destacar');
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          // 🔥 LLAMAR AL ENDPOINT REAL DE FEATURE
          final featuredCompanion = await remoteDataSource.featurePetViaApi(
            userId: realUserId,
            petId: petId,
          );

          debugPrint('✅ [REPO] Destacado exitoso desde API: ${featuredCompanion.displayName}');

          // 💾 GUARDAR EN CACHE LOCAL
          await localDataSource.cacheCompanion(featuredCompanion);
          await _updateLocalCacheAfterFeature(realUserId, featuredCompanion);

          return Right(featuredCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error en API de destacar: $e');
          
          // 🔥 LOS ERRORES YA VIENEN FORMATEADOS DEL DATASOURCE
          return Left(ServerFailure(e.toString()));
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión, usando destacar local');
        return await _setActiveCompanionLocal(realUserId, petId);
      }
    } catch (e) {
      debugPrint('💥 [REPO] Error general destacando: $e');
      return Left(UnknownFailure('Error destacando: ${e.toString()}'));
    }
  }

  // ==================== 🔥 ACCIONES LOCALES ARREGLADAS ====================

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL INCLUSO EN MÉTODOS LOCALES
      final realUserId = await _getRealUserId();
      debugPrint('🍎 [REPO] Alimentación con USER ID REAL: $realUserId');
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
      debugPrint('💖 [REPO] Amor con USER ID REAL: $realUserId');
      return await _loveCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en amor: $e');
      return Left(UnknownFailure('Error en amor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CompanionEntity>> evolveCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL INCLUSO EN MÉTODOS LOCALES
      final realUserId = await _getRealUserId();
      debugPrint('⭐ [REPO] Evolución local con USER ID REAL: $realUserId');
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
      debugPrint('⭐ [REPO] Activación local con USER ID REAL: $realUserId');
      return await _setActiveCompanionLocal(realUserId, companionId);
    } catch (e) {
      debugPrint('❌ [REPO] Error en activación: $e');
      return Left(UnknownFailure('Error en activación: ${e.toString()}'));
    }
  }

  // ==================== MÉTODO LEGACY (mantener compatibilidad) ====================
  @override
  Future<Either<Failure, CompanionEntity>> purchaseCompanion(String userId, String companionId) async {
    // Redirigir al método de adopción actualizado
    return adoptCompanion(userId: userId, petId: companionId);
  }

  // ==================== 🔧 MÉTODOS HELPER PRIVADOS MEJORADOS ====================

  Future<Either<Failure, List<CompanionEntity>>> _getLocalCompanions(String userId) async {
    try {
      final companions = await localDataSource.getCachedCompanions(userId);
      debugPrint('📱 [REPO] Local: ${companions.length} compañeros para usuario $userId');

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
      // 🔥 DEXTER BABY CON PRECIO (NO GRATIS)
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un pequeño chihuahua mexicano',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: false,
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: 100, // 🔥 CON PRECIO
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),

      // Elly Baby (precio actualizado)
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
        purchasePrice: 200,
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'eating'],
        createdAt: now,
      ),

      // Paxolotl Baby (precio actualizado)
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
        purchasePrice: 600,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'swimming'],
        createdAt: now,
      ),

      // Yami Baby (precio actualizado)
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
        purchasePrice: 2500,
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
          isSelected: comp.id == featuredCompanion.id, // 🔥 SOLO UNA ACTIVA
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

  // ==================== MÉTODOS LOCALES DE FALLBACK MEJORADOS ====================

  Future<Either<Failure, CompanionEntity>> _adoptCompanionLocal(
      String userId, String petId, String? nickname) async {
    try {
      debugPrint('💰 [REPO] Adopción local simulada');
      debugPrint('👤 [REPO] Usuario: $userId');
      debugPrint('🆔 [REPO] Pet ID: $petId');
      debugPrint('🏷️ [REPO] Nickname: ${nickname ?? "Sin nickname"}');

      // 🔧 MAPEAR PET ID A COMPANION TYPE PARA FALLBACK
      final companionType = _mapPetIdToCompanionType(petId);
      final companionStage = _mapPetIdToCompanionStage(petId);

      // Crear companion adoptado localmente
      final adoptedCompanion = CompanionModel(
        id: '${companionType.name}_${companionStage.name}',
        type: companionType,
        stage: companionStage,
        name: nickname ?? _getDisplayName(companionType),
        description: 'Mascota adoptada localmente',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true,
        isSelected: false,
        purchasedAt: DateTime.now(),
        currentMood: CompanionMood.happy,
        purchasePrice: _getDefaultPrice(companionType, companionStage),
        evolutionPrice: _getEvolutionPrice(companionStage),
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: DateTime.now(),
      );

      await localDataSource.cacheCompanion(adoptedCompanion);
      await _updateLocalCacheAfterPurchase(userId, adoptedCompanion);

      debugPrint('✅ [REPO] Adopción local exitosa: ${adoptedCompanion.displayName}');
      return Right(adoptedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error en adopción local: $e');
      return Left(UnknownFailure('Error en adopción local: ${e.toString()}'));
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
          evolutionPrice: nextStage == CompanionStage.adult
              ? 0
              : companion.evolutionPrice + 50,
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
      final companionIndex = companions.indexWhere((c) => c.id == companionId);
      
      if (companionIndex == -1) {
        return Left(ValidationFailure('Mascota no encontrada'));
      }
      
      final companion = companions[companionIndex];
      
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

      companions[companionIndex] = fedCompanion;
      await localDataSource.cacheCompanions(userId, companions);
      return Right(fedCompanion);
    } catch (e) {
      return Left(UnknownFailure('Error alimentando: ${e.toString()}'));
    }
  }
  Future<Either<Failure, CompanionEntity>> _loveCompanionLocal(String userId, String companionId) async {
    try {
      debugPrint('💖 [REPO] Dando amor localmente: usuario $userId, mascota: $companionId');
      
      final companions = await localDataSource.getCachedCompanions(userId);
      
      // 🔧 BUSCAR COMPANION CORRECTAMENTE
      final companionIndex = companions.indexWhere((c) => c.id == companionId);
      if (companionIndex == -1) {
        debugPrint('❌ [REPO] Companion no encontrado: $companionId');
        return Left(ValidationFailure('Este compañero no fue encontrado'));
      }
      
      final companion = companions[companionIndex];

      if (!companion.isOwned) {
        return Left(ValidationFailure('Este compañero no te pertenece'));
      }

      // 🔧 CREAR COMPANION CON AMOR CON LÓGICA MEJORADA
      final lovedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience + 20, // +20 EXP por dar amor
          happiness: 100, // Llenar felicidad
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

      // 🔧 ACTUALIZAR EN LA LISTA Y CACHE
      companions[companionIndex] = lovedCompanion;
      await localDataSource.cacheCompanions(userId, companions);
      await localDataSource.cacheCompanion(lovedCompanion);

      debugPrint('✅ [REPO] Amor dado exitosamente: ${lovedCompanion.displayName}');
      return Right(lovedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error dando amor: $e');
      return Left(UnknownFailure('Error dando amor: ${e.toString()}'));
    }
  }

 CompanionType _mapPetIdToCompanionType(String petId) {
    final petIdLower = petId.toLowerCase();
    if (petIdLower.contains('dexter') || petIdLower.contains('dog')) {
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || petIdLower.contains('panda')) {
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') || petIdLower.contains('axolotl')) {
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || petIdLower.contains('jaguar')) {
      return CompanionType.yami;
    }
    return CompanionType.dexter;
  }

  CompanionStage _mapPetIdToCompanionStage(String petId) {
    final petIdLower = petId.toLowerCase();
    if (petIdLower.contains('baby') || petIdLower.contains('peque')) {
      return CompanionStage.baby;
    } else if (petIdLower.contains('young') || petIdLower.contains('joven')) {
      return CompanionStage.young;
    }
    return CompanionStage.baby;
  }


  String _getDisplayName(CompanionType type) {
    switch (type) {
      case CompanionType.dexter:
        return 'Dexter';
      case CompanionType.elly:
        return 'Elly';
      case CompanionType.paxolotl:
        return 'Paxolotl';
      case CompanionType.yami:
        return 'Yami';
    }
  }

   int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    int basePrice = 100;

    switch (type) {
      case CompanionType.dexter:
        basePrice = 100; // 🔥 YA NO ES GRATIS
        break;
      case CompanionType.elly:
        basePrice = 200;
        break;
      case CompanionType.paxolotl:
        basePrice = 600;
        break;
      case CompanionType.yami:
        basePrice = 2500;
        break;
    }

    switch (stage) {
      case CompanionStage.baby:
        return basePrice;
      case CompanionStage.young:
        return (basePrice * 1.5).round();
      case CompanionStage.adult:
        return (basePrice * 2.0).round();
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 50;
      case CompanionStage.young:
        return 100;
      case CompanionStage.adult:
        return 0;
    }
  }
}