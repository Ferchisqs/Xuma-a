// lib/features/companion/data/datasources/companion_local_datasource.dart - ACTUALIZADO PARA API
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';
import '../../domain/entities/companion_entity.dart';

abstract class CompanionLocalDataSource {
  Future<List<CompanionModel>> getCachedCompanions(String userId);
  Future<void> cacheCompanions(String userId, List<CompanionModel> companions);
  Future<CompanionModel?> getCachedCompanion(String companionId);
  Future<void> cacheCompanion(CompanionModel companion);
  Future<CompanionStatsModel?> getCachedStats(String userId);
  Future<void> cacheStats(CompanionStatsModel stats);
  Future<void> clearCache();
}

@Injectable(as: CompanionLocalDataSource)
class CompanionLocalDataSourceImpl implements CompanionLocalDataSource {
  final CacheService cacheService;

  static const String _companionsPrefix = 'companions_';
  static const String _companionPrefix = 'companion_';
  static const String _statsPrefix = 'companion_stats_';

  // 🔧 CONFIGURACIÓN DE MODO
  static const bool useApiMode = true; // 🆕 CAMBIAR A true PARA USAR API
  static const bool useMockData = false; // 🆕 false PARA DATOS REALES

  CompanionLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<CompanionModel>> getCachedCompanions(String userId) async {
    try {
      debugPrint('🐾 [LOCAL_DS] Obteniendo compañeros para usuario: $userId');
      debugPrint('🌐 [LOCAL_DS] Modo API: $useApiMode');
      debugPrint('🎮 [LOCAL_DS] Usar Mock: $useMockData');
      
      if (!useApiMode || useMockData) {
        // 🔧 MODO DESARROLLO: TODOS DESBLOQUEADOS
        debugPrint('🎮 [LOCAL_DS] Devolviendo mock con todos desbloqueados');
        final mockCompanions = _getMockCompanionsAllUnlocked(userId);
        debugPrint('✅ [LOCAL_DS] Devolviendo ${mockCompanions.length} compañeros mock');
        return mockCompanions;
      }
      
      // 🆕 MODO API: INTENTAR OBTENER DESDE CACHE
      debugPrint('💾 [LOCAL_DS] Intentando obtener desde cache...');
      final companionsJson = await cacheService.getList<Map<String, dynamic>>('$_companionsPrefix$userId');
      
      if (companionsJson != null && companionsJson.isNotEmpty) {
        debugPrint('✅ [LOCAL_DS] Cache encontrado: ${companionsJson.length} mascotas');
        
        final companions = <CompanionModel>[];
        for (final json in companionsJson) {
          try {
            final companion = CompanionModel.fromJson(json);
            companions.add(companion);
          } catch (e) {
            debugPrint('❌ [LOCAL_DS] Error parseando mascota desde cache: $e');
          }
        }
        
        debugPrint('📊 [LOCAL_DS] ${companions.length} mascotas parseadas exitosamente');
        return companions;
      } else {
        debugPrint('⚠️ [LOCAL_DS] No hay cache, devolviendo lista vacía');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error: $e');
      if (useMockData) {
        return _getMockCompanionsAllUnlocked(userId);
      } else {
        return [];
      }
    }
  }

  @override
  Future<void> cacheCompanions(String userId, List<CompanionModel> companions) async {
    try {
      debugPrint('💾 [LOCAL_DS] Guardando ${companions.length} compañeros en caché');
      
      final companionsJson = companions.map((companion) => companion.toJson()).toList();
      
      await cacheService.setList(
        '$_companionsPrefix$userId', 
        companionsJson,
        duration: const Duration(hours: 24), // Cache por 24 horas
      );
      
      debugPrint('✅ [LOCAL_DS] ${companions.length} compañeros guardados en caché');
      
      // 🆕 GUARDAR ESTADÍSTICAS TAMBIÉN
      if (companions.isNotEmpty) {
        final stats = _calculateStatsFromCompanions(userId, companions);
        await cacheStats(stats);
        debugPrint('📊 [LOCAL_DS] Estadísticas calculadas y guardadas');
      }
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error guardando compañeros: $e');
      throw CacheException('Error caching companions: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel?> getCachedCompanion(String companionId) async {
    try {
      debugPrint('🔍 [LOCAL_DS] Buscando compañero: $companionId');
      
      final companionJson = await cacheService.get<Map<String, dynamic>>('$_companionPrefix$companionId');
      if (companionJson == null) {
        debugPrint('⚠️ [LOCAL_DS] Compañero no encontrado en cache individual');
        return null;
      }
      
      final companion = CompanionModel.fromJson(companionJson);
      debugPrint('✅ [LOCAL_DS] Compañero encontrado: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error obteniendo compañero: $e');
      return null;
    }
  }

  @override
  Future<void> cacheCompanion(CompanionModel companion) async {
    try {
      debugPrint('💾 [LOCAL_DS] Guardando compañero individual: ${companion.displayName}');
      
      await cacheService.set(
        '$_companionPrefix${companion.id}', 
        companion.toJson(),
        duration: const Duration(hours: 24),
      );
      
      debugPrint('✅ [LOCAL_DS] Compañero individual guardado');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error guardando compañero individual: $e');
      throw CacheException('Error caching companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionStatsModel?> getCachedStats(String userId) async {
    try {
      debugPrint('📊 [LOCAL_DS] Obteniendo stats para usuario: $userId');
      debugPrint('🌐 [LOCAL_DS] Modo API: $useApiMode');
      debugPrint('🎮 [LOCAL_DS] Usar Mock: $useMockData');
      
      if (!useApiMode || useMockData) {
        // 🔧 MODO DESARROLLO: STATS GENEROSOS
        debugPrint('🎮 [LOCAL_DS] Generando stats generosos para desarrollo');
        final stats = _getMockStatsAllUnlocked(userId);
        debugPrint('📊 [LOCAL_DS] Stats generados:');
        debugPrint('💰 Total: ${stats.totalPoints}, Gastados: ${stats.spentPoints}, Disponibles: ${stats.availablePoints}');
        debugPrint('🐾 Poseídos: ${stats.ownedCompanions}/${stats.totalCompanions}');
        return stats;
      }
      
      // 🆕 MODO API: INTENTAR OBTENER DESDE CACHE
      debugPrint('💾 [LOCAL_DS] Intentando obtener stats desde cache...');
      final statsJson = await cacheService.get<Map<String, dynamic>>('$_statsPrefix$userId');
      
      if (statsJson != null) {
        debugPrint('✅ [LOCAL_DS] Stats encontrados en cache');
        final stats = CompanionStatsModel.fromJson(statsJson);
        debugPrint('📊 [LOCAL_DS] Stats desde cache:');
        debugPrint('💰 Total: ${stats.totalPoints}, Disponibles: ${stats.availablePoints}');
        debugPrint('🐾 Poseídos: ${stats.ownedCompanions}/${stats.totalCompanions}');
        return stats;
      } else {
        debugPrint('⚠️ [LOCAL_DS] No hay stats en cache');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error obteniendo stats: $e');
      if (useMockData) {
        return _getMockStatsAllUnlocked(userId);
      } else {
        return null;
      }
    }
  }

  @override
  Future<void> cacheStats(CompanionStatsModel stats) async {
    try {
      debugPrint('💾 [LOCAL_DS] Guardando stats:');
      debugPrint('💰 Total: ${stats.totalPoints}, Gastados: ${stats.spentPoints}, Disponibles: ${stats.availablePoints}');
      debugPrint('🐾 Poseídos: ${stats.ownedCompanions}');
      
      await cacheService.set(
        '$_statsPrefix${stats.userId}', 
        stats.toJson(),
        duration: const Duration(hours: 12), // Cache por 12 horas
      );
      
      debugPrint('✅ [LOCAL_DS] Stats guardados correctamente');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error guardando stats: $e');
      throw CacheException('Error caching companion stats: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      debugPrint('🗑️ [LOCAL_DS] Limpiando todo el cache de compañeros...');
      
      // Limpiar todas las claves relacionadas con compañeros
      final allKeys = await cacheService.getKeysWithPrefix(_companionsPrefix);
      final companionKeys = await cacheService.getKeysWithPrefix(_companionPrefix);
      final statsKeys = await cacheService.getKeysWithPrefix(_statsPrefix);
      
      for (final key in [...allKeys, ...companionKeys, ...statsKeys]) {
        await cacheService.remove(key);
      }
      
      debugPrint('✅ [LOCAL_DS] Cache limpiado completamente');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error limpiando cache: $e');
    }
  }

  Future<void> clearStatsCache(String userId) async {
    try {
      await cacheService.remove('$_statsPrefix$userId');
      debugPrint('🗑️ [LOCAL_DS] Cache de stats limpiado para usuario: $userId');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error limpiando cache de stats: $e');
    }
  }

  // 🆕 MÉTODO PARA CALCULAR STATS DESDE LISTA DE COMPAÑEROS
  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : '';
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: ownedCount,
      totalPoints: 1000, // TODO: Obtener desde API de puntos
      spentPoints: ownedCount * 50, // Estimado basado en compras
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0, // TODO: Implementar contador
      totalLoveCount: 0, // TODO: Implementar contador
      totalEvolutions: 0, // TODO: Implementar contador
      lastActivity: DateTime.now(),
    );
  }

  // 🔧 MÉTODO ACTUALIZADO: TODOS LOS COMPAÑEROS DESBLOQUEADOS (SOLO PARA DESARROLLO)
  List<CompanionModel> _getMockCompanionsAllUnlocked(String userId) {
    final now = DateTime.now();
    debugPrint('🎮 [LOCAL_DS] Generando mock con TODOS los compañeros DESBLOQUEADOS');
    
    return [
      // ✨ DEXTER - Chihuahua (TODAS LAS ETAPAS DESBLOQUEADAS)
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un adorable chihuahua bebé lleno de energía',
        level: 5,
        experience: 80,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: true, // Compañero activo inicial
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_young',
        type: CompanionType.dexter,
        stage: CompanionStage.young,
        name: 'Dexter',
        description: 'Dexter ha crecido y es más juguetón',
        level: 8,
        experience: 120,
        happiness: 100,
        hunger: 90,
        energy: 85,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 0,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_adult',
        type: CompanionType.dexter,
        stage: CompanionStage.adult,
        name: 'Dexter',
        description: 'Dexter adulto, el compañero perfecto',
        level: 12,
        experience: 200,
        happiness: 100,
        hunger: 95,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 0,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving', 'sleeping'],
        createdAt: now,
      ),

      // ✨ ELLY - Panda (TODAS LAS ETAPAS DESBLOQUEADAS)
      CompanionModel(
        id: 'elly_baby',
        type: CompanionType.elly,
        stage: CompanionStage.baby,
        name: 'Elly',
        description: 'Una tierna panda bebé que ama el bambú',
        level: 3,
        experience: 45,
        happiness: 95,
        hunger: 80,
        energy: 90,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 50,
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy', 'eating'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'elly_young',
        type: CompanionType.elly,
        stage: CompanionStage.young,
        name: 'Elly',
        description: 'Elly joven, más grande y cariñosa',
        level: 7,
        experience: 150,
        happiness: 100,
        hunger: 100,
        energy: 95,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 100,
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'elly_adult',
        type: CompanionType.elly,
        stage: CompanionStage.adult,
        name: 'Elly',
        description: 'Elly adulta, sabia y protectora',
        level: 15,
        experience: 300,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 150,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'sleeping', 'eating', 'loving', 'excited'],
        createdAt: now,
      ),

      // ✨ PAXOLOTL - Ajolote (TODAS LAS ETAPAS DESBLOQUEADAS)
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un pequeño ajolote lleno de curiosidad',
        level: 4,
        experience: 60,
        happiness: 90,
        hunger: 85,
        energy: 80,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 100,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink', 'happy', 'eating'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_young',
        type: CompanionType.paxolotl,
        stage: CompanionStage.young,
        name: 'Paxolotl',
        description: 'Paxolotl joven, explorador nato',
        level: 9,
        experience: 180,
        happiness: 100,
        hunger: 90,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 150,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_adult',
        type: CompanionType.paxolotl,
        stage: CompanionStage.adult,
        name: 'Paxolotl',
        description: 'Paxolotl adulto, místico y poderoso',
        level: 18,
        experience: 400,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 200,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving', 'sleeping'],
        createdAt: now,
      ),

      // ✨ YAMI - Jaguar (TODAS LAS ETAPAS DESBLOQUEADAS)
      CompanionModel(
        id: 'yami_baby',
        type: CompanionType.yami,
        stage: CompanionStage.baby,
        name: 'Yami',
        description: 'Un jaguar bebé feroz pero tierno',
        level: 6,
        experience: 90,
        happiness: 85,
        hunger: 75,
        energy: 95,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 200,
        evolutionPrice: 200,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_young',
        type: CompanionType.yami,
        stage: CompanionStage.young,
        name: 'Yami',
        description: 'Yami joven, elegante y ágil',
        level: 11,
        experience: 220,
        happiness: 100,
        hunger: 85,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 300,
        evolutionPrice: 300,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'eating', 'loving'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_adult',
        type: CompanionType.yami,
        stage: CompanionStage.adult,
        name: 'Yami',
        description: 'Yami adulta, majestuosa protectora de la naturaleza',
        level: 20,
        experience: 500,
        happiness: 100,
        hunger: 100,
        energy: 100,
        isOwned: true, // 🔓 DESBLOQUEADO
        isSelected: false,
        purchasedAt: now,
        currentMood: CompanionMood.excited,
        purchasePrice: 400,
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'loving', 'sleeping', 'eating'],
        createdAt: now,
      ),
    ];
  }

  // 🔧 MÉTODO ACTUALIZADO: STATS GENEROSOS PARA DESARROLLO
  CompanionStatsModel _getMockStatsAllUnlocked(String userId) {
    debugPrint('💰 [LOCAL_DS] Generando stats generosos para desarrollo');
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: 12, // 🔓 TODAS DESBLOQUEADAS!
      totalPoints: 999999, // 🚀 ¡CASI UN MILLÓN DE PUNTOS!
      spentPoints: 0, // No hemos gastado nada porque ya tenemos todo
      activeCompanionId: 'dexter_baby',
      totalFeedCount: 100,
      totalLoveCount: 75,
      totalEvolutions: 12,
      lastActivity: DateTime.now(),
    );
  }

