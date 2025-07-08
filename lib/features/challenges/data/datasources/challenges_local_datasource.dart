import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/challenge_model.dart';
import '../models/user_challenge_stats_model.dart';
import '../../domain/entities/challenge_entity.dart';

abstract class ChallengesLocalDataSource {
  Future<List<ChallengeModel>> getCachedChallenges();
  Future<void> cacheChallenges(List<ChallengeModel> challenges);
  Future<ChallengeModel?> getCachedChallenge(String id);
  Future<void> cacheChallenge(ChallengeModel challenge);
  Future<UserChallengeStatsModel?> getCachedUserStats(String userId);
  Future<void> cacheUserStats(String userId, UserChallengeStatsModel stats);
  Future<List<ChallengeModel>> getCachedActiveChallenges(String userId);
  Future<void> cacheActiveChallenges(String userId, List<ChallengeModel> challenges);
}

@Injectable(as: ChallengesLocalDataSource)
class ChallengesLocalDataSourceImpl implements ChallengesLocalDataSource {
  final CacheService cacheService;
  
  static const String _challengesKey = 'challenges_list';
  static const String _challengePrefix = 'challenge_';
  static const String _userStatsPrefix = 'user_challenge_stats_';
  static const String _activeChallengesPrefix = 'active_challenges_';

  ChallengesLocalDataSourceImpl(this.cacheService);

  @override
  Future<List<ChallengeModel>> getCachedChallenges() async {
    try {
      final challengesJson = await cacheService.getList(_challengesKey);
      if (challengesJson == null || challengesJson.isEmpty) {
        return _getMockChallenges();
      }
      return challengesJson
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockChallenges();
    }
  }

  @override
  Future<void> cacheChallenges(List<ChallengeModel> challenges) async {
    try {
      final challengesJson = challenges.map((challenge) => challenge.toJson()).toList();
      await cacheService.setList(_challengesKey, challengesJson, duration: const Duration(hours: 2));
    } catch (e) {
      throw CacheException('Error caching challenges: ${e.toString()}');
    }
  }

