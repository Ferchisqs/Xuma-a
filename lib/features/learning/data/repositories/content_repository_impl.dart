import 'package:injectable/injectable.dart';
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

  ContentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
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
          final remoteContent = await remoteDataSource.getContentById(id);
          
          // TODO: Cache content if needed
          // await localDataSource.cacheContent(remoteContent);
          
          print('✅ [CONTENT REPO] Got content: ${remoteContent.title}');
          return Right(remoteContent);
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
}