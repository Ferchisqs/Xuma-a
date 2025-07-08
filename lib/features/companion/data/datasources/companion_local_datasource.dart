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
        return _getMockStats(userId);
      }
      return CompanionStatsModel.fromJson(statsJson);
    } catch (e) {
      return _getMockStats(userId);
    }
  }

  @override
  Future<void> cacheStats(CompanionStatsModel stats) async {
    try {
      await cacheService.set('$_statsPrefix${stats.userId}', stats.toJson());
    } catch (e) {
      throw CacheException('Error caching companion stats: ${e.toString()}');
    }
  }

  // 🎨 MOCK DATA - Todos los compañeros con precios realistas
  List<CompanionModel> _getMockCompanions(String userId) {
    final now = DateTime.now();
    return [
      // DEXTER - Chihuahua (Starter - más barato)
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
        purchasePrice: 0, // Gratis
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
        purchasePrice: 75,
        evolutionPrice: 100,
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
        purchasePrice: 150,
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
        purchasePrice: 100,
        evolutionPrice: 75,
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
        purchasePrice: 150,
        evolutionPrice: 125,
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
        purchasePrice: 250,
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
        purchasePrice: 125,
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
        purchasePrice: 200,
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
        purchasePrice: 350,
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
        purchasePrice: 200,
        evolutionPrice: 150,
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
        purchasePrice: 300,
        evolutionPrice: 200,
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
        purchasePrice: 500, // La más cara
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
      ownedCompanions: 1, // Solo Dexter baby
      totalPoints: 100, // Puntos iniciales del usuario
      spentPoints: 0,
      activeCompanionId: 'dexter_baby',
      totalFeedCount: 0,
      totalLoveCount: 0,
      totalEvolutions: 0,
      lastActivity: DateTime.now(),
    );
  }
}