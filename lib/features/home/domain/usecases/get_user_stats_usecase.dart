import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_stats_entity.dart';
import '../repositories/home_repository.dart';

@lazySingleton
class GetUserStatsUseCase implements NoParamsUseCase<UserStatsEntity> {
  final HomeRepository _repository;

  GetUserStatsUseCase(this._repository);

  @override
  Future<Either<Failure, UserStatsEntity>> call() async {
    return await _repository.getUserStats();
  }
}