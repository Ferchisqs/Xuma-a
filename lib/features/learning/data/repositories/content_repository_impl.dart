// lib/features/learning/data/repositories/content_repository_impl.dart - CON BY-TOPIC
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/media_resolver_service.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_remote_datasource.dart';
import '../datasources/learning_local_datasource.dart';

@Injectable(as: ContentRepository)
class ContentRepositoryImpl implements ContentRepository {
  final ContentRemoteDataSource remoteDataSource;
  final LearningLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MediaResolverService mediaResolverService; // 👈 Agregado

  ContentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.mediaResolverService,
  });

  @override
  Future<Either<Failure, List<TopicEntity>>> getTopics() async {
    try {
      print('🔍 [CONTENT REPO] Getting topics...');
      
      if (await networkInfo.isConnected) {
        try {
          print('🌐 [CONTENT REPO] Network available, fetching from remote');
          final remoteTopics = await remoteDataSource.getTopics();
          
          // TODO: Cache topics if needed
          // await localDataSource.cacheTopics(remoteTopics);
          
          print('✅ [CONTENT REPO] Got ${remoteTopics.length} topics from remote');
          return Right(remoteTopics);
        } catch (e) {
          print('❌ [CONTENT REPO] Remote fetch failed: $e');
          
          // TODO: Fallback to cache if available
          // final localTopics = await localDataSource.getCachedTopics();
          // return Right(localTopics);
          
          return Left(ServerFailure('Error fetching topics: $e'));
        }
      } else {
        print('📱 [CONTENT REPO] No network, using cache');
        
        // TODO: Get from cache
        // final localTopics = await localDataSource.getCachedTopics();
        // return Right(localTopics);
        
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      print('❌ [CONTENT REPO] Server exception: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ [CONTENT REPO] Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [CONTENT REPO] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ContentEntity>> getContentById(String id) async {
    try {
      print('🔍 [CONTENT REPO] Getting content by ID: $id');
      
      if (await networkInfo.isConnected) {
        try {
          print('🌐 [CONTENT REPO] Network available, fetching content from remote');
          final rawContent = await remoteDataSource.getContentById(id); // 👈 Cambio: rawContent
          
          // 👈 Nuevo: Resolver media URLs
          final resolvedContent = await mediaResolverService.resolveMediaUrls(rawContent);
          
          // TODO: Cache content if needed
          // await localDataSource.cacheContent(resolvedContent);
          
          print('✅ [CONTENT REPO] Got content: ${resolvedContent.title}');
          return Right(resolvedContent); // 👈 Cambio: resolvedContent
        } catch (e) {
          print('❌ [CONTENT REPO] Remote content fetch failed: $e');
          
          // TODO: Fallback to cache if available
          // final localContent = await localDataSource.getCachedContent(id);
          // if (localContent != null) {
          //   return Right(localContent);
          // }
          
          return Left(ServerFailure('Error fetching content: $e'));
        }
      } else {
        print('📱 [CONTENT REPO] No network, using cache');
        
        // TODO: Get from cache
        // final localContent = await localDataSource.getCachedContent(id);
        // if (localContent != null) {
        //   return Right(localContent);
        // }
        
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      print('❌ [CONTENT REPO] Server exception: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ [CONTENT REPO] Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [CONTENT REPO] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }

  // 🆕 IMPLEMENTACIÓN PARA CONTENIDOS POR TOPIC
  @override
  Future<Either<Failure, List<ContentEntity>>> getContentsByTopicId(
    String topicId, 
    int page, 
    int limit,
  ) async {
    try {
      print('🔍 [CONTENT REPO] Getting contents by topic ID: $topicId (page: $page, limit: $limit)');
      
      if (await networkInfo.isConnected) {
        try {
          print('🌐 [CONTENT REPO] Network available, fetching contents from remote');
          final remoteContents = await remoteDataSource.getContentsByTopicId(topicId, page, limit);
          
          // TODO: Cache contents if needed
          // await localDataSource.cacheContentsByTopic(topicId, remoteContents);
          
          print('✅ [CONTENT REPO] Got ${remoteContents.length} contents from remote');
          return Right(remoteContents);
        } catch (e) {
          print('❌ [CONTENT REPO] Remote contents fetch failed: $e');
          
          // TODO: Fallback to cache if available
          // final localContents = await localDataSource.getCachedContentsByTopic(topicId);
          // if (localContents != null) {
          //   return Right(localContents);
          // }
          
          return Left(ServerFailure('Error fetching contents: $e'));
        }
      } else {
        print('📱 [CONTENT REPO] No network, using cache');
        
        // TODO: Get from cache
        // final localContents = await localDataSource.getCachedContentsByTopic(topicId);
        // if (localContents != null) {
        //   return Right(localContents);
        // }
        
        return Left(NetworkFailure('Sin conexión a internet'));
      }
    } on ServerException catch (e) {
      print('❌ [CONTENT REPO] Server exception: ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ [CONTENT REPO] Cache exception: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [CONTENT REPO] Unknown error: $e');
      return Left(UnknownFailure('Error desconocido: ${e.toString()}'));
    }
  }
}