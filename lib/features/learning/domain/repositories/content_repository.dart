import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/topic_entity.dart';
import '../entities/content_entity.dart';

abstract class ContentRepository {
  Future<Either<Failure, List<TopicEntity>>> getTopics();
  Future<Either<Failure, ContentEntity>> getContentById(String id);
}