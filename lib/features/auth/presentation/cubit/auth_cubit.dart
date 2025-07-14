// lib/features/auth/presentation/cubit/auth_cubit.dart - VERSIÓN COMPLETA
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/parental_info.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/services/auth_service.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../profile/domain/services/profile_service.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';

// ==================== ESTADOS MEJORADOS ====================
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
  final bool isProfileLoading; // 🆕 INDICADOR DE CARGA DE PERFIL

  const AuthAuthenticated(
    this.user, {
    this.emailVerified = true,
    this.parentalConsentApproved = true,
    this.fullProfile,
    this.isProfileLoading = false, // 🆕 DEFAULT FALSE
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

// ==================== CUBIT MEJORADO ====================
@injectable
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthService _authService;
  final ProfileService _profileService;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthService authService,
    required ProfileService profileService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _authService = authService,
       _profileService = profileService,
       super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(const AuthLoading(message: 'Iniciando sesión...'));

    try {
      final params = LoginParams(email: email, password: password);
      final result = await _loginUseCase(params);

      await result.fold(
        (failure) async {
          print('❌ Login failed: ${failure.message}');
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Login successful for: ${user.email}');
          await _handleSuccessfulAuth(user);
        },
      );
    } catch (e) {
      print('❌ Login exception: $e');
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
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          print('✅ Registration successful for: ${user.email}');
          await _handleSuccessfulAuth(user);
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

      final result = await _registerUseCase(completeParams);

      await result.fold(
        (failure) async {
          final userFriendlyMessage = ErrorHandler.getErrorMessage(failure.message);
          emit(AuthError(userFriendlyMessage));
        },
        (user) async {
          emit(AuthParentalConsentPending(user, parentalInfo.guardianEmail));
        },
      );
    } catch (e) {
      final userFriendlyMessage = ErrorHandler.getErrorMessage(e.toString());
      emit(AuthError(userFriendlyMessage));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading(message: 'Cerrando sesión...'));
    
    try {
      print('🔍 Starting logout process...');
      
      final result = await _authService.logout();
      
      await result.fold(
        (failure) async {
          print('⚠️ Server logout failed: ${failure.message}');
          print('✅ Cleaning local session anyway...');
          emit(AuthInitial());
        },
        (_) async {
          print('✅ Server logout successful, cleaning local session...');
          emit(AuthInitial());
        },
      );
    } catch (e) {
      print('❌ Logout exception: $e');
      print('✅ Exception during logout, but cleaning local session...');
      emit(AuthInitial());
    }
  }

  // ==================== GESTIÓN DE TOKENS ====================

  Future<void> validateCurrentToken() async {
    // 🆕 NO EMITIR LOADING PARA VALIDACIÓN SILENCIOSA
    try {
      final currentUserResult = await _authService.getCurrentUser();
      
      await currentUserResult.fold(
        (failure) async {
          emit(AuthInitial());
        },
        (user) async {
          if (user != null) {
            await _handleSuccessfulAuth(user, silent: true);
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

    emit(const AuthLoading(message: 'Enviando verificación...'));

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
          // No mostrar error, solo mantener estado actual
        },
        (status) async {
          if (status['isVerified'] == true) {
            await validateCurrentToken();
          }
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
            await validateCurrentToken();
          }
        },
      );
    } catch (e) {
      // Silenciar errores de verificación automática
    }
  }

  // ==================== MÉTODO PRINCIPAL MEJORADO ====================

  Future<void> _handleSuccessfulAuth(UserEntity user, {bool silent = false}) async {
    try {
      print('🔍 [AUTH] Handling successful auth for user: ${user.email}');
      
      // 🆕 EMITIR ESTADO AUTENTICADO INMEDIATAMENTE CON INDICADOR DE CARGA
      emit(AuthAuthenticated(user, isProfileLoading: true));
      
      // 🆕 INTENTAR CARGAR PERFIL COMPLETO SIN CAMBIAR EL ESTADO PRINCIPAL
      print('🔍 [AUTH] Loading full profile for user: ${user.id}');
      
      final profileResult = await _profileService.getUserProfile(user.id);
      
      await profileResult.fold(
        (failure) async {
          print('⚠️ [AUTH] Could not load full profile: ${failure.message}');
          // 🆕 MANTENER AUTENTICACIÓN BÁSICA PERO SIN INDICADOR DE CARGA
          emit(AuthAuthenticated(user, isProfileLoading: false));
        },
        (fullProfile) async {
          print('✅ [AUTH] Full profile loaded successfully');
          // 🆕 EMITIR CON PERFIL COMPLETO Y SIN INDICADOR DE CARGA
          emit(AuthAuthenticated(user, fullProfile: fullProfile, isProfileLoading: false));
        },
      );
      
    } catch (e) {
      print('❌ [AUTH] Error in _handleSuccessfulAuth: $e');
      // Si hay cualquier error, mantener autenticación básica
      emit(AuthAuthenticated(user, isProfileLoading: false));
    }
  }

  // ==================== MÉTODO PARA RECARGAR PERFIL ====================
  
  Future<void> refreshUserProfile() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    
    try {
      print('🔍 [AUTH] Refreshing user profile...');
      
      // 🆕 INDICAR QUE EL PERFIL SE ESTÁ CARGANDO
      emit(AuthAuthenticated(
        currentState.user,
        fullProfile: currentState.fullProfile,
        isProfileLoading: true,
      ));
      
      final profileResult = await _profileService.getUserProfile(currentState.user.id);
      
      await profileResult.fold(
        (failure) async {
          print('⚠️ [AUTH] Could not refresh profile: ${failure.message}');
          // Volver al estado anterior sin indicador de carga
          emit(AuthAuthenticated(
            currentState.user,
            fullProfile: currentState.fullProfile,
            isProfileLoading: false,
          ));
        },
        (fullProfile) async {
          print('✅ [AUTH] Profile refreshed successfully');
          emit(AuthAuthenticated(
            currentState.user,
            fullProfile: fullProfile,
            isProfileLoading: false,
          ));
        },
      );
    } catch (e) {
      print('❌ [AUTH] Error refreshing profile: $e');
      // Volver al estado anterior
      emit(AuthAuthenticated(
        currentState.user,
        fullProfile: currentState.fullProfile,
        isProfileLoading: false,
      ));
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

  void startPeriodicCheck(String userId) {
    if (state is AuthEmailVerificationSent || 
        state is AuthParentalConsentPending) {
      
      Stream.periodic(const Duration(seconds: 30))
          .take(20)
          .listen((_) async {
        if (state is AuthEmailVerificationSent) {
          await checkEmailVerificationStatus(userId);
        } else if (state is AuthParentalConsentPending) {
          await checkParentalConsentStatus(userId);
        }
      });
    }
  }

  // ==================== GETTERS MEJORADOS ====================
  
  UserEntity? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  UserProfileEntity? get currentUserProfile {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.fullProfile;
    }
    return null;
  }

  bool get isAuthenticated => state is AuthAuthenticated;
  
  bool get isLoading => state is AuthLoading;

  // 🆕 GETTER MEJORADO PARA ESTADO DE CARGA DE PERFIL
  bool get isLoadingProfile {
    final currentState = state;
    return currentState is AuthAuthenticated && currentState.isProfileLoading;
  }

  bool get hasFullProfile {
    final currentState = state;
    return currentState is AuthAuthenticated && 
           currentState.fullProfile != null && 
           !currentState.isProfileLoading;
  }

  // 🆕 GETTER PARA SABER SI EL USUARIO ESTÁ AUTENTICADO PERO SIN PERFIL COMPLETO
  bool get needsProfileLoad {
    final currentState = state;
    return currentState is AuthAuthenticated && 
           currentState.fullProfile == null && 
           !currentState.isProfileLoading;
  }
}