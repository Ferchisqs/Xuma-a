import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_remote_datasource.dart';
import '../datasources/news_local_datasource.dart';

@LazySingleton(as: NewsRepository)
class NewsRepositoryImpl implements NewsRepository {
  final NewsRemoteDataSource _remoteDataSource;
  final NewsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  NewsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<NewsEntity>>> getClimateNews({
    int page = 1,
    int limit = 20,
  }) async {
    print('🔍 [NEWS REPO] Getting climate news - Page: $page, Limit: $limit');
    
    if (await _networkInfo.isConnected) {
      try {
        print('🌐 [NEWS REPO] Network available, fetching from remote...');
        
        final remoteNews = await _remoteDataSource.getClimateNews(
          page: page,
          limit: limit,
        );
        
        // Cache solo la primera página para evitar sobrecarga
        if (page == 1) {
          await _localDataSource.cacheNews(remoteNews);
          print('💾 [NEWS REPO] First page cached successfully');
        }
        
        print('✅ [NEWS REPO] Remote news fetched: ${remoteNews.length} articles');
        return Right(remoteNews);
        
      } on ServerException catch (e) {
        print('❌ [NEWS REPO] Server error, trying cache fallback: ${e.message}');
        
        // Si hay error del servidor, intentar usar cache como fallback
        try {
          final cachedNews = await _localDataSource.getCachedNews();
          if (cachedNews != null && cachedNews.isNotEmpty) {
            print('📦 [NEWS REPO] Using cached news as fallback: ${cachedNews.length} articles');
            return Right(cachedNews);
          }
        } catch (cacheError) {
          print('❌ [NEWS REPO] Cache fallback also failed: $cacheError');
        }
        
        return Left(ServerFailure(e.message));
      }
    } else {
      print('📡 [NEWS REPO] No network, using cached news...');
      
      try {
        final localNews = await _localDataSource.getCachedNews();
        if (localNews != null && localNews.isNotEmpty) {
          print('✅ [NEWS REPO] Cached news retrieved: ${localNews.length} articles');
          return Right(localNews);
        } else {
          print('📦 [NEWS REPO] No cached news available');
          return const Left(CacheFailure('No hay noticias guardadas disponibles'));
        }
      } on CacheException catch (e) {
        print('❌ [NEWS REPO] Cache error: ${e.message}');
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<NewsEntity>>> getCachedNews() async {
    print('📦 [NEWS REPO] Getting cached news only...');
    
    try {
      final cachedNews = await _localDataSource.getCachedNews();
      if (cachedNews != null) {
        print('✅ [NEWS REPO] Cached news found: ${cachedNews.length} articles');
        return Right(cachedNews);
      } else {
        print('📦 [NEWS REPO] No cached news available');
        return const Left(CacheFailure('No hay noticias en cache'));
      }
    } on CacheException catch (e) {
      print('❌ [NEWS REPO] Cache error: ${e.message}');
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> refreshNews() async {
    print('🔄 [NEWS REPO] Refreshing news...');
    
    if (await _networkInfo.isConnected) {
      try {
        await _localDataSource.clearNewsCache();
        
        final remoteNews = await _remoteDataSource.getClimateNews(
          page: 1,
          limit: 20,
        );
        
        await _localDataSource.cacheNews(remoteNews);
        
        print('✅ [NEWS REPO] News refreshed successfully: ${remoteNews.length} articles');
        return const Right(true);
        
      } on ServerException catch (e) {
        print('❌ [NEWS REPO] Error refreshing news: ${e.message}');
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        print('❌ [NEWS REPO] Cache error during refresh: ${e.message}');
        return Left(CacheFailure(e.message));
      }
    } else {
      print('📡 [NEWS REPO] No network available for refresh');
      return const Left(NetworkFailure('Sin conexión a internet'));
    }
  }

  Future<void> debugCacheInfo() async {
    try {
      final cacheInfo = await (_localDataSource as NewsLocalDataSourceImpl).getCacheInfo();
      print('🔍 [NEWS REPO] Cache Info: $cacheInfo');
    } catch (e) {
      print('❌ [NEWS REPO] Error getting cache info: $e');
    }
  }
}