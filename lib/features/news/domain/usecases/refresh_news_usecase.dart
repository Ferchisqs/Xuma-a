import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/errors/failures.dart';
import 'package:xuma_a/core/usecases/usecase.dart';
import 'package:xuma_a/core/utils/either.dart';
import 'package:xuma_a/features/news/domain/repositories/news_repository.dart';

@lazySingleton
class RefreshNewsUseCase implements NoParamsUseCase<bool> {
  final NewsRepository _repository;

  RefreshNewsUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call() async {
    return await _repository.refreshNews();
  }
}