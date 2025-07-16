// lib/features/news/data/datasources/news_local_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/news_model.dart';

abstract class NewsLocalDataSource {
  Future<List<NewsModel>?> getCachedNews();
  Future<void> cacheNews(List<NewsModel> news);
  Future<void> clearNewsCache();
}

@LazySingleton(as: NewsLocalDataSource)
class NewsLocalDataSourceImpl implements NewsLocalDataSource {
  final CacheService _cacheService;
  
  static const String _newsCacheKey = 'climate_news_cache';
  static const Duration _cacheDuration = Duration(hours: 2); // Cache por 2 horas

  NewsLocalDataSourceImpl(this._cacheService);

  @override
  Future<List<NewsModel>?> getCachedNews() async {
    try {
      print('📦 [NEWS CACHE] Attempting to get cached news...');
      
      final cachedData = await _cacheService.getList<Map<String, dynamic>>(_newsCacheKey);
      
      if (cachedData != null) {
        print('✅ [NEWS CACHE] Found ${cachedData.length} cached articles');
        
        final newsList = cachedData
            .map((newsJson) => NewsModel.fromJson(newsJson))
            .toList();
            
        return newsList;
      } else {
        print('📦 [NEWS CACHE] No cached news found');
        return null;
      }
    } catch (e) {
      print('❌ [NEWS CACHE] Error getting cached news: $e');
      throw CacheException('Failed to get cached news: $e');
    }
  }

  @override
  Future<void> cacheNews(List<NewsModel> news) async {
    try {
      print('💾 [NEWS CACHE] Caching ${news.length} articles...');
      
      final newsJsonList = news.map((newsModel) => newsModel.toJson()).toList();
      
      await _cacheService.setList(
        _newsCacheKey,
        newsJsonList,
        duration: _cacheDuration,
      );
      
      print('✅ [NEWS CACHE] News cached successfully');
    } catch (e) {
      print('❌ [NEWS CACHE] Error caching news: $e');
      throw CacheException('Failed to cache news: $e');
    }
  }

  @override
  Future<void> clearNewsCache() async {
    try {
      print('🗑️ [NEWS CACHE] Clearing news cache...');
      
      await _cacheService.remove(_newsCacheKey);
      
      print('✅ [NEWS CACHE] News cache cleared');
    } catch (e) {
      print('❌ [NEWS CACHE] Error clearing news cache: $e');
      throw CacheException('Failed to clear news cache: $e');
    }
  }

  // Helper method para verificar información del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      return await _cacheService.getCacheInfo(_newsCacheKey);
    } catch (e) {
      print('❌ [NEWS CACHE] Error getting cache info: $e');
      return {};
    }
  }
}