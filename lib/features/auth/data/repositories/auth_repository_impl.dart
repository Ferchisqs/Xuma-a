// lib/features/auth/data/repositories/auth_repository_impl.dart - VERSIÓN CORREGIDA
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/services/token_manager.dart'; // 🆕 IMPORTAR TOKEN MANAGER
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_usecase.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final TokenManager _tokenManager; // 🆕 AGREGAR TOKEN MANAGER

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._tokenManager, // 🆕 INYECTAR TOKEN MANAGER
  );

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      print('🔐 [REPO] Starting login for: $email');
      
      // 🆕 VERIFICAR SI HAY UN USUARIO DIFERENTE LOGUEADO
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null && cachedUser.email.toLowerCase() != email.toLowerCase()) {
        print('🔄 [REPO] Different user detected, clearing cache...');
        await _localDataSource.clearCache();
      }
      
      // Hacer login remoto
      final user = await _remoteDataSource.login(email, password);
      
      print('✅ [REPO] Remote login successful for: ${user.email}');
      
      // 🆕 VERIFICAR QUE LOS TOKENS SE GUARDARON CORRECTAMENTE
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [REPO] Warning: No valid token after login');
        // No fallar, el TokenManager ya debería haberse encargado
      }
      
      // Cachear usuario (esto también guarda el email actual)
      await _localDataSource.cacheUser(user);
      
      print('✅ [REPO] User cached successfully');
      
      return Right(user);
    } on AuthException catch (e) {
      print('❌ [REPO] Auth error in login: ${e.message}');
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      print('❌ [REPO] Server error in login: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [REPO] Unexpected error in login: $e');
      return Left(ServerFailure('Error inesperado en login: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(RegisterParams params) async {
    try {
      print('🔐 [REPO] Starting registration for: ${params.email}');
      
      // 🆕 LIMPIAR CUALQUIER CACHE ANTERIOR ANTES DEL REGISTRO
      await _localDataSource.clearCache();
      
      // Hacer registro remoto
      final user = await _remoteDataSource.register(params);
      
      print('✅ [REPO] Remote registration successful for: ${user.email}');
      
      // 🆕 VERIFICAR TOKENS
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [REPO] Warning: No valid token after registration');
      }
      
      // Cachear usuario
      await _localDataSource.cacheUser(user);
      
      print('✅ [REPO] User cached after registration');
      
      return Right(user);
    } on AuthException catch (e) {
      print('❌ [REPO] Auth error in registration: ${e.message}');
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      print('❌ [REPO] Server error in registration: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [REPO] Unexpected error in registration: $e');
      return Left(ServerFailure('Error inesperado en registro: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithParentalConsent(RegisterParams params) async {
    try {
      print('🔐 [REPO] Starting parental consent registration for: ${params.email}');
      
      // 🆕 LIMPIAR CACHE ANTERIOR
      await _localDataSource.clearCache();
      
      // Hacer registro con consentimiento parental
      final user = await _remoteDataSource.registerWithParentalConsent(params);
      
      print('✅ [REPO] Parental consent registration successful for: ${user.email}');
      
      // 🆕 VERIFICAR TOKENS
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [REPO] Warning: No valid token after parental consent registration');
      }
      
      // Cachear usuario
      await _localDataSource.cacheUser(user);
      
      return Right(user);
    } on AuthException catch (e) {
      print('❌ [REPO] Auth error in parental consent registration: ${e.message}');
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      print('❌ [REPO] Server error in parental consent registration: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [REPO] Unexpected error in parental consent registration: $e');
      return Left(ServerFailure('Error inesperado en registro parental: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      print('🔐 [REPO] Starting logout process...');
      
      // 🆕 HACER LOGOUT REMOTO PRIMERO (OPCIONAL - SI FALLA, SEGUIMOS CON LOCAL)
      try {
        await _remoteDataSource.logout();
        print('✅ [REPO] Remote logout successful');
      } catch (e) {
        print('⚠️ [REPO] Remote logout failed, but continuing with local cleanup: $e');
        // No fallar por esto, continuar con limpieza local
      }
      
      // 🆕 LIMPIAR CACHE LOCAL Y TOKENS (CRÍTICO)
      await _localDataSource.clearCache(); // Esto también limpia tokens
      
      print('✅ [REPO] Local logout completed successfully');
      
      return const Right(null);
    } on ServerException catch (e) {
      print('⚠️ [REPO] Server error in logout, but cleaning local anyway: ${e.message}');
      
      // 🆕 AUNQUE FALLE EL SERVIDOR, LIMPIAR LOCAL
      try {
        await _localDataSource.clearCache();
        print('✅ [REPO] Local cleanup completed despite server error');
      } catch (localError) {
        print('❌ [REPO] Failed to clean local cache: $localError');
        return Left(ServerFailure('Error limpiando datos locales: $localError'));
      }
      
      return const Right(null); // Logout exitoso localmente
    } catch (e) {
      print('❌ [REPO] Unexpected error in logout: $e');
      
      // 🆕 INTENTAR LIMPIAR LOCAL COMO ÚLTIMO RECURSO
      try {
        await _localDataSource.clearCache();
        print('✅ [REPO] Emergency local cleanup completed');
        return const Right(null);
      } catch (emergencyError) {
        print('❌ [REPO] Emergency cleanup failed: $emergencyError');
        return Left(ServerFailure('Error crítico en logout: $emergencyError'));
      }
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      print('🔐 [REPO] Getting current user...');
      
      // 🆕 VERIFICAR TOKEN PRIMERO
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [REPO] No valid token, clearing cache and returning null');
        await _localDataSource.clearCache();
        return const Right(null);
      }
      
      // Intentar obtener usuario del cache
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        print('✅ [REPO] Cached user found: ${cachedUser.email}');
        
        // 🆕 VERIFICAR QUE EL TOKEN SIGUE SIENDO VÁLIDO PARA ESTE USUARIO
        try {
          final remoteUser = await _remoteDataSource.getCurrentUser();
          if (remoteUser != null && remoteUser.email == cachedUser.email) {
            print('✅ [REPO] Token validated with server');
            // Actualizar cache con datos más recientes si es necesario
            await _localDataSource.cacheUser(remoteUser);
            return Right(remoteUser);
          } else if (remoteUser == null) {
            print('⚠️ [REPO] Token invalid on server, clearing cache');
            await _localDataSource.clearCache();
            return const Right(null);
          } else {
            print('⚠️ [REPO] Token belongs to different user, clearing cache');
            await _localDataSource.clearCache();
            return const Right(null);
          }
        } catch (e) {
          print('⚠️ [REPO] Error validating token with server: $e');
          // Si no podemos validar con el servidor, usar cache por ahora
          return Right(cachedUser);
        }
      }
      
      // 🆕 NO HAY CACHE, INTENTAR OBTENER DEL SERVIDOR
      print('🔍 [REPO] No cached user, checking with server...');
      try {
        final remoteUser = await _remoteDataSource.getCurrentUser();
        if (remoteUser != null) {
          print('✅ [REPO] User found on server: ${remoteUser.email}');
          await _localDataSource.cacheUser(remoteUser);
          return Right(remoteUser);
        } else {
          print('⚠️ [REPO] No user found on server');
          return const Right(null);
        }
      } catch (e) {
        print('❌ [REPO] Error getting user from server: $e');
        return const Right(null);
      }
      
    } on CacheException catch (e) {
      print('❌ [REPO] Cache error: ${e.message}');
      return Left(CacheFailure(e.message));
    } on ServerException catch (e) {
      print('❌ [REPO] Server error: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [REPO] Unexpected error getting current user: $e');
      return Left(ServerFailure('Error obteniendo usuario actual: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      print('🔐 [REPO] Checking if user is logged in...');
      
      // 🆕 USAR TOKEN MANAGER EN LUGAR DE TOKEN LOCAL
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      final hasCachedUser = await _localDataSource.getCachedUser() != null;
      
      final isLoggedIn = hasValidToken && hasCachedUser;
      
      print('🔍 [REPO] Login status check:');
      print('   - Has valid token: $hasValidToken');
      print('   - Has cached user: $hasCachedUser');
      print('   - Is logged in: $isLoggedIn');
      
      if (!isLoggedIn && (hasValidToken || hasCachedUser)) {
        print('⚠️ [REPO] Inconsistent state detected, cleaning up...');
        await _localDataSource.clearCache();
      }
      
      return Right(isLoggedIn);
    } on CacheException catch (e) {
      print('❌ [REPO] Cache error checking login status: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ [REPO] Error checking login status: $e');
      return Left(CacheFailure('Error verificando sesión: $e'));
    }
  }

  // 🆕 MÉTODO PARA DEBUG
  Future<void> debugAuthState() async {
    try {
      print('🔍 [REPO] ========== AUTH STATE DEBUG ==========');
      
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      final cachedUser = await _localDataSource.getCachedUser();
      
      print('🔍 [REPO] Has valid token: $hasValidToken');
      print('🔍 [REPO] Has cached user: ${cachedUser != null}');
      
      if (cachedUser != null) {
        print('🔍 [REPO] Cached user: ${cachedUser.email} (ID: ${cachedUser.id})');
      }
      
      await _tokenManager.debugTokenInfo();
      
      print('🔍 [REPO] =====================================');
    } catch (e) {
      print('❌ [REPO] Error in debug: $e');
    }
  }
}