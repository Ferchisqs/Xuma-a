// lib/features/companion/data/datasources/companion_local_datasource.dart - CORREGIDO
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

  CompanionLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<CompanionModel>> getCachedCompanions(String userId) async {
    try {
      debugPrint('🐾 [LOCAL_DS] === OBTENIENDO COMPAÑEROS LOCALES ===');
      debugPrint('👤 [LOCAL_DS] Usuario: $userId');
      
      // Intentar cargar desde cache
      final companionsJson = await cacheService.getList<Map<String, dynamic>>('$_companionsPrefix$userId');
      
      if (companionsJson != null && companionsJson.isNotEmpty) {
        debugPrint('💾 [LOCAL_DS] Found ${companionsJson.length} cached companions');
        
        final companions = companionsJson
            .map((json) => CompanionModel.fromJson(json))
            .toList();
        
        // 🔧 VERIFICAR QUE DEXTER JOVEN ESTÉ PRESENTE
        if (!_hasDexterYoung(companions)) {
          debugPrint('🔧 [LOCAL_DS] Adding missing Dexter young');
          final dexterYoung = _createInitialDexterYoung();
          companions.insert(0, dexterYoung);
          
          // Guardar la lista actualizada
          await cacheCompanions(userId, companions);
        }
        
        debugPrint('✅ [LOCAL_DS] Returning ${companions.length} companions');
        return companions;
      }
      
      // Si no hay cache, crear set inicial con Dexter joven
      debugPrint('🔧 [LOCAL_DS] No cache found, creating initial set');
      final initialCompanions = _createInitialCompanionSet();
      await cacheCompanions(userId, initialCompanions);
      
      debugPrint('✅ [LOCAL_DS] Created and cached ${initialCompanions.length} initial companions');
      return initialCompanions;
      
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error getting cached companions: $e');
      
      // Fallback: crear set mínimo con Dexter joven
      final fallbackCompanions = [_createInitialDexterYoung()];
      return fallbackCompanions;
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
      
      // Si no hay stats, generar basado en companions actuales
      debugPrint('🔧 [LOCAL_DS] No cached stats, generating from companions');
      final companions = await getCachedCompanions(userId);
      final stats = _calculateStatsFromCompanions(userId, companions);
      await cacheStats(stats);
      
      debugPrint('✅ [LOCAL_DS] Generated and cached new stats');
      return stats;
      
    } catch (e) {
      debugPrint('❌ [LOCAL_DS] Error getting cached stats: $e');
      return _getDefaultStats(userId);
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

  // ==================== 🔧 MÉTODOS HELPER CORREGIDOS ====================

  /// Verificar si Dexter joven está en la lista
  bool _hasDexterYoung(List<CompanionModel> companions) {
    return companions.any((c) => 
      c.type == CompanionType.dexter && 
      c.stage == CompanionStage.young && 
      c.isOwned
    );
  }

  /// Crear Dexter joven inicial (mascota por defecto)
  CompanionModel _createInitialDexterYoung() {
    debugPrint('🐕 [LOCAL_DS] Creating initial Dexter young');
    
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
      isOwned: true, // 🔧 SIEMPRE POSEÍDO
      isSelected: true, // 🔧 ACTIVO POR DEFECTO
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // 🔧 GRATIS
      evolutionPrice: 100,
      unlockedAnimations: ['idle', 'blink', 'happy', 'eating', 'loving'],
      createdAt: DateTime.now(),
    );
  }

  /// Crear set inicial completo de companions
  List<CompanionModel> _createInitialCompanionSet() {
    debugPrint('🎮 [LOCAL_DS] Creating initial companion set');
    
    final now = DateTime.now();
    final companions = <CompanionModel>[];
    
    // Agregar Dexter joven como inicial (poseído)
    companions.add(_createInitialDexterYoung());
    
    // Agregar otras etapas de Dexter (no poseídas)
    companions.add(CompanionModel(
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
      purchasePrice: 75,
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));
    
    companions.add(CompanionModel(
      id: 'dexter_adult',
      type: CompanionType.dexter,
      stage: CompanionStage.adult,
      name: 'Dexter',
      description: 'Dexter adulto, el compañero perfecto',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: false,
      isSelected: false,
      purchasedAt: null,
      currentMood: CompanionMood.happy,
      purchasePrice: 150,
      evolutionPrice: 0,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: now,
    ));
    
    // Agregar otros tipos (no poseídos)
    for (final type in [CompanionType.elly, CompanionType.paxolotl, CompanionType.yami]) {
      for (final stage in CompanionStage.values) {
        companions.add(CompanionModel(
          id: '${type.name}_${stage.name}',
          type: type,
          stage: stage,
          name: _getDisplayName(type),
          description: _generateDescription(type, stage),
          level: 1,
          experience: 0,
          happiness: 100,
          hunger: 100,
          energy: 100,
          isOwned: false,
          isSelected: false,
          purchasedAt: null,
          currentMood: CompanionMood.happy,
          purchasePrice: _getDefaultPrice(type, stage),
          evolutionPrice: _getEvolutionPrice(stage),
          unlockedAnimations: ['idle', 'blink', 'happy'],
          createdAt: now,
        ));
      }
    }
    
    debugPrint('🎮 [LOCAL_DS] Created ${companions.length} companions (1 owned)');
    return companions;
  }

  /// Calcular stats desde la lista de companions
  CompanionStatsModel _calculateStatsFromCompanions(String userId, List<CompanionModel> companions) {
    final ownedCount = companions.where((c) => c.isOwned).length;
    final activeCompanionId = companions.where((c) => c.isSelected).isNotEmpty 
        ? companions.firstWhere((c) => c.isSelected).id 
        : 'dexter_young';
    
    // Calcular puntos gastados basado en precios de companions poseídos
    int spentPoints = 0;
    for (final companion in companions.where((c) => c.isOwned)) {
      spentPoints += companion.purchasePrice;
    }
    
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: ownedCount,
      totalPoints: 1000, // 🔧 PUNTOS GENEROSOS PARA TESTING
      spentPoints: spentPoints,
      activeCompanionId: activeCompanionId,
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  /// Stats por defecto
  CompanionStatsModel _getDefaultStats(String userId) {
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12,
      ownedCompanions: 1, // Solo Dexter joven inicial
      totalPoints: 1000,
      spentPoints: 0,
      activeCompanionId: 'dexter_young',
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }

  // Métodos helper para nombres, descripciones y precios
  String _getDisplayName(CompanionType type) {
    switch (type) {
      case CompanionType.dexter: return 'Dexter';
      case CompanionType.elly: return 'Elly';
      case CompanionType.paxolotl: return 'Paxolotl';
      case CompanionType.yami: return 'Yami';
    }
  }

  String _generateDescription(CompanionType type, CompanionStage stage) {
    final name = _getDisplayName(type);
    switch (stage) {
      case CompanionStage.baby:
        return 'Un adorable $name bebé lleno de energía';
      case CompanionStage.young:
        return '$name ha crecido y es más juguetón';
      case CompanionStage.adult:
        return '$name adulto, el compañero perfecto';
    }
  }

  int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    int basePrice = 50;
    switch (type) {
      case CompanionType.dexter: basePrice = 75; break;
      case CompanionType.elly: basePrice = 100; break;
      case CompanionType.paxolotl: basePrice = 150; break;
      case CompanionType.yami: basePrice = 200; break;
    }
    
    switch (stage) {
      case CompanionStage.baby: return basePrice;
      case CompanionStage.young: return basePrice + 25;
      case CompanionStage.adult: return basePrice + 50;
    }
  }

  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby: return 50;
      case CompanionStage.young: return 100;
      case CompanionStage.adult: return 0;
    }
  }
}