  @override
  Future<ChallengeModel?> getCachedChallenge(String id) async {
    try {
      final challengeJson = await cacheService.get('$_challengePrefix$id');
      if (challengeJson == null) return null;
      return ChallengeModel.fromJson(challengeJson);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheChallenge(ChallengeModel challenge) async {
    try {
      await cacheService.set(
        '$_challengePrefix${challenge.id}',
        challenge.toJson(),
        duration: const Duration(hours: 2),
      );
    } catch (e) {
      throw CacheException('Error caching challenge: ${e.toString()}');
    }
  }

  @override
  Future<UserChallengeStatsModel?> getCachedUserStats(String userId) async {
    try {
      final statsJson = await cacheService.get('$_userStatsPrefix$userId');
      if (statsJson == null) {
        return _getMockUserStats();
      }
      return UserChallengeStatsModel.fromJson(statsJson);
    } catch (e) {
      return _getMockUserStats();
    }
  }

  @override
  Future<void> cacheUserStats(String userId, UserChallengeStatsModel stats) async {
    try {
      await cacheService.set(
        '$_userStatsPrefix$userId',
        stats.toJson(),
        duration: const Duration(hours: 1),
      );
    } catch (e) {
      throw CacheException('Error caching user stats: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getCachedActiveChallenges(String userId) async {
    try {
      final challengesJson = await cacheService.getList('$_activeChallengesPrefix$userId');
      if (challengesJson == null || challengesJson.isEmpty) {
        return _getMockActiveChallenges();
      }
      return challengesJson
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      return _getMockActiveChallenges();
    }
  }

  @override
  Future<void> cacheActiveChallenges(String userId, List<ChallengeModel> challenges) async {
    try {
      final challengesJson = challenges.map((challenge) => challenge.toJson()).toList();
      await cacheService.setList(
        '$_activeChallengesPrefix$userId',
        challengesJson,
        duration: const Duration(hours: 1),
      );
    } catch (e) {
      throw CacheException('Error caching active challenges: ${e.toString()}');
    }
  }

  // Mock Data
  List<ChallengeModel> _getMockChallenges() {
    final now = DateTime.now();
    return [
      ChallengeModel(
        id: 'challenge_1',
        title: 'Recicla 10 botellas de pet y depositadas en el contenedor',
        description: 'Recolecta 10 botellas de plástico PET y deposítalas en el contenedor de reciclaje correspondiente.',
        category: 'reciclaje',
        imageUrl: 'assets/images/challenge_recycling.png',
        iconCode: 0xe567, // Icons.recycling
        type: ChallengeType.daily,
        difficulty: ChallengeDifficulty.easy,
        totalPoints: 100,
        currentProgress: 7,
        targetProgress: 10,
        status: ChallengeStatus.active,
        startDate: now.subtract(const Duration(hours: 2)),
        endDate: now.add(const Duration(hours: 22)),
        requirements: ['Botellas PET limpias', 'Contenedor de reciclaje'],
        rewards: ['100 puntos', 'Badge Reciclador'],
        isParticipating: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'challenge_2',
        title: 'Recolecta 10 latas y deposítalas en el contenedor',
        description: 'Encuentra 10 latas de aluminio y deposítalas en el contenedor apropiado.',
        category: 'reciclaje',
        imageUrl: 'assets/images/challenge_cans.png',
        iconCode: 0xe567,
        type: ChallengeType.daily,
        difficulty: ChallengeDifficulty.easy,
        totalPoints: 80,
        currentProgress: 3,
        targetProgress: 10,
        status: ChallengeStatus.active,
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 23)),
        requirements: ['Latas de aluminio', 'Contenedor de reciclaje'],
        rewards: ['80 puntos', 'Badge Metales'],
        isParticipating: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChallengeModel(
        id: 'challenge_3',
        title: 'Recolecta 10 cajas y deposítalas en el contenedor',
        description: 'Reúne 10 cajas de cartón y deposítalas en el área de reciclaje.',
        category: 'reciclaje',
        imageUrl: 'assets/images/challenge_boxes.png',
        iconCode: 0xe567,
        type: ChallengeType.daily,
        difficulty: ChallengeDifficulty.medium,
        totalPoints: 120,
        currentProgress: 0,
        targetProgress: 10,
        status: ChallengeStatus.notStarted,
        startDate: now,
        endDate: now.add(const Duration(days: 1)),
        requirements: ['Cajas de cartón', 'Área de reciclaje'],
        rewards: ['120 puntos', 'Badge Cartón'],
        isParticipating: false,
        createdAt: now,
      ),
      ChallengeModel(
        id: 'challenge_4',
        title: 'Recolecta basura orgánica y haz tu composta',
        description: 'Recolecta residuos orgánicos y crea tu propia composta casera.',
        category: 'compostaje',
        imageUrl: 'assets/images/challenge_compost.png',
        iconCode: 0xe1b1, // Icons.compost
        type: ChallengeType.weekly,
        difficulty: ChallengeDifficulty.hard,
        totalPoints: 300,
        currentProgress: 1,
        targetProgress: 5,
        status: ChallengeStatus.active,
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        requirements: ['Residuos orgánicos', 'Contenedor para composta'],
        rewards: ['300 puntos', 'Badge Composta Master'],
        isParticipating: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  List<ChallengeModel> _getMockActiveChallenges() {
    return _getMockChallenges().where((c) => c.isParticipating && c.isActive).toList();
  }

  UserChallengeStatsModel _getMockUserStats() {
    return UserChallengeStatsModel(
      totalChallengesCompleted: 15,
      currentActiveChallenges: 3,
      totalPointsEarned: 2450,
      currentStreak: 7,
      bestStreak: 12,
      currentRank: 'Eco Guerrero',
      rankPosition: 1000,
      achievedBadges: const ['Reciclador Pro', 'Guardián del Agua', 'Composta Master'],
      categoryProgress: const {
        'reciclaje': 8,
        'energia': 5,
        'agua': 3,
        'compostaje': 2,
      },
      lastActivityDate: DateTime.now(),
    );
  }
}