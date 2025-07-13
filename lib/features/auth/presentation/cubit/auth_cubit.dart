// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/parental_info.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/services/auth_service.dart';

// ==================== ESTADOS ====================
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final bool emailVerified;
  final bool parentalConsentApproved;

  const AuthAuthenticated(
    this.user, {
    this.emailVerified = true,
    this.parentalConsentApproved = true,
  });

  @override
  List<Object> get props => [user, emailVerified, parentalConsentApproved];
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

class AuthParentalConsentPending extends AuthState {
  final UserEntity user;
  final String parentEmail;

  const AuthParentalConsentPending(this.user, this.parentEmail);

  @override
  List<Object> get props => [user, parentEmail];
}

class AuthEmailVerificationRequired extends AuthState {
  final UserEntity user;

  const AuthEmailVerificationRequired(this.user);

  @override
  List<Object> get props => [user];
}

class AuthEmailVerificationSent extends AuthState {
  final UserEntity user;
  final String email;

  const AuthEmailVerificationSent(this.user, this.email);

  @override
  List<Object> get props => [user, email];
}

class AuthTokenRefreshed extends AuthState {
  final UserEntity user;

  const AuthTokenRefreshed(this.user);

  @override
  List<Object> get props => [user];
}

// ==================== CUBIT ====================
@injectable
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthService _authService;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthService authService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _authService = authService,
       super(AuthInitial());

  // ==================== AUTENTICACIÓN BÁSICA ====================

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final params = LoginParams(email: email, password: password);
    final result = await _loginUseCase(params);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async => await _handleSuccessfulAuth(user),
    );
  }

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

    // Registro normal
    final result = await _registerUseCase(baseParams);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async => await _handleSuccessfulAuth(user),
    );
  }

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

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async {
        // Para menores, mostrar estado de consentimiento pendiente
        emit(AuthParentalConsentPending(user, parentalInfo.guardianEmail));
      },
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    
    final result = await _authService.logout();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthInitial()),
    );
  }

  // ==================== GESTIÓN DE TOKENS ====================

  Future<void> validateCurrentToken() async {
    final currentUserResult = await _authService.getCurrentUser();
    
    await currentUserResult.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async {
        if (user != null) {
          await _handleSuccessfulAuth(user);
        } else {
          emit(AuthInitial());
        }
      },
    );
  }

  Future<void> refreshToken() async {
    // Este método será llamado automáticamente por el ApiClient
    // pero puede ser útil para casos específicos
    final currentUserResult = await _authService.getCurrentUser();
    
    await currentUserResult.fold(
      (failure) async => emit(AuthError('Sesión expirada')),
      (user) async {
        if (user != null) {
          emit(AuthTokenRefreshed(user));
        } else {
          emit(AuthInitial());
        }
      },
    );
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================

  Future<void> sendEmailVerification(String userId) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationRequired) return;

    emit(AuthLoading());

    final result = await _authService.sendEmailVerification(userId);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthEmailVerificationSent(
        currentState.user,
        currentState.user.email,
      )),
    );
  }

  Future<void> resendEmailVerification(String email) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationSent &&
        currentState is! AuthEmailVerificationRequired) return;

    emit(AuthLoading());

    final result = await _authService.resendEmailVerification(email);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        if (currentState is AuthEmailVerificationRequired) {
          emit(AuthEmailVerificationSent(currentState.user, email));
        } else if (currentState is AuthEmailVerificationSent) {
          emit(AuthEmailVerificationSent(currentState.user, email));
        }
      },
    );
  }

  Future<void> checkEmailVerificationStatus(String userId) async {
    final result = await _authService.getVerificationStatus(userId);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (status) async {
        if (status['isVerified'] == true) {
          // Email verificado, obtener usuario actualizado
          await validateCurrentToken();
        }
        // Si no está verificado, mantener el estado actual
      },
    );
  }

  // ==================== CONSENTIMIENTO PARENTAL ====================

  Future<void> checkParentalConsentStatus(String userId) async {
    final result = await _authService.getParentalConsentStatus(userId);

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (status) async {
        if (status['isApproved'] == true) {
          // Consentimiento aprobado, obtener usuario actualizado
          await validateCurrentToken();
        }
        // Si no está aprobado, mantener el estado actual
      },
    );
  }

  // ==================== MÉTODOS HELPER ====================

  Future<void> _handleSuccessfulAuth(UserEntity user) async {
    // Verificar estado completo del usuario
    final authStatusResult = await _authService.getFullAuthStatus(user.id);

    await authStatusResult.fold(
      (failure) async {
        // Si no podemos verificar el estado, asumir que está autenticado
        emit(AuthAuthenticated(user));
      },
      (authStatus) async {
        final emailVerification = authStatus['emailVerification'] as Map<String, dynamic>?;
        final parentalConsent = authStatus['parentalConsent'] as Map<String, dynamic>?;
        
        final isEmailVerified = emailVerification?['isVerified'] ?? true;
        final needsParentalConsent = parentalConsent?['requiresConsent'] ?? false;
        final isParentalConsentApproved = parentalConsent?['isApproved'] ?? true;

        // Determinar el estado apropiado
        if (!isEmailVerified && user.age >= 13) {
          emit(AuthEmailVerificationRequired(user));
        } else if (needsParentalConsent && !isParentalConsentApproved) {
          final parentEmail = parentalConsent?['parentEmail'] ?? '';
          emit(AuthParentalConsentPending(user, parentEmail));
        } else {
          emit(AuthAuthenticated(
            user,
            emailVerified: isEmailVerified,
            parentalConsentApproved: isParentalConsentApproved,
          ));
        }
      },
    );
  }

  // ==================== MÉTODOS DE NAVEGACIÓN ====================

  void acknowledgeParentalConsent() {
    emit(AuthInitial());
  }

  void cancelParentalProcess() {
    emit(AuthInitial());
  }

  void goBackToVerification(UserEntity user) {
    emit(AuthEmailVerificationRequired(user));
  }

  void reset() {
    emit(AuthInitial());
  }

  // ==================== AUTO-VERIFICACIÓN ====================

  /// Inicia verificación automática periódica para usuarios pendientes
  void startPeriodicCheck(String userId) {
    if (state is AuthEmailVerificationSent || 
        state is AuthParentalConsentPending) {
      
      // Verificar cada 30 segundos si el estado ha cambiado
      Stream.periodic(const Duration(seconds: 30))
          .take(20) // Máximo 20 intentos (10 minutos)
          .listen((_) async {
        if (state is AuthEmailVerificationSent) {
          await checkEmailVerificationStatus(userId);
        } else if (state is AuthParentalConsentPending) {
          await checkParentalConsentStatus(userId);
        }
      });
    }
  }
}