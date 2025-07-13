import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileParams {
  final String userId;

  GetUserProfileParams({required this.userId});
}

@lazySingleton
class GetUserProfileUseCase implements UseCase<UserProfileEntity, GetUserProfileParams> {
  final ProfileRepository _repository;

  GetUserProfileUseCase(this._repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(GetUserProfileParams params) async {
    if (params.userId.trim().isEmpty) {
      return const Left(ValidationFailure('El ID de usuario es requerido'));
    }

    return await _repository.getUserProfile(params.userId);
  }
}