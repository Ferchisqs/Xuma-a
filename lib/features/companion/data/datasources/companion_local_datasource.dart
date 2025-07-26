// lib/features/companion/data/datasources/companion_local_datasource.dart
// 🔥 CORREGIDO: Sin Dexter gratis, cache limpio

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';

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

  CompanionLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<CompanionModel>> getCachedCompanions(String userId) async {
    try {
      debugPrint('🐾 [LOCAL_DS] === OBTENIENDO COMPAÑEROS LOCALES (SIN DEXTER GRATIS) ===');
      debugPrint('👤 [LOCAL_DS] Usuario: $userId');
      
      // Intentar cargar desde cache
      final companionsJson = await cacheService.getList<Map<String, dynamic>>('$_companionsPrefix$userId');
      
      if (companionsJson != null && companionsJson.isNotEmpty) {
        debugPrint('💾 [LOCAL_DS] Found ${companionsJson.length} cached companions');
        
        final companions = companionsJson
            .map((json) => CompanionModel.fromJson(json))
            .toList();
        
        debugPrint('✅ [LOCAL_DS] Returning ${companions.length} companions from cache');
        return companions;
      }
      
      // 🔥 SI NO HAY CACHE, RETORNAR LISTA VACÍA (SIN CREAR NADA)
      debugPrint('📭 [LOCAL_DS] No cached companions found - returning empty list');
      return [];
      
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error getting cached companions: $e');
      
      // 🔥 EN ERROR, TAMBIÉN RETORNAR LISTA VACÍA
      debugPrint('📭 [LOCAL_DS] Error fallback - returning empty list');
      return [];
    }
  }

  @override
  Future<void> cacheCompanions(String userId, List<CompanionModel> companions) async {
    try {
      debugPrint('💾 [LOCAL_DS] Caching ${companions.length} companions for user: $userId');
      
      final companionsJson = companions.map((companion) => companion.toJson()).toList();
      
      await cacheService.setList(
        '$_companionsPrefix$userId', 
        companionsJson,
        duration: const Duration(hours: 24),
      );
      
      debugPrint('✅ [LOCAL_DS] Successfully cached companions');
      
      // Actualizar stats automáticamente
      if (companions.isNotEmpty) {
        final stats = _calculateStatsFromCompanions(userId, companions);
        await cacheStats(stats);
        debugPrint('📊 [LOCAL_DS] Updated stats automatically');
      } else {
        // 🔥 SI NO HAY COMPANIONS, CREAR STATS VACÍAS
        final emptyStats = _getEmptyStats(userId);
        await cacheStats(emptyStats);
        debugPrint('📊 [LOCAL_DS] Created empty stats');
      }
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error caching companions: $e');
    }
  }

  @override
  Future<CompanionModel?> getCachedCompanion(String companionId) async {
    try {
      debugPrint('🔍 [LOCAL_DS] Getting cached companion: $companionId');
      
      final companionJson = await cacheService.get<Map<String, dynamic>>('$_companionPrefix$companionId');
      if (companionJson == null) {
        debugPrint('⚠️ [LOCAL_DS] Companion not found in individual cache');
        return null;
      }
      
      final companion = CompanionModel.fromJson(companionJson);
      debugPrint('✅ [LOCAL_DS] Found companion: ${companion.displayName}');
      return companion;
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error getting cached companion: $e');
      return null;
    }
  }

  @override
  Future<void> cacheCompanion(CompanionModel companion) async {
    try {
      debugPrint('💾 [LOCAL_DS] Caching individual companion: ${companion.displayName}');
      
      await cacheService.set(
        '$_companionPrefix${companion.id}', 
        companion.toJson(),
        duration: const Duration(hours: 24),
      );
      
      debugPrint('✅ [LOCAL_DS] Successfully cached individual companion');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error caching individual companion: $e');
    }
  }

  @override
  Future<CompanionStatsModel?> getCachedStats(String userId) async {
    try {
      debugPrint('📊 [LOCAL_DS] === OBTENIENDO STATS LOCALES ===');
      debugPrint('👤 [LOCAL_DS] Usuario: $userId');
      
      final statsJson = await cacheService.get<Map<String, dynamic>>('$_statsPrefix$userId');
      
      if (statsJson != null) {
        final stats = CompanionStatsModel.fromJson(statsJson);
        debugPrint('💾 [LOCAL_DS] Found cached stats:');
        debugPrint('💰 Available points: ${stats.availablePoints}');
        debugPrint('🐾 Owned companions: ${stats.ownedCompanions}');
        return stats;
      }
      
      // 🔥 SI NO HAY STATS, GENERAR VACÍAS
      debugPrint('🔧 [LOCAL_DS] No cached stats, generating empty stats');
      final emptyStats = _getEmptyStats(userId);
      await cacheStats(emptyStats);
      
      debugPrint('✅ [LOCAL_DS] Generated and cached empty stats');
      return emptyStats;
      
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error getting cached stats: $e');
      return _getEmptyStats(userId);
    }
  }

  @override
  Future<void> cacheStats(CompanionStatsModel stats) async {
    try {
      debugPrint('💾 [LOCAL_DS] Caching stats for user: ${stats.userId}');
      debugPrint('💰 Points: ${stats.totalPoints} total, ${stats.availablePoints} available');
      debugPrint('🐾 Companions: ${stats.ownedCompanions}/${stats.totalCompanions}');
      
      await cacheService.set(
        '$_statsPrefix${stats.userId}', 
        stats.toJson(),
        duration: const Duration(hours: 12),
      );
      
      debugPrint('✅ [LOCAL_DS] Successfully cached stats');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error caching stats: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      debugPrint('🗑️ [LOCAL_DS] Clearing all companion cache...');
      
      final allKeys = await cacheService.getKeysWithPrefix(_companionsPrefix);
      final companionKeys = await cacheService.getKeysWithPrefix(_companionPrefix);
      final statsKeys = await cacheService.getKeysWithPrefix(_statsPrefix);
      
      for (final key in [...allKeys, ...companionKeys, ...statsKeys]) {
        await cacheService.remove(key);
      }
      
      debugPrint('✅ [LOCAL_DS] Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error clearing cache: $e');
    }
  }

  // ==================== 🔧 MÉTODOS HELPER ACTUALIZADOS ====================

  /// Calcular stats desde la lista de companions (REALES)
  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : (companions.isNotEmpty ? companions.first.id : '');
    
    // Calcular puntos gastados basado en precios de companions poseídos
    int spentPoints = 0;
    for (final companion in companions.where((c) => c.isOwned)) {
      spentPoints += companion.purchasePrice;
    }
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas (meta del juego)
      ownedCompanions: ownedCount,
      totalPoints: 1000, // Puntos base para testing
      spentPoints: spentPoints,
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  /// Stats vacías para usuarios sin mascotas
  CompanionStatsModel _getEmptyStats(String userId) {
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // Meta del juego: 4 tipos x 3 etapas
      ownedCompanions: 0, // 🔥 CERO mascotas (sin Dexter gratis)
      totalPoints: 1000, // Puntos iniciales generosos para testing
      spentPoints: 0,
      activeCompanionId: '', // 🔥 SIN MASCOTA ACTIVA
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }
}