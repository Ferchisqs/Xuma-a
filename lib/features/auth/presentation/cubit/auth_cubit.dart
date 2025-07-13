// lib/features/auth/presentation/cubit/auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/parental_info.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/services/auth_service.dart';
import '../../../../core/utils/error_handler.dart';

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
  final bool isUserFriendly;

  const AuthError(this.message, {this.isUserFriendly = true});

  @override
  List<Object> get props => [message, isUserFriendly];
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


  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    try {
      final params = LoginParams(email: email, password: password);
      final result = await _loginUseCase(params);

      await result.fold(
        (failure) async {
          print('❌ Login failed: ${failure.message}'); // Para debug
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Login successful for: ${user.email}'); // Para debug
          await _handleSuccessfulAuth(user);
        },
      );
    } catch (e) {
      print('❌ Login exception: $e'); // Para debug
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
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

    try {
      final baseParams = RegisterParams(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        age: age,
      );

      print('🔍 Registering user: $email, age: $age'); // Para debug

      // Si es menor de 13 años, solicitar información parental
      if (baseParams.needsParentalConsent) {
        print('👨‍👩‍👧‍👦 Menor de 13, requiere info parental'); // Para debug
        emit(AuthParentalInfoRequired(baseParams));
        return;
      }

      // Registro normal
      final result = await _registerUseCase(baseParams);

      await result.fold(
        (failure) async {
          print('❌ Registration failed: ${failure.message}'); // Para debug
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Registration successful for: ${user.email}'); // Para debug
          await _handleSuccessfulAuth(user);
        },
      );
    } catch (e) {
      print('❌ Registration exception: $e'); // Para debug
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }
  Future<void> registerWithParentalInfo({
    required RegisterParams baseParams,
    required ParentalInfo parentalInfo,
  }) async {
    emit(AuthLoading());

    try {
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
        (failure) async {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          // Para menores, mostrar estado de consentimiento pendiente
          emit(AuthParentalConsentPending(user, parentalInfo.guardianEmail));
        },
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

 
  Future<void> logout() async {
    emit(AuthLoading());
    
    try {
      print('🔍 Starting logout process...'); // Para debug
      
      final result = await _authService.logout();
      
      await result.fold(
        (failure) async {
          print('⚠️ Server logout failed: ${failure.message}'); // Para debug
          // Incluso si falla el logout en el servidor, limpiar localmente
          print('✅ Cleaning local session anyway...');
          emit(AuthInitial());
        },
        (_) async {
          print('✅ Server logout successful, cleaning local session...');
          emit(AuthInitial());
        },
      );
    } catch (e) {
      print('❌ Logout exception: $e'); // Para debug
      // Incluso si hay excepción, limpiar estado local
      print('✅ Exception during logout, but cleaning local session...');
      emit(AuthInitial());
    }
  }

  // ==================== GESTIÓN DE TOKENS ====================

  Future<void> validateCurrentToken() async {
    try {
      final currentUserResult = await _authService.getCurrentUser();
      
      await currentUserResult.fold(
        (failure) async {
          // Si no hay usuario válido, ir a inicial sin mostrar error
          emit(AuthInitial());
        },
        (user) async {
          if (user != null) {
            await _handleSuccessfulAuth(user);
          } else {
            emit(AuthInitial());
          }
        },
      );
    } catch (e) {
      emit(AuthInitial());
    }
  }

  Future<void> refreshToken() async {
    try {
      final currentUserResult = await _authService.getCurrentUser();
      
      await currentUserResult.fold(
        (failure) async => emit(AuthInitial()),
        (user) async {
          if (user != null) {
            emit(AuthTokenRefreshed(user));
          } else {
            emit(AuthInitial());
          }
        },
      );
    } catch (e) {
      emit(AuthInitial());
    }
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================

  Future<void> sendEmailVerification(String userId) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationRequired) return;

    emit(AuthLoading());

    try {
      final result = await _authService.sendEmailVerification(userId);

      result.fold(
        (failure) {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (_) => emit(AuthEmailVerificationSent(
          currentState.user,
          currentState.user.email,
        )),
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  Future<void> resendEmailVerification(String email) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationSent &&
        currentState is! AuthEmailVerificationRequired) return;

    emit(AuthLoading());

    try {
      final result = await _authService.resendEmailVerification(email);

      result.fold(
        (failure) {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (_) {
          if (currentState is AuthEmailVerificationRequired) {
            emit(AuthEmailVerificationSent(currentState.user, email));
          } else if (currentState is AuthEmailVerificationSent) {
            emit(AuthEmailVerificationSent(currentState.user, email));
          }
        },
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  Future<void> checkEmailVerificationStatus(String userId) async {
    try {
      final result = await _authService.getVerificationStatus(userId);

      await result.fold(
        (failure) async {
          // No mostrar error, solo mantener estado actual para verificaciones automáticas
        },
        (status) async {
          if (status['isVerified'] == true) {
            // Email verificado, obtener usuario actualizado
            await validateCurrentToken();
          }
          // Si no está verificado, mantener el estado actual
        },
      );
    } catch (e) {
      // Silenciar errores de verificación automática
    }
  }

  // ==================== CONSENTIMIENTO PARENTAL ====================

  Future<void> checkParentalConsentStatus(String userId) async {
    try {
      final result = await _authService.getParentalConsentStatus(userId);

      await result.fold(
        (failure) async {
          // No mostrar error para verificaciones automáticas
        },
        (status) async {
          if (status['isApproved'] == true) {
            // Consentimiento aprobado, obtener usuario actualizado
            await validateCurrentToken();
          }
          // Si no está aprobado, mantener el estado actual
        },
      );
    } catch (e) {
      // Silenciar errores de verificación automática
    }
  }

  // ==================== MÉTODOS HELPER ====================

    Future<void> _handleSuccessfulAuth(UserEntity user) async {
    try {
      print('🔍 Handling successful auth for user: ${user.email}'); // Para debug
      
      // Para usuarios que ya están verificados (como en login), ir directo
      // Solo verificar servicios adicionales si es necesario
      
      if (user.age < 13) {
        // Para menores de 13, verificar consentimiento parental
        print('👨‍👩‍👧‍👦 Usuario menor de 13, verificando consentimiento parental'); // Para debug
        
        final consentResult = await _authService.getParentalConsentStatus(user.id);
        
        await consentResult.fold(
          (failure) async {
            print('⚠️ No se pudo verificar consentimiento parental, usuario autenticado'); // Para debug
            // Si no hay servicio de consentimiento, asumir que está autenticado
            emit(AuthAuthenticated(user));
          },
          (consentStatus) async {
            final isApproved = consentStatus['isApproved'] ?? 
                              consentStatus['approved'] ?? 
                              true; // Default true para login
            final parentEmail = consentStatus['parentEmail'] ?? 
                               consentStatus['guardian_email'] ?? 
                               '';
            
            if (!isApproved) {
              print('👨‍👩‍👧‍👦 Consentimiento parental pendiente'); // Para debug
              emit(AuthParentalConsentPending(user, parentEmail));
            } else {
              print('✅ Consentimiento parental aprobado'); // Para debug
              emit(AuthAuthenticated(user));
            }
          },
        );
      } else {
        // Para usuarios mayores de 13
        print('👤 Usuario mayor de 13, verificando estado de verificación'); // Para debug
        
        // Intentar obtener estado completo, pero no bloquear si no funciona
        final authStatusResult = await _authService.getFullAuthStatus(user.id);

        await authStatusResult.fold(
          (failure) async {
            print('⚠️ No se pudo verificar estado completo, asumiendo usuario verificado'); // Para debug
            // Para login, si no podemos verificar estado, asumir que está autenticado
            emit(AuthAuthenticated(user));
          },
          (authStatus) async {
            final emailVerification = authStatus['emailVerification'] as Map<String, dynamic>?;
            
            final isEmailVerified = emailVerification?['isVerified'] ?? 
                                   emailVerification?['emailVerified'] ?? 
                                   true; // Default true para login

            print('🔍 Email verification status: $isEmailVerified'); // Para debug

            if (!isEmailVerified) {
              print('📧 Email no verificado, mostrando pantalla de verificación'); // Para debug
              emit(AuthEmailVerificationRequired(user));
            } else {
              print('✅ Usuario completamente autenticado'); // Para debug
              emit(AuthAuthenticated(user));
            }
          },
        );
      }
    } catch (e) {
      print('❌ Error en _handleSuccessfulAuth: $e'); // Para debug
      // Si hay cualquier error, para login asumir que está autenticado
      print('✅ Error en verificación, pero usuario autenticado para login'); // Para debug
      emit(AuthAuthenticated(user));
    }
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

  // ==================== GETTERS ====================
  
  UserEntity? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  bool get isAuthenticated => state is AuthAuthenticated;
  
  bool get isLoading => state is AuthLoading;
}