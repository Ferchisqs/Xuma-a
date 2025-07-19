// lib/features/companion/data/datasources/companion_local_datasource.dart - ARREGLADO
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
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

  // 🔧 SIEMPRE USAR MODO LOCAL HASTA QUE LA API FUNCIONE
  static const bool useApiMode = false; // 🔧 false = SOLO LOCAL
  static const bool useMockData = true;  // 🔧 true = DATOS MOCK

  CompanionLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<CompanionModel>> getCachedCompanions(String userId) async {
    try {
      debugPrint('🐾 [LOCAL_DS] === OBTENIENDO COMPAÑEROS ===');
      debugPrint('👤 [LOCAL_DS] Usuario: $userId');
      debugPrint('🌐 [LOCAL_DS] API Mode: $useApiMode (FORZADO A LOCAL)');
      debugPrint('🎮 [LOCAL_DS] Mock Data: $useMockData');
      
      // 🔧 FORZAR MODO LOCAL HASTA QUE LA API FUNCIONE
      debugPrint('📱 [LOCAL_DS] USANDO MODO LOCAL - Generando compañeros funcionales');
      final mockCompanions = _getMockCompanionsFunctional(userId);
      debugPrint('✅ [LOCAL_DS] ${mockCompanions.length} compañeros generados');
      
      // 🔧 GUARDAR EN CACHE TAMBIÉN
      await cacheCompanions(userId, mockCompanions);
      
      return mockCompanions;
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error: $e');
      // 🔧 SIEMPRE DEVOLVER DATOS FUNCIONALES
      return _getMockCompanionsFunctional(userId);
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
        duration: const Duration(hours: 24),
      );
      
      debugPrint('✅ [LOCAL_DS] ${companions.length} compañeros guardados en caché');
      
      // 🔧 GUARDAR STATS AUTOMÁTICAMENTE
      if (companions.isNotEmpty) {
        final stats = _calculateStatsFromCompanions(userId, companions);
        await cacheStats(stats);
        debugPrint('📊 [LOCAL_DS] Stats calculados y guardados');
      }
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error guardando compañeros: $e');
      // 🔧 NO LANZAR EXCEPCIÓN, SOLO LOGGING
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
      // 🔧 NO LANZAR EXCEPCIÓN
    }
  }

  @override
  Future<CompanionStatsModel?> getCachedStats(String userId) async {
    try {
      debugPrint('📊 [LOCAL_DS] === OBTENIENDO STATS ===');
      debugPrint('👤 [LOCAL_DS] Usuario: $userId');
      
      // 🔧 SIEMPRE GENERAR STATS FUNCIONALES
      debugPrint('🎮 [LOCAL_DS] Generando stats funcionales para tienda');
      final stats = _getMockStatsFunctional(userId);
      debugPrint('📊 [LOCAL_DS] Stats generados:');
      debugPrint('💰 Total: ${stats.totalPoints}, Disponibles: ${stats.availablePoints}');
      debugPrint('🐾 Poseídos: ${stats.ownedCompanions}/${stats.totalCompanions}');
      
      return stats;
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error obteniendo stats: $e');
      return _getMockStatsFunctional(userId);
    }
  }

  @override
  Future<void> cacheStats(CompanionStatsModel stats) async {
    try {
      debugPrint('💾 [LOCAL_DS] Guardando stats:');
      debugPrint('💰 Total: ${stats.totalPoints}, Disponibles: ${stats.availablePoints}');
      debugPrint('🐾 Poseídos: ${stats.ownedCompanions}');
      
      await cacheService.set(
        '$_statsPrefix${stats.userId}', 
        stats.toJson(),
        duration: const Duration(hours: 12),
      );
      
      debugPrint('✅ [LOCAL_DS] Stats guardados correctamente');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error guardando stats: $e');
      // 🔧 NO LANZAR EXCEPCIÓN
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      debugPrint('🗑️ [LOCAL_DS] Limpiando todo el cache de compañeros...');
      
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

  // 🔧 CALCULAR STATS DESDE COMPAÑEROS
  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : '';
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: ownedCount,
      totalPoints: 500, // 🔧 PUNTOS RAZONABLES PARA TESTING
      spentPoints: ownedCount * 50,
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  // 🔧 COMPAÑEROS FUNCIONALES PARA TESTING (SOLO DEXTER DESBLOQUEADO)
  List<CompanionModel> _getMockCompanionsFunctional(String userId) {
    final now = DateTime.now();
    debugPrint('🎮 [LOCAL_DS] Generando compañeros funcionales para testing');
    
    return [
      // ✨ DEXTER - Chihuahua (SOLO BABY DESBLOQUEADO)
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
      
      // 🔒 OTROS COMPAÑEROS BLOQUEADOS PARA COMPRAR
      CompanionModel(
        id: 'dexter_young',
        type: CompanionType.dexter,
        stage: CompanionStage.young,
        name: 'Dexter',
        description: 'Dexter ha crecido y es más juguetón',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 90,
        energy: 85,
        isOwned: false, // 🔒 BLOQUEADO
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 100,
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      
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
        isOwned: false, // 🔒 BLOQUEADO
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 150,
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      
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
        isOwned: false, // 🔒 BLOQUEADO
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 200,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      
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
        isOwned: false, // 🔒 BLOQUEADO
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 250,
        evolutionPrice: 200,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      
      // 🔒 MÁS ETAPAS PARA COMPRAR
      CompanionModel(
        id: 'elly_young',
        type: CompanionType.elly,
        stage: CompanionStage.young,
        name: 'Elly',
        description: 'Elly joven, más grande y cariñosa',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 100,
        energy: 95,
        isOwned: false, // 🔒 BLOQUEADO
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.normal,
        purchasePrice: 300,
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
    ];
  }

  CompanionStatsModel _getMockStatsFunctional(String userId) {
    debugPrint('💰 [LOCAL_DS] Generando stats funcionales para testing');
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: 1,   // 🔧 SOLO DEXTER BABY
      totalPoints: 500,    // 🔧 PUNTOS SUFICIENTES PARA COMPRAR
      spentPoints: 0,      // 🔧 NO HEMOS GASTADO NADA AÚN
      activeCompanionId: 'dexter_baby',
      totalFeedCount: 5,
      totalLoveCount: 3,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }
}