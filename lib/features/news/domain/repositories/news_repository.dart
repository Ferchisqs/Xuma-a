// lib/features/news/domain/repositories/news_repository.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/news_entity.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<NewsEntity>>> getClimateNews({
    int page = 1,
    int limit = 20,
  });
  
  Future<Either<Failure, List<NewsEntity>>> getCachedNews();
  
  Future<Either<Failure, bool>> refreshNews();
}