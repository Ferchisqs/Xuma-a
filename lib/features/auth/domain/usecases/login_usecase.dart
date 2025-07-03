// lib/features/auth/domain/usecases/login_usecase.dart
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;

  LoginParams({
    required this.email,
    required this.password,
  });
}

@lazySingleton
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validar email
    if (params.email.trim().isEmpty) {
      return const Left(ValidationFailure('El email es requerido'));
    }

    if (!params.email.contains('@') || !params.email.contains('.')) {
      return const Left(ValidationFailure('Formato de email inválido'));
    }

    // Validar password
    if (params.password.isEmpty) {
      return const Left(ValidationFailure('La contraseña es requerida'));
    }

    if (params.password.length < 6) {
      return const Left(ValidationFailure('La contraseña debe tener al menos 6 caracteres'));
    }

    // Llamar al repositorio
    return await _repository.login(params.email.trim().toLowerCase(), params.password);
  }
}