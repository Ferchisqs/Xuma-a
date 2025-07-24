// lib/features/auth/presentation/cubit/auth_cubit.dart - VERSIÓN COMPLETA CORREGIDA
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/services/auth_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../profile/domain/services/profile_service.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../../domain/entities/parental_info.dart';
import '../../../../core/services/token_manager.dart';

// ==================== ESTADOS ====================
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  
  const AuthLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final bool emailVerified;
  final bool parentalConsentApproved;
  final UserProfileEntity? fullProfile;
  final bool isProfileLoading;

  const AuthAuthenticated(
    this.user, {
    this.emailVerified = true,
    this.parentalConsentApproved = true,
    this.fullProfile,
    this.isProfileLoading = false,
  });

  @override
  List<Object?> get props => [user, emailVerified, parentalConsentApproved, fullProfile, isProfileLoading];
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
  final ProfileService _profileService;
  final TokenManager _tokenManager;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthService authService,
    required ProfileService profileService,
    required TokenManager tokenManager,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _authService = authService,
       _profileService = profileService,
       _tokenManager = tokenManager,
       super(AuthInitial());

  // ==================== MÉTODOS PRINCIPALES ====================

  Future<void> login(String email, String password) async {
    emit(const AuthLoading(message: 'Iniciando sesión...'));

    try {
      final params = LoginParams(email: email, password: password);
      final result = await _loginUseCase(params);

      await result.fold(
        (failure) async {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          await _handleSuccessfulAuth(user);
        },
      );
    } catch (e) {
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
    emit(const AuthLoading(message: 'Creando tu cuenta...'));

    try {
      final baseParams = RegisterParams(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        age: age,
      );

      print('🔍 Registering user: $email, age: $age');

      if (baseParams.needsParentalConsent) {
        print('👨‍👩‍👧‍👦 Menor de 13, requiere info parental');
        emit(AuthParentalInfoRequired(baseParams));
        return;
      }

      final result = await _registerUseCase(baseParams);

      await result.fold(
        (failure) async {
          print('❌ Registration failed: ${failure.message}');
          
          String userFriendlyMessage;
          
          if (failure.message.toLowerCase().contains('already exists') ||
              failure.message.toLowerCase().contains('ya existe') ||
              failure.message.toLowerCase().contains('duplicate') ||
              (failure.message.toLowerCase().contains('email') && 
               failure.message.toLowerCase().contains('use'))) {
            userFriendlyMessage = 'Este email ya está registrado. Intenta iniciar sesión o usa otro email.';
          } else if (failure.message.toLowerCase().contains('validation') ||
                     failure.message.toLowerCase().contains('invalid')) {
            userFriendlyMessage = 'Datos de registro inválidos. Verifica la información ingresada.';
          } else if (failure.message.toLowerCase().contains('network') ||
                     failure.message.toLowerCase().contains('connection')) {
            userFriendlyMessage = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
          } else {
            userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          }
          
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Registration successful for: ${user.email}');
          
          final hasValidToken = await _hasValidToken();
          
          if (hasValidToken) {
            print('✅ [AUTH] User fully authenticated after registration (has tokens)');
            await _handleSuccessfulAuth(user);
          } else {
            print('📧 [AUTH] User registered but needs email verification (no tokens)');
            emit(AuthEmailVerificationRequired(user));
          }
        },
      );
    } catch (e) {
      print('❌ Registration exception: $e');
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  Future<void> registerWithParentalInfo({
    required RegisterParams baseParams,
    required ParentalInfo parentalInfo,
  }) async {
    emit(const AuthLoading(message: 'Registrando con consentimiento parental...'));

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

      final result = await _authService.registerWithParentalConsent(completeParams);

      await result.fold(
        (failure) async {
          print('❌ Parental registration failed: ${failure.message}');
          
          String userFriendlyMessage;
          
          if (failure.message.toLowerCase().contains('already exists') ||
              failure.message.toLowerCase().contains('ya existe')) {
            userFriendlyMessage = 'El email del tutor ya está registrado. Verifica la dirección de correo.';
          } else if (failure.message.toLowerCase().contains('guardian') ||
                     failure.message.toLowerCase().contains('tutor')) {
            userFriendlyMessage = 'Error con la información del tutor. Verifica los datos ingresados.';
          } else {
            userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          }
          
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Parental registration successful');
          emit(AuthParentalConsentPending(user, parentalInfo.parentEmail));
          startPeriodicCheck(user.id);
        },
      );
    } catch (e) {
      print('❌ Parental registration exception: $e');
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  // ==================== MÉTODOS DE TOKEN ====================

  Future<void> refreshToken() async {
    try {
      print('🔄 [AUTH] Attempting to refresh token...');
      
      final storedRefreshToken = await _tokenManager.getRefreshToken();
      
      if (storedRefreshToken == null) {
        print('⚠️ [AUTH] No refresh token available');
        emit(AuthInitial());
        return;
      }
      
      final result = await _authService.refreshUserToken(storedRefreshToken);
      
      await result.fold(
        (failure) async {
          print('❌ [AUTH] Token refresh failed: ${failure.message}');
          await cleanInconsistentState();
        },
        (response) async {
          print('✅ [AUTH] Token refreshed successfully');
          await validateCurrentToken();
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception during token refresh: $e');
      await cleanInconsistentState();
    }
  }

  Future<bool> autoRefreshToken() async {
    try {
      print('🔄 [AUTH] Auto-refreshing token...');
      
      final storedRefreshToken = await _tokenManager.getRefreshToken();
      
      if (storedRefreshToken == null) {
        print('⚠️ [AUTH] No refresh token for auto-refresh');
        return false;
      }
      
      final result = await _authService.refreshUserToken(storedRefreshToken);
      
      return await result.fold(
        (failure) async {
          print('❌ [AUTH] Auto token refresh failed: ${failure.message}');
          return false;
        },
        (response) async {
          print('✅ [AUTH] Auto token refresh successful');
          return true;
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception during auto token refresh: $e');
      return false;
    }
  }

  Future<bool> _hasValidToken() async {
    try {
      final result = await _authService.hasValidToken();
      
      return await result.fold(
        (failure) async {
          print('⚠️ [AUTH] Error checking token validity: ${failure.message}');
          return false;
        },
        (isValid) async {
          return isValid;
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception checking token validity: $e');
      return false;
    }
  }

  // ==================== MÉTODOS DE NAVEGACIÓN Y CONTROL ====================

  void reset() {
    emit(AuthInitial());
  }

  void acknowledgeParentalConsent() {
    emit(AuthInitial());
  }

  void cancelParentalProcess() {
    emit(AuthInitial());
  }

  void goBackToVerification(UserEntity user) {
    emit(AuthEmailVerificationRequired(user));
  }

  // ==================== CONSENTIMIENTO PARENTAL ====================

  Future<void> checkParentalConsentStatus(String userId) async {
    try {
      final result = await _authService.getParentalConsentStatus(userId);

      await result.fold(
        (failure) async {
          print('⚠️ [AUTH] Error checking parental consent status: ${failure.message}');
        },
        (status) async {
          print('🔍 [AUTH] Parental consent status: $status');
          
          if (status['isApproved'] == true || status['approved'] == true) {
            print('✅ [AUTH] Parental consent approved, attempting authentication...');
            await validateCurrentToken();
          } else {
            print('⚠️ [AUTH] Parental consent still pending');
          }
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception checking parental consent: $e');
    }
  }

  Future<void> requestParentalConsent({
    required String minorUserId,
    required String parentEmail,
    required String parentName,
    required String relationship,
  }) async {
    try {
      emit(const AuthLoading(message: 'Enviando solicitud parental...'));
      
      final result = await _authService.requestParentalConsent(
        minorUserId: minorUserId,
        parentEmail: parentEmail,
        parentName: parentName,
        relationship: relationship,
      );

      await result.fold(
        (failure) async {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (response) async {
          print('✅ [AUTH] Parental consent request sent successfully');
          
          final tempUser = UserEntity(
            id: minorUserId,
            email: '',
            firstName: '',
            lastName: '',
            age: 0,
            createdAt: DateTime.now(),
            needsParentalConsent: true,
          );
          
          emit(AuthParentalConsentPending(tempUser, parentEmail));
        },
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================

  Future<void> sendEmailVerification(String userId) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationRequired && 
        currentState is! AuthEmailVerificationSent) {
      print('⚠️ [AUTH] Cannot send email verification from current state: ${currentState.runtimeType}');
      return;
    }

    emit(const AuthLoading(message: 'Enviando verificación...'));

    try {
      final result = await _authService.sendEmailVerification(userId);

      result.fold(
        (failure) {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (_) {
          if (currentState is AuthEmailVerificationRequired) {
            emit(AuthEmailVerificationSent(
              currentState.user,
              currentState.user.email,
            ));
          } else if (currentState is AuthEmailVerificationSent) {
            emit(AuthEmailVerificationSent(
              currentState.user,
              currentState.email,
            ));
          }
        },
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  Future<void> resendEmailVerification(String email) async {
    final currentState = state;
    if (currentState is! AuthEmailVerificationSent &&
        currentState is! AuthEmailVerificationRequired) {
      print('⚠️ [AUTH] Cannot resend email from current state: ${currentState.runtimeType}');
      return;
    }

    emit(const AuthLoading(message: 'Reenviando verificación...'));

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
          print('⚠️ [AUTH] Could not check email verification status: ${failure.message}');
        },
        (status) async {
          print('🔍 [AUTH] Email verification status: $status');
          
          if (status['isVerified'] == true || status['verified'] == true) {
            final currentState = state;
            if (currentState is AuthEmailVerificationRequired) {
              await handleEmailVerified(currentState.user);
            } else if (currentState is AuthEmailVerificationSent) {
              await handleEmailVerified(currentState.user);
            }
          } else {
            print('⚠️ [AUTH] Email still not verified');
          }
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception checking email verification: $e');
    }
  }

  // ==================== VALIDACIÓN DE TOKEN ====================

  Future<void> validateCurrentToken() async {
    try {
      print('🔍 [AUTH] Validating current token...');
      
      final currentUserResult = await _authService.getCurrentUser();
      
      await currentUserResult.fold(
        (failure) async {
          print('❌ [AUTH] Token validation failed: ${failure.message}');
          await cleanInconsistentState();
        },
        (user) async {
          if (user != null) {
            print('✅ [AUTH] Token validation successful for: ${user.email}');
            
            final currentState = state;
            if (currentState is AuthAuthenticated) {
              if (currentState.user.email.toLowerCase() != user.email.toLowerCase()) {
                print('⚠️ [AUTH] User mismatch detected, cleaning state...');
                await cleanInconsistentState();
                return;
              }
            }
            
            await _handleSuccessfulAuth(user);
          } else {
            print('⚠️ [AUTH] No user found during validation');
            emit(AuthInitial());
          }
        },
      );
    } catch (e) {
      print('❌ [AUTH] Exception during token validation: $e');
      emit(AuthInitial());
    }
  }

  // ==================== MÉTODOS DE LIMPIEZA ====================

  Future<void> cleanInconsistentState() async {
    try {
      print('🧹 [AUTH] Cleaning inconsistent state...');
      
      await _authService.logout();
      
      emit(AuthInitial());
      
      print('✅ [AUTH] Inconsistent state cleaned');
    } catch (e) {
      print('❌ [AUTH] Error cleaning inconsistent state: $e');
      emit(AuthInitial());
    }
  }

  Future<void> forceCompleteLogout() async {
    try {
      print('🔧 [AUTH] Forcing complete logout...');
      
      emit(const AuthLoading(message: 'Limpiando sesión...'));
      
      await _authService.logout();
      
      emit(AuthInitial());
      
      print('✅ [AUTH] Complete logout forced successfully');
    } catch (e) {
      print('❌ [AUTH] Error in force logout: $e');
      emit(AuthInitial());
    }
  }

  // ==================== VERIFICACIÓN PERIÓDICA ====================

  void startPeriodicCheck(String userId) {
    if (state is AuthEmailVerificationSent || 
        state is AuthParentalConsentPending) {
      
      Stream.periodic(const Duration(seconds: 30))
          .take(20) // Verificar por 10 minutos máximo
          .listen((_) async {
        if (state is AuthEmailVerificationSent) {
          await checkEmailVerificationStatus(userId);
        } else if (state is AuthParentalConsentPending) {
          await checkParentalConsentStatus(userId);
        }
      });
    }
  }

  // Dentro de tu AuthCubit (lib/features/auth/presentation/cubit/auth_cubit.dart)
Future<void> refreshUserProfile() async {
  try {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(const AuthLoading(message: 'Actualizando perfil...'));
      
      // Obtener el usuario actualizado
      final userResult = await _authService.getCurrentUser();
      
      await userResult.fold(
        (failure) async {
          emit(AuthError('Error al actualizar perfil: ${failure.message}'));
        },
        (user) async {
          if (user != null) {
            // Obtener el perfil completo
            final profileResult = await _profileService.getUserProfile(user.id);
            
            await profileResult.fold(
              (failure) async {
                emit(AuthAuthenticated(
                  user,
                  emailVerified: currentState.emailVerified,
                  parentalConsentApproved: currentState.parentalConsentApproved,
                  fullProfile: currentState.fullProfile,
                  isProfileLoading: false,
                ));
              },
              (profile) async {
                emit(AuthAuthenticated(
                  user,
                  emailVerified: currentState.emailVerified,
                  parentalConsentApproved: currentState.parentalConsentApproved,
                  fullProfile: profile,
                  isProfileLoading: false,
                ));
              },
            );
          } else {
            emit(AuthInitial());
          }
        },
      );
    }
  } catch (e) {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthAuthenticated(
        currentState.user,
        emailVerified: currentState.emailVerified,
        parentalConsentApproved: currentState.parentalConsentApproved,
        fullProfile: currentState.fullProfile,
        isProfileLoading: false,
      ));
    }
    print('❌ [AUTH] Error refreshing user profile: $e');
  }
}

  // ==================== MÉTODOS PRIVADOS ====================

  Future<void> _handleSuccessfulAuth(UserEntity user) async {
    try {
      emit(AuthAuthenticated(user, isProfileLoading: true));
      
      final profileResult = await _profileService.getUserProfile(user.id);
      
      await profileResult.fold(
        (failure) async {
          emit(AuthAuthenticated(user, isProfileLoading: false));
        },
        (profile) async {
          emit(AuthAuthenticated(
            user,
            fullProfile: profile,
            isProfileLoading: false,
          ));
        },
      );
    } catch (e) {
      emit(AuthAuthenticated(user, isProfileLoading: false));
    }
  }

  Future<void> handleEmailVerified(UserEntity user) async {
    try {
      final hasValidToken = await _hasValidToken();
      
      if (hasValidToken) {
        await _handleSuccessfulAuth(user);
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthInitial());
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final result = await _authService.getCurrentUser();
      
      await result.fold(
        (failure) async {
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
}