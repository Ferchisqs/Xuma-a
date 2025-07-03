// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/parental_info.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// Estados
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthParentalInfoRequired extends AuthState {
  final RegisterParams baseParams;

  const AuthParentalInfoRequired(this.baseParams);

  @override
  List<Object> get props => [baseParams];
}

class AuthParentalConsentRequired extends AuthState {
  final UserEntity user;

  const AuthParentalConsentRequired(this.user);

  @override
  List<Object> get props => [user];
}

// Cubit
@injectable
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  // Constructor corregido para injectable
  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       super(AuthInitial());

  // Login corregido con LoginParams
  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final params = LoginParams(email: email, password: password);
    final result = await _loginUseCase(params);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // Registro inicial - detecta si necesita consentimiento parental
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required int age,
  }) async {
    emit(AuthLoading());

    final baseParams = RegisterParams(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      age: age,
    );

    // Si es menor de 13 años, solicitar información parental
    if (baseParams.needsParentalConsent) {
      emit(AuthParentalInfoRequired(baseParams));
      return;
    }

    // Registro normal para mayores de 13 años
    final result = await _registerUseCase(baseParams);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // Registro con información parental
  Future<void> registerWithParentalInfo({
    required RegisterParams baseParams,
    required ParentalInfo parentalInfo,
  }) async {
    emit(AuthLoading());

    final completeParams = RegisterParams(
      firstName: baseParams.firstName,
      lastName: baseParams.lastName,
      email: baseParams.email,
      password: baseParams.password,
      confirmPassword: baseParams.confirmPassword,
      age: baseParams.age,
      parentalInfo: parentalInfo,
    );

    final result = await _registerUseCase(completeParams);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthParentalConsentRequired(user)),
    );
  }

  // Confirmar consentimiento parental (para usar con tu diseño actual)
  void acknowledgeParentalConsent() {
    emit(AuthInitial());
  }

  // Cancelar proceso de registro parental
  void cancelParentalProcess() {
    emit(AuthInitial());
  }

  // Logout
  void logout() {
    emit(AuthInitial());
  }

  // Reset estado
  void reset() {
    emit(AuthInitial());
  }
}