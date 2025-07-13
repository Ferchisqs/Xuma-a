// lib/features/auth/domain/services/auth_service.dart
import 'package:injectable/injectable.dart';
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
  
  /// Verifica si el usuario necesita verificar su email
  Future<Either<Failure, bool>> needsEmailVerification(String userId) async {
    final result = await getVerificationStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(!(status['isVerified'] ?? false)),
    );
  }

  /// Verifica si el usuario necesita consentimiento parental
  Future<Either<Failure, bool>> needsParentalConsent(String userId) async {
    final result = await getParentalConsentStatus(userId);
    return result.fold(
      (failure) => Left(failure),
      (status) => Right(status['requiresConsent'] ?? false),
    );
  }

  /// Obtiene el estado completo de autenticación del usuario
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
}