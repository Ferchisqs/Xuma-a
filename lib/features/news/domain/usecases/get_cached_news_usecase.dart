import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/errors/failures.dart';
import 'package:xuma_a/core/usecases/usecase.dart';
import 'package:xuma_a/core/utils/either.dart';
import 'package:xuma_a/features/news/domain/entities/news_entity.dart';
import 'package:xuma_a/features/news/domain/repositories/news_repository.dart';

@lazySingleton
class GetCachedNewsUseCase implements NoParamsUseCase<List<NewsEntity>> {
  final NewsRepository _repository;

  GetCachedNewsUseCase(this._repository);

  @override
  Future<Either<Failure, List<NewsEntity>>> call() async {
    return await _repository.getCachedNews();
  }
}