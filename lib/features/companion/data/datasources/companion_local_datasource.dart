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
      final companionsJson = await cacheService.getList('$_companionsPrefix$userId');
      if (companionsJson == null || companionsJson.isEmpty) {
        return _getMockCompanions(userId);
      }
      return companionsJson
          .map((json) => CompanionModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockCompanions(userId);
    }
  }

  @override
  Future<void> cacheCompanions(String userId, List<CompanionModel> companions) async {
    try {
      final companionsJson = companions.map((companion) => companion.toJson()).toList();
      await cacheService.setList('$_companionsPrefix$userId', companionsJson);
    } catch (e) {
      throw CacheException('Error caching companions: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel?> getCachedCompanion(String companionId) async {
    try {
      final companionJson = await cacheService.get('$_companionPrefix$companionId');
      if (companionJson == null) return null;
      return CompanionModel.fromJson(companionJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheCompanion(CompanionModel companion) async {
    try {
      await cacheService.set('$_companionPrefix${companion.id}', companion.toJson());
    } catch (e) {
      throw CacheException('Error caching companion: ${e.toString()}');
    }
  }

 @override
Future<CompanionStatsModel?> getCachedStats(String userId) async {
  try {
    final statsJson = await cacheService.get('$_statsPrefix$userId');
    if (statsJson == null) {
      debugPrint('📊 No hay stats en cache, creando mock stats');
      return _getMockStats(userId);
    }
    
    final stats = CompanionStatsModel.fromJson(statsJson);
    debugPrint('📊 Stats cargados del cache:');
    debugPrint('💰 Total: ${stats.totalPoints}, Gastados: ${stats.spentPoints}, Disponibles: ${stats.availablePoints}');
    debugPrint('🐾 Poseídos: ${stats.ownedCompanions}/${stats.totalCompanions}');
    
    return stats;
  } catch (e) {
    debugPrint('❌ Error leyendo stats del cache: $e');
    return _getMockStats(userId);
  }
}


 @override
Future<void> cacheStats(CompanionStatsModel stats) async {
  try {
    debugPrint('💾 Guardando stats actualizados:');
    debugPrint('💰 Total: ${stats.totalPoints}, Gastados: ${stats.spentPoints}, Disponibles: ${stats.availablePoints}');
    debugPrint('🐾 Poseídos: ${stats.ownedCompanions}');
    
    await cacheService.set('$_statsPrefix${stats.userId}', stats.toJson());
    debugPrint('✅ Stats guardados correctamente en cache');
  } catch (e) {
    debugPrint('❌ Error guardando stats: $e');
    throw CacheException('Error caching companion stats: ${e.toString()}');
  }
}
Future<void> clearStatsCache(String userId) async {
  try {
    await cacheService.remove('$_statsPrefix$userId');
    debugPrint('🗑️ Cache de stats limpiado para usuario: $userId');
  } catch (e) {
    debugPrint('❌ Error limpiando cache de stats: $e');
  }
}

  // 🎨 MOCK DATA COMPLETO - Todos los compañeros con precios realistas
  List<CompanionModel> _getMockCompanions(String userId) {
    final now = DateTime.now();
    return [
      // DEXTER - Chihuahua (Starter - GRATIS)
      CompanionModel(
        id: 'dexter_baby',
        type: CompanionType.dexter,
        stage: CompanionStage.baby,
        name: 'Dexter',
        description: 'Un adorable chihuahua bebé lleno de energía',
        level: 1,
        experience: 0,
        happiness: 100,
        hunger: 80,
        energy: 90,
        isOwned: true, // 🎯 DEXTER BABY viene gratis!
        isSelected: true, // Es el compañero inicial
        purchasedAt: now,
        currentMood: CompanionMood.happy,
        purchasePrice: 0, // GRATIS
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_young',
        type: CompanionType.dexter,
        stage: CompanionStage.young,
        name: 'Dexter',
        description: 'Dexter ha crecido y es más juguetón',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 100, // 🔧 Era 75, ahora 100
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'dexter_adult',
        type: CompanionType.dexter,
        stage: CompanionStage.adult,
        name: 'Dexter',
        description: 'Dexter adulto, el compañero perfecto',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 200, // 🔧 Era 150, ahora 200
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited'],
        createdAt: now,
      ),

      // ELLY - Panda
      CompanionModel(
        id: 'elly_baby',
        type: CompanionType.elly,
        stage: CompanionStage.baby,
        name: 'Elly',
        description: 'Una tierna panda bebé que ama el bambú',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 150, // 🔧 Era 100, ahora 150
        evolutionPrice: 50,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'elly_young',
        type: CompanionType.elly,
        stage: CompanionStage.young,
        name: 'Elly',
        description: 'Elly joven, más grande y cariñosa',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 300, // 🔧 Era 150, ahora 300
        evolutionPrice: 75,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'elly_adult',
        type: CompanionType.elly,
        stage: CompanionStage.adult,
        name: 'Elly',
        description: 'Elly adulta, sabia y protectora',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 500, // 🔧 Era 250, ahora 500
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'sleeping'],
        createdAt: now,
      ),

      // PAXOLOTL - Ajolote
      CompanionModel(
        id: 'paxolotl_baby',
        type: CompanionType.paxolotl,
        stage: CompanionStage.baby,
        name: 'Paxolotl',
        description: 'Un pequeño ajolote lleno de curiosidad',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 400, // 🔧 Era 125, ahora 400
        evolutionPrice: 100,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_young',
        type: CompanionType.paxolotl,
        stage: CompanionStage.young,
        name: 'Paxolotl',
        description: 'Paxolotl joven, explorador nato',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 800, // 🔧 Era 200, ahora 800
        evolutionPrice: 150,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'paxolotl_adult',
        type: CompanionType.paxolotl,
        stage: CompanionStage.adult,
        name: 'Paxolotl',
        description: 'Paxolotl adulto, místico y poderoso',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 1500, // 🔧 Era 350, ahora 1500
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited'],
        createdAt: now,
      ),

      // YAMI - Jaguar (Premium)
      CompanionModel(
        id: 'yami_baby',
        type: CompanionType.yami,
        stage: CompanionStage.baby,
        name: 'Yami',
        description: 'Un jaguar bebé feroz pero tierno',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 1000, // 🔧 Era 200, ahora 1000
        evolutionPrice: 200,
        unlockedAnimations: ['idle', 'blink'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_young',
        type: CompanionType.yami,
        stage: CompanionStage.young,
        name: 'Yami',
        description: 'Yami joven, elegante y ágil',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 2000, // 🔧 Era 300, ahora 2000
        evolutionPrice: 300,
        unlockedAnimations: ['idle', 'blink', 'happy'],
        createdAt: now,
      ),
      CompanionModel(
        id: 'yami_adult',
        type: CompanionType.yami,
        stage: CompanionStage.adult,
        name: 'Yami',
        description: 'Yami adulta, majestuosa protectora de la naturaleza',
        level: 1,
        experience: 0,
        happiness: 50,
        hunger: 50,
        energy: 50,
        isOwned: false,
        isSelected: false,
        currentMood: CompanionMood.normal,
        purchasePrice: 3000, // 🔧 Era 500, ahora 3000 (la más cara pero comprables)
        evolutionPrice: 0,
        unlockedAnimations: ['idle', 'blink', 'happy', 'excited', 'loving'],
        createdAt: now,
      ),
    ];
  }

  CompanionStatsModel _getMockStats(String userId) {
    return CompanionStatsModel(
      userId: userId,
      totalCompanions: 12, // 4 tipos x 3 etapas
      ownedCompanions: 1, // Solo Dexter baby inicialmente
      totalPoints: 10000, // 🚀 ¡10,000 PUNTOS PARA COMPRAR TODO!
      spentPoints: 0,
      activeCompanionId: 'dexter_baby',
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }
}