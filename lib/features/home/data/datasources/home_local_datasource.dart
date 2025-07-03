import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/eco_tip_model.dart';
import '../models/user_stats_model.dart';

abstract class HomeLocalDataSource {
  Future<EcoTipModel?> getCachedDailyTip();
  Future<void> cacheDailyTip(EcoTipModel tip);
  Future<UserStatsModel?> getCachedUserStats();
  Future<void> cacheUserStats(UserStatsModel stats);
  Future<void> clearCache();
}

@LazySingleton(as: HomeLocalDataSource)
class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final CacheService _cacheService;

  HomeLocalDataSourceImpl(this._cacheService);

  @override
  Future<EcoTipModel?> getCachedDailyTip() async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>('daily_tip');
      if (cachedData != null) {
        return EcoTipModel.fromJson(cachedData);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached daily tip: $e');
    }
  }

  @override
  Future<void> cacheDailyTip(EcoTipModel tip) async {
    try {
      await _cacheService.set(
        'daily_tip',
        tip.toJson(),
        duration: const Duration(hours: 24),
      );
    } catch (e) {
      throw CacheException('Failed to cache daily tip: $e');
    }
  }

  @override
  Future<UserStatsModel?> getCachedUserStats() async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>('user_stats');
      if (cachedData != null) {
        return UserStatsModel.fromJson(cachedData);
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user stats: $e');
    }
  }

  @override
  Future<void> cacheUserStats(UserStatsModel stats) async {
    try {
      await _cacheService.set(
        'user_stats',
        stats.toJson(),
        duration: const Duration(hours: 1),
      );
    } catch (e) {
      throw CacheException('Failed to cache user stats: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _cacheService.clear();
    } catch (e) {
      throw CacheException('Failed to clear home cache: $e');
    }
  }
}