// lib/features/auth/presentation/cubit/auth_cubit.dart - VERSIÓN COMPLETA CORREGIDA
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
      print('🔍 User data: firstName=$firstName, lastName=$lastName, age=$age');

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
          print('✅ Registered user data: firstName=${user.firstName}, lastName=${user.lastName}, age=${user.age}');
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
      print('🔍 [AUTH] User data disponible:');
      print('   - ID: ${user.id}');
      print('   - Email: ${user.email}');
      print('   - FirstName: ${user.firstName}');
      print('   - LastName: ${user.lastName}');
      print('   - Age: ${user.age}');
      
      // 🆕 EMITIR ESTADO AUTENTICADO INMEDIATAMENTE CON INDICADOR DE CARGA
      emit(AuthAuthenticated(user, isProfileLoading: true));
      
      // 🆕 INTENTAR CARGAR PERFIL COMPLETO PASANDO DATOS DEL USUARIO ACTUAL
      print('🔍 [AUTH] Loading full profile for user: ${user.id}');
      
      final profileResult = await _profileService.getUserProfile(user.id);
      
      await profileResult.fold(
        (failure) async {
          print('⚠️ [AUTH] Could not load full profile: ${failure.message}');
          
          // 🆕 SI EL PERFIL FALLA, CREAR UNO BASADO EN LOS DATOS DEL USUARIO
          print('🔧 [AUTH] Creating profile from user data...');
          final fallbackProfile = _createProfileFromUserData(user);
          emit(AuthAuthenticated(user, fullProfile: fallbackProfile, isProfileLoading: false));
        },
        (fullProfile) async {
          print('✅ [AUTH] Full profile loaded successfully');
          
          // 🆕 VERIFICAR SI EL PERFIL TIENE DATOS PLACEHOLDER
          if (_hasPlaceholderData(fullProfile)) {
            print('⚠️ [AUTH] Profile has placeholder data, merging with user data...');
            final mergedProfile = _mergeUserDataWithProfile(user, fullProfile);
            emit(AuthAuthenticated(user, fullProfile: mergedProfile, isProfileLoading: false));
          } else {
            emit(AuthAuthenticated(user, fullProfile: fullProfile, isProfileLoading: false));
          }
        },
      );
      
    } catch (e) {
      print('❌ [AUTH] Error in _handleSuccessfulAuth: $e');
      // Si hay cualquier error, mantener autenticación básica
      emit(AuthAuthenticated(user, isProfileLoading: false));
    }
  }

  // 🆕 MÉTODO PARA VERIFICAR SI EL PERFIL TIENE DATOS PLACEHOLDER
  bool _hasPlaceholderData(UserProfileEntity profile) {
    // Verificar firstName
    if (profile.firstName.toLowerCase() == 'string' || 
        profile.firstName.toLowerCase() == 'user' ||
        profile.firstName.toLowerCase() == 'example' ||
        profile.firstName.trim().isEmpty) {
      return true;
    }
    
    // Verificar lastName
    if (profile.lastName.toLowerCase() == 'string' || 
        profile.lastName.toLowerCase() == 'user' ||
        profile.lastName.toLowerCase() == 'example') {
      return true;
    }
    
    // Verificar age
    if (profile.age == 0) {
      return true;
    }
    
    return false;
  }

  // 🆕 MÉTODO PARA CREAR PERFIL DESDE DATOS DEL USUARIO
  UserProfileEntity _createProfileFromUserData(UserEntity user) {
    print('🔧 [AUTH] Creating profile from user data...');
    
    // Usar datos reales del usuario que se registró
    return UserProfileEntity(
      id: user.id,
      email: user.email,
      firstName: user.firstName.isNotEmpty ? user.firstName : 'Usuario',
      lastName: user.lastName.isNotEmpty ? user.lastName : 'XUMA\'A',
      age: user.age > 0 ? user.age : 25,
      avatarUrl: user.profilePicture,
      bio: 'Miembro de la comunidad XUMA\'A 🌱',
      location: null,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      lastLogin: user.lastLogin ?? DateTime.now(),
      needsParentalConsent: user.needsParentalConsent,
      ecoPoints: 150, // Puntos iniciales
      achievementsCount: 2, // Logros iniciales
      lessonsCompleted: 1, // Lecciones iniciales
      level: _getUserLevelFromAge(user.age > 0 ? user.age : 25),
    );
  }

  // 🆕 MÉTODO PARA MEZCLAR DATOS DEL USUARIO CON EL PERFIL
  UserProfileEntity _mergeUserDataWithProfile(UserEntity user, UserProfileEntity profile) {
    print('🔧 [AUTH] Merging user data with profile...');
    print('🔧 [AUTH] User firstName: ${user.firstName}');
    print('🔧 [AUTH] Profile firstName: ${profile.firstName}');
    print('🔧 [AUTH] User age: ${user.age}');
    print('🔧 [AUTH] Profile age: ${profile.age}');
    
    return UserProfileEntity(
      id: profile.id,
      email: profile.email.isNotEmpty ? profile.email : user.email,
      firstName: _isPlaceholder(profile.firstName) ? user.firstName : profile.firstName,
      lastName: _isPlaceholder(profile.lastName) ? user.lastName : profile.lastName,
      age: profile.age == 0 ? user.age : profile.age,
      avatarUrl: profile.avatarUrl ?? user.profilePicture,
      bio: profile.bio ?? 'Miembro de la comunidad XUMA\'A 🌱',
      location: profile.location,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt ?? DateTime.now(),
      lastLogin: profile.lastLogin ?? user.lastLogin ?? DateTime.now(),
      needsParentalConsent: profile.needsParentalConsent,
      ecoPoints: profile.ecoPoints > 0 ? profile.ecoPoints : 150,
      achievementsCount: profile.achievementsCount > 0 ? profile.achievementsCount : 2,
      lessonsCompleted: profile.lessonsCompleted > 0 ? profile.lessonsCompleted : 1,
      level: profile.level.isNotEmpty && !_isPlaceholder(profile.level) 
          ? profile.level 
          : _getUserLevelFromAge(profile.age > 0 ? profile.age : user.age),
    );
  }

  // 🆕 HELPER PARA VERIFICAR SI ES PLACEHOLDER
  bool _isPlaceholder(String value) {
    if (value.trim().isEmpty) return true;
    final lower = value.toLowerCase().trim();
    return lower == 'string' || 
           lower == 'user' || 
           lower == 'example';
  }

  // 🆕 HELPER PARA OBTENER NIVEL BASADO EN EDAD
  String _getUserLevelFromAge(int age) {
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }

  // ==================== MÉTODO PARA RECARGAR PERFIL MEJORADO ====================
  
  Future<void> refreshUserProfile() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    
    try {
      print('🔍 [AUTH] Refreshing user profile...');
      print('🔍 [AUTH] Current user data:');
      print('   - ID: ${currentState.user.id}');
      print('   - Email: ${currentState.user.email}');
      print('   - FirstName: ${currentState.user.firstName}');
      print('   - LastName: ${currentState.user.lastName}');
      print('   - Age: ${currentState.user.age}');
      
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
          
          // 🆕 SI FALLA, USAR DATOS DEL USUARIO ACTUAL
          final fallbackProfile = _createProfileFromUserData(currentState.user);
          emit(AuthAuthenticated(
            currentState.user,
            fullProfile: fallbackProfile,
            isProfileLoading: false,
          ));
        },
        (fullProfile) async {
          print('✅ [AUTH] Profile refreshed successfully');
          
          // 🆕 VERIFICAR Y MEZCLAR DATOS SI ES NECESARIO
          if (_hasPlaceholderData(fullProfile)) {
            print('⚠️ [AUTH] Refreshed profile has placeholder data, merging...');
            final mergedProfile = _mergeUserDataWithProfile(currentState.user, fullProfile);
            emit(AuthAuthenticated(
              currentState.user,
              fullProfile: mergedProfile,
              isProfileLoading: false,
            ));
          } else {
            emit(AuthAuthenticated(
              currentState.user,
              fullProfile: fullProfile,
              isProfileLoading: false,
            ));
          }
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

  // 🆕 MÉTODO PARA FORZAR RECARGA CON DATOS DEL REGISTRO
  Future<void> forceProfileReloadWithUserData() async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    
    print('🔧 [AUTH] Forcing profile reload with user data...');
    
    // Crear perfil basado en datos del usuario actual
    final userBasedProfile = _createProfileFromUserData(currentState.user);
    
    // Emitir inmediatamente
    emit(AuthAuthenticated(
      currentState.user,
      fullProfile: userBasedProfile,
      isProfileLoading: false,
    ));
    
    // Luego intentar cargar el perfil real del servidor en background
    try {
      final profileResult = await _profileService.getUserProfile(currentState.user.id);
      
      await profileResult.fold(
        (failure) async {
          print('⚠️ [AUTH] Server profile still failing, keeping user-based profile');
          // Mantener el perfil basado en usuario
        },
        (serverProfile) async {
          print('✅ [AUTH] Server profile loaded, merging with user data');
          final mergedProfile = _mergeUserDataWithProfile(currentState.user, serverProfile);
          emit(AuthAuthenticated(
            currentState.user,
            fullProfile: mergedProfile,
            isProfileLoading: false,
          ));
        },
      );
    } catch (e) {
      print('❌ [AUTH] Error in background profile load: $e');
      // Mantener el perfil basado en usuario
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