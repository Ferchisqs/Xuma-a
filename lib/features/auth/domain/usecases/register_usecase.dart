// lib/features/auth/domain/usecases/register_usecase.dart
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../entities/parental_info.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final int age;
  final ParentalInfo? parentalInfo;

  RegisterParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.age,
    this.parentalInfo,
  });

  bool get needsParentalConsent => age < 13;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'age': age,
    };

    if (parentalInfo != null) {
      // Agregar cada campo individualmente para evitar problemas de tipo
      final parentalData = parentalInfo!.toJson();
      parentalData.forEach((key, value) {
        json[key] = value;
      });
    }

    return json;
  }
}

@lazySingleton
class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    // Validar que las contraseñas coincidan
    if (params.password != params.confirmPassword) {
      return const Left(ValidationFailure('Las contraseñas no coinciden'));
    }

    // Validar edad mínima
    if (params.age < 1 || params.age > 120) {
      return const Left(ValidationFailure('Edad inválida'));
    }

    // Si es menor de 13 años, validar que tenga información parental
    if (params.needsParentalConsent && params.parentalInfo == null) {
      return const Left(ValidationFailure('Se requiere información del tutor para menores de 13 años'));
    }

    // Si es menor de 13 años, usar endpoint de consentimiento parental
    if (params.needsParentalConsent) {
      return await _repository.registerWithParentalConsent(params);
    }

    // Registro normal para mayores de 13 años
    return await _repository.register(params);
  }
}