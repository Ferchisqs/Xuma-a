import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/topic_entity.dart';
import '../entities/content_entity.dart';

abstract class ContentRepository {
  Future<Either<Failure, List<TopicEntity>>> getTopics();
  Future<Either<Failure, ContentEntity>> getContentById(String id);
  
  // 🆕 NUEVO MÉTODO PARA CONTENIDOS POR TOPIC
  Future<Either<Failure, List<ContentEntity>>> getContentsByTopicId(
    String topicId, 
    int page, 
    int limit,
  );
}