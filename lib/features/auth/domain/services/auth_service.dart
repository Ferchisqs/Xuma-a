// lib/features/auth/domain/services/auth_service.dart
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/auth/domain/usecases/register_usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';

@lazySingleton
class AuthService {
  final AuthRepository _authRepository;
  final AuthRemoteDataSource _remoteDataSource;

  AuthService(this._authRepository, this._remoteDataSource);

  // ==================== MÉTODOS BÁSICOS ====================
  
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    return await _authRepository.login(email, password);
  }

  Future<Either<Failure, void>> logout() async {
    return await _authRepository.logout();
  }

  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }

  Future<Either<Failure, bool>> isLoggedIn() async {
    return await _authRepository.isLoggedIn();
  }

  Future<Either<Failure, UserEntity>> registerWithParentalConsent(RegisterParams params) async {
    try {
      return await _authRepository.registerWithParentalConsent(params);
    } catch (e) {
      return Left(ServerFailure('Error en registro con consentimiento parental: $e'));
    }
  }

  // ==================== GESTIÓN DE TOKENS ====================
  
  Future<Either<Failure, Map<String, dynamic>>> validateToken(String token) async {
    try {
      final result = await _remoteDataSource.validateToken(token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error validando token: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> refreshToken(String refreshToken) async {
    try {
      final result = await _remoteDataSource.refreshToken(refreshToken);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error renovando token: $e'));
    }
  }

  Future<Either<Failure, void>> revokeToken(String token) async {
    try {
      await _remoteDataSource.revokeToken(token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error revocando token: $e'));
    }
  }

  Future<Either<Failure, bool>> hasValidToken() async {
    try {
      final currentUserResult = await getCurrentUser();
      
      return currentUserResult.fold(
        (failure) => const Right(false),
        (user) => Right(user != null),
      );
    } catch (e) {
      return Left(ServerFailure('Error verificando token: $e'));
    }
  }

  Future<Either<Failure, bool>> isTokenValid() async {
    try {
      final result = await _remoteDataSource.getCurrentUser();
      return Right(result != null);
    } catch (e) {
      return const Right(false);
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> refreshUserToken(String refreshToken) async {
    try {
      final result = await _remoteDataSource.refreshToken(refreshToken);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error renovando token: $e'));
    }
  }

  Future<Either<Failure, bool>> autoRefreshToken() async {
    try {
      final currentUserResult = await getCurrentUser();
      
      return currentUserResult.fold(
        (failure) => const Right(false),
        (user) => Right(user != null),
      );
    } catch (e) {
      return Left(ServerFailure('Error en auto-refresh: $e'));
    }
  }

  // ==================== CONSENTIMIENTO PARENTAL ====================
  
  Future<Either<Failure, Map<String, dynamic>>> requestParentalConsent({
    required String minorUserId,
    required String parentEmail,
    required String parentName,
    required String relationship,
  }) async {
    try {
      final result = await _remoteDataSource.requestParentalConsent(
        minorUserId: minorUserId,
        parentEmail: parentEmail,
        parentName: parentName,
        relationship: relationship,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error solicitando consentimiento parental: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> approveParentalConsent(String token) async {
    try {
      final result = await _remoteDataSource.approveParentalConsent(token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error aprobando consentimiento parental: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getParentalConsentStatus(String userId) async {
    try {
      final result = await _remoteDataSource.getParentalConsentStatus(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error obteniendo estado de consentimiento: $e'));
    }
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================
  
  Future<Either<Failure, void>> sendEmailVerification(String userId) async {
    try {
      await _remoteDataSource.sendEmailVerification(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error enviando verificación de email: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> verifyEmail(String token) async {
    try {
      final result = await _remoteDataSource.verifyEmail(token);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error verificando email: $e'));
    }
  }

  Future<Either<Failure, void>> resendEmailVerification(String email) async {
    try {
      await _remoteDataSource.resendEmailVerification(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error reenviando verificación: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getVerificationStatus(String userId) async {
    try {
      final result = await _remoteDataSource.getVerificationStatus(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Error obteniendo estado de verificación: $e'));
    }
  }

  // ==================== MÉTODOS HELPER ====================
  
  Future<Either<Failure, bool>> needsEmailVerification(String userId) async {
    final result = await getVerificationStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(!(status['isVerified'] ?? false)),
    );
  }

  Future<Either<Failure, bool>> needsParentalConsent(String userId) async {
    final result = await getParentalConsentStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(status['requiresConsent'] ?? false),
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> getFullAuthStatus(String userId) async {
    try {
      final verificationResult = await getVerificationStatus(userId);
      final consentResult = await getParentalConsentStatus(userId);
      
      return verificationResult.fold(
        (failure) => Left(failure),
        (verificationStatus) => consentResult.fold(
          (failure) => Left(failure),
          (consentStatus) => Right({
            'emailVerification': verificationStatus,
            'parentalConsent': consentStatus,
            'isFullyAuthenticated': (verificationStatus['isVerified'] ?? false) && 
                                !(consentStatus['requiresConsent'] ?? false),
          }),
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Error obteniendo estado completo: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getCompleteAuthStatus(String userId) async {
    try {
      final verificationResult = await getVerificationStatus(userId);
      final consentResult = await getParentalConsentStatus(userId);
      final tokenValidResult = await hasValidToken();
      
      return verificationResult.fold(
        (failure) => Left(failure),
        (verificationStatus) => consentResult.fold(
          (failure) => Left(failure),
          (consentStatus) => tokenValidResult.fold(
            (failure) => Left(failure),
            (hasToken) => Right({
              'hasValidToken': hasToken,
              'emailVerification': verificationStatus,
              'parentalConsent': consentStatus,
              'isFullyAuthenticated': hasToken && 
                                    (verificationStatus['isVerified'] ?? false) && 
                                    !(consentStatus['requiresConsent'] ?? false),
            }),
          ),
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Error obteniendo estado completo: $e'));
    }
  }

  Future<Either<Failure, bool>> canUserAccess(String userId) async {
    final statusResult = await getCompleteAuthStatus(userId);
    
    return statusResult.fold(
      (failure) => Left(failure),
      (status) => Right(status['isFullyAuthenticated'] ?? false),
    );
  }

  Future<Either<Failure, bool>> activelyNeedsParentalConsent(String userId) async {
    final result = await getParentalConsentStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(status['requiresConsent'] ?? false),
    );
  }

  Future<Either<Failure, bool>> activelyNeedsEmailVerification(String userId) async {
    final result = await getVerificationStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(!(status['isVerified'] ?? false)),
    );
  }
}