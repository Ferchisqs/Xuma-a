// lib/features/companion/data/repositories/companion_repository_impl.dart
// 🔥 CONECTADO A NUEVOS ENDPOINTS + MÉTODOS ARREGLADOS

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
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

      // 🔥 USAR USER ID REAL DEL TOKEN
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');

      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🚀 [REPO] Conectando con API real...');

        try {
          final hasValidToken = await tokenManager.hasValidAccessToken();
          if (!hasValidToken) {
            debugPrint('⚠️ [REPO] Sin token válido, usando fallback local');
            return await _getLocalCompanions(realUserId);
          }

          final remoteCompanions = await remoteDataSource.getUserCompanions(realUserId);
          debugPrint('✅ [REPO] API devolvió ${remoteCompanions.length} mascotas del usuario');

          // 🔍 VERIFICAR MASCOTAS DE API
          debugPrint('🔍 [REPO] === VERIFICANDO MASCOTAS DE API ===');
          for (int i = 0; i < remoteCompanions.length; i++) {
            final pet = remoteCompanions[i];
            debugPrint('🐾 [REPO] Mascota $i: ${pet.displayName}');
            debugPrint('   - ID: ${pet.id}');
            debugPrint('   - isOwned: ${pet.isOwned} 👈');
            debugPrint('   - isSelected: ${pet.isSelected}');
          }

          List<CompanionModel> finalCompanions = [];
          for (int i = 0; i < remoteCompanions.length; i++) {
            final petWithOwnership = remoteCompanions[i].copyWith(
              isOwned: true,     // 🔥 FORZAR COMO POSEÍDA
              isSelected: i == 0, // Primera activa
            );
            finalCompanions.add(petWithOwnership);
            debugPrint('✅ [REPO] Corregida: ${petWithOwnership.displayName} - owned: ${petWithOwnership.isOwned}');
          }

          debugPrint('🔍 [REPO] === FINAL: ${finalCompanions.length} mascotas poseídas ===');

          // 🔧 ASEGURAR QUE AL MENOS UNA ESTÉ ACTIVA
          if (finalCompanions.isNotEmpty &&
              !finalCompanions.any((c) => c.isSelected)) {
            finalCompanions[0] = finalCompanions[0].copyWith(isSelected: true);
            debugPrint('⭐ [REPO] Activando primera mascota: ${finalCompanions[0].displayName}');
          }

          // Guardar en cache
          await localDataSource.cacheCompanions(realUserId, finalCompanions);
          debugPrint('💾 [REPO] Mascotas guardadas en cache');

          return Right(finalCompanions);
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
      debugPrint('🐾 [REPO] === INICIANDO ADOPCIÓN VIA API REAL ===');
      debugPrint('👤 [REPO] User ID: $userId');
      debugPrint('🆔 [REPO] Pet ID: $petId');
      debugPrint('🏷️ [REPO] Nickname: ${nickname ?? "Sin nickname"}');

      // 🔥 USAR USER ID REAL
      final realUserId = await _getRealUserId();
      debugPrint('👤 [REPO] Usuario ID REAL: $realUserId');
      debugPrint('🌐 [REPO] API Mode: $enableApiMode');

      // 🔥 VERIFICAR CONEXIÓN Y USAR API REAL
      if (enableApiMode && await networkInfo.isConnected) {
        debugPrint('🌐 [REPO] Conectado a internet, usando API real');

        final hasValidToken = await tokenManager.hasValidAccessToken();
        if (!hasValidToken) {
          debugPrint('❌ [REPO] Sin token válido para adopción');
          return Left(AuthFailure('Token de autenticación requerido'));
        }

        try {
          final adoptedCompanion = await remoteDataSource.adoptCompanion(
            userId: realUserId,
            petId: petId,
            nickname: nickname,
          );

          debugPrint('✅ [REPO] Adopción exitosa desde API: ${adoptedCompanion.displayName}');

          // 💾 GUARDAR EN CACHE LOCAL
          await localDataSource.cacheCompanion(adoptedCompanion);

          // 🔧 ACTUALIZAR LISTA DE COMPANIONS DEL USUARIO
          await _updateLocalCacheAfterPurchase(realUserId, adoptedCompanion);

          return Right(adoptedCompanion);
        } catch (e) {
          debugPrint('❌ [REPO] Error en API de adopción: $e');

          // 🔧 MANEJO DE ERRORES ESPECÍFICOS DE TU API
          if (e.toString().contains('ya adoptada') ||
              e.toString().contains('already adopted')) {
            return Left(ValidationFailure('Ya tienes esta mascota'));
          } else if (e.toString().contains('insufficient') ||
              e.toString().contains('insuficientes')) {
            return Left(ValidationFailure('No tienes suficientes puntos'));
          } else if (e.toString().contains('not found')) {
            return Left(ValidationFailure('Mascota no encontrada'));
          } else if (e.toString().contains('authentication') ||
              e.toString().contains('unauthorized')) {
            return Left(AuthFailure('Error de autenticación'));
          } else {
            return Left(ServerFailure('Error adoptando mascota: ${e.toString()}'));
          }
        }
      } else {
        debugPrint('📱 [REPO] Sin conexión, usando adopción local');
        return await _adoptCompanionLocal(realUserId, petId, nickname);
      }
    } catch (e) {
      debugPrint('💥 [REPO] Error general en adopción: $e');
      return Left(UnknownFailure('Error en adopción: ${e.toString()}'));
    }
  }

  // ==================== 🆕 EVOLUCIÓN VIA API REAL ====================
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

          if (e.toString().contains('insufficient') ||
              e.toString().contains('insuficientes')) {
            return Left(ValidationFailure('No tienes suficientes puntos para evolucionar'));
          } else if (e.toString().contains('max level') ||
              e.toString().contains('maximum')) {
            return Left(ValidationFailure('Ya está en su máxima evolución'));
          } else if (e.toString().contains('not found')) {
            return Left(ValidationFailure('Mascota no encontrada'));
          } else if (e.toString().contains('experience') ||
              e.toString().contains('experiencia')) {
            return Left(ValidationFailure('Tu mascota necesita más experiencia'));
          } else {
            return Left(ServerFailure('Error evolucionando mascota: ${e.toString()}'));
          }
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

  // ==================== 🆕 DESTACAR MASCOTA VIA API REAL ====================
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
          
          if (e.toString().contains('not found')) {
            return Left(ValidationFailure('Mascota no encontrada'));
          } else if (e.toString().contains('already featured')) {
            return Left(ValidationFailure('Esta mascota ya está destacada'));
          } else {
            return Left(ServerFailure('Error destacando mascota: ${e.toString()}'));
          }
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

  // ==================== MÉTODOS LOCALES (MEJORADOS) ====================

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

  @override
  Future<Either<Failure, CompanionEntity>> feedCompanion(String userId, String companionId) async {
    try {
      // 🔥 USAR USER ID REAL
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
      debugPrint('🍎 [REPO] Alimentando localmente: usuario $userId, mascota: $companionId');
      
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

      // 🔧 CREAR COMPANION ALIMENTADO CON LÓGICA MEJORADA
      final fedCompanion = CompanionModel.fromEntity(
        CompanionEntity(
          id: companion.id,
          type: companion.type,
          stage: companion.stage,
          name: companion.name,
          description: companion.description,
          level: companion.level,
          experience: companion.experience + 25, // +25 EXP por alimentar
          happiness: (companion.happiness + 15).clamp(0, 100),
          hunger: 100, // Llenar hambre
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

      // 🔧 ACTUALIZAR EN LA LISTA Y CACHE
      companions[companionIndex] = fedCompanion;
      await localDataSource.cacheCompanions(userId, companions);
      await localDataSource.cacheCompanion(fedCompanion);

      debugPrint('✅ [REPO] Companion alimentado exitosamente: ${fedCompanion.displayName}');
      return Right(fedCompanion);
    } catch (e) {
      debugPrint('❌ [REPO] Error alimentando: $e');
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

  // 🔧 MÉTODOS HELPER PARA MAPEO LOCAL
  CompanionType _mapPetIdToCompanionType(String petId) {
    final petIdLower = petId.toLowerCase();

    if (petIdLower.contains('dexter') ||
        petIdLower.contains('dog') ||
        petIdLower.contains('chihuahua')) {
      return CompanionType.dexter;
    } else if (petIdLower.contains('elly') || petIdLower.contains('panda')) {
      return CompanionType.elly;
    } else if (petIdLower.contains('paxolotl') ||
        petIdLower.contains('axolotl') ||
        petIdLower.contains('ajolote')) {
      return CompanionType.paxolotl;
    } else if (petIdLower.contains('yami') || petIdLower.contains('jaguar')) {
      return CompanionType.yami;
    }

    debugPrint('⚠️ [REPO] Pet ID no reconocido: $petId, usando Dexter por defecto');
    return CompanionType.dexter;
  }

  CompanionStage _mapPetIdToCompanionStage(String petId) {
    final petIdLower = petId.toLowerCase();

    if (petIdLower.contains('baby') || petIdLower.contains('peque')) {
      return CompanionStage.baby;
    } else if (petIdLower.contains('young') || petIdLower.contains('joven')) {
      return CompanionStage.young;
    } else if (petIdLower.contains('adult') || petIdLower.contains('adulto')) {
      return CompanionStage.adult;
    }

    return CompanionStage.baby; // Por defecto
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
        basePrice = 0;
        break; // Gratis
      case CompanionType.elly:
        basePrice = 200;
        break;
      case CompanionType.paxolotl:
        basePrice = 300;
        break;
      case CompanionType.yami:
        basePrice = 500;
        break;
    }

    switch (stage) {
      case CompanionStage.baby:
        return basePrice;
      case CompanionStage.young:
        return basePrice + 50;
      case CompanionStage.adult:
        return basePrice + 100;
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