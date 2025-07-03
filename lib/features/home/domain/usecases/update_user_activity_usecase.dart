import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../repositories/home_repository.dart';

class UpdateUserActivityParams {
  final String activityType;
  final Map<String, dynamic>? metadata;

  UpdateUserActivityParams({
    required this.activityType,
    this.metadata,
  });
}

@lazySingleton
class UpdateUserActivityUseCase implements UseCase<bool, UpdateUserActivityParams> {
  final HomeRepository _repository;

  UpdateUserActivityUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(UpdateUserActivityParams params) async {
    return await _repository.updateUserActivity(params.activityType);
  }
}