  // 🆕 MÉTODO PARA SINCRONIZAR CON API
  Future<void> syncWithApiData(String userId, List<CompanionModel> apiCompanions) async {
    try {
      debugPrint('🔄 [LOCAL_DS] Sincronizando con datos de API...');
      
      // Si no hay datos de API, mantener cache actual
      if (apiCompanions.isEmpty) {
        debugPrint('⚠️ [LOCAL_DS] No hay datos de API para sincronizar');
        return;
      }
      
      // Limpiar cache existente
      await clearCache();
      
      // Guardar nuevos datos de API
      await cacheCompanions(userId, apiCompanions);
      
      debugPrint('✅ [LOCAL_DS] Sincronización completada: ${apiCompanions.length} mascotas');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error sincronizando con API: $e');
    }
  }

  // 🆕 MÉTODO PARA VERIFICAR SI NECESITA ACTUALIZACIÓN
  Future<bool> needsRefresh(String userId) async {
    try {
      final cacheInfo = await cacheService.getCacheInfo('$_companionsPrefix$userId');
      
      if (!cacheInfo.containsKey('exists') || cacheInfo['exists'] != true) {
        debugPrint('📅 [LOCAL_DS] No hay cache, necesita refresh');
        return true;
      }
      
      final isExpired = cacheInfo['isExpired'] ?? true;
      debugPrint('📅 [LOCAL_DS] Cache expirado: $isExpired');
      
      return isExpired;
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error verificando refresh: $e');
      return true; // En caso de error, refrescar
    }
  }
}