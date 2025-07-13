import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateUserAvatarParams {
  final String userId;
  final String avatarUrl;

  UpdateUserAvatarParams({
    required this.userId,
    required this.avatarUrl,
  });
}

@lazySingleton
class UpdateUserAvatarUseCase implements UseCase<UserProfileEntity, UpdateUserAvatarParams> {
  final ProfileRepository _repository;

  UpdateUserAvatarUseCase(this._repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(UpdateUserAvatarParams params) async {
    if (params.userId.trim().isEmpty) {
      return const Left(ValidationFailure('El ID de usuario es requerido'));
    }

    if (params.avatarUrl.trim().isEmpty) {
      return const Left(ValidationFailure('La URL del avatar es requerida'));
    }

    // Validar que sea una URL válida
    if (!Uri.tryParse(params.avatarUrl)!.hasAbsolutePath == true) {
      return const Left(ValidationFailure('La URL del avatar no es válida'));
    }

    return await _repository.updateUserAvatar(params.userId, params.avatarUrl);
  }
}