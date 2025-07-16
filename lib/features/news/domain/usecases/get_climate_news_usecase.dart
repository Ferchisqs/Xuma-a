import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/news_entity.dart';
import '../repositories/news_repository.dart';

class GetClimateNewsParams {
  final int page;
  final int limit;

  const GetClimateNewsParams({
    this.page = 1,
    this.limit = 20,
  });
}

@lazySingleton
class GetClimateNewsUseCase implements UseCase<List<NewsEntity>, GetClimateNewsParams> {
  final NewsRepository _repository;

  GetClimateNewsUseCase(this._repository);

  @override
  Future<Either<Failure, List<NewsEntity>>> call(GetClimateNewsParams params) async {
    return await _repository.getClimateNews(
      page: params.page,
      limit: params.limit,
    );
  }
}