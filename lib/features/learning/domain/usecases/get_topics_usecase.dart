import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/topic_entity.dart';
import '../repositories/content_repository.dart';

@injectable
class GetTopicsUseCase implements UseCase<List<TopicEntity>, NoParams> {
  final ContentRepository repository;

  GetTopicsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TopicEntity>>> call(NoParams params) {
    return repository.getTopics();
  }
}