// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/usecases/register_usecase.dart';

abstract class AuthRemoteDataSource {
  // ==================== AUTENTICACIÓN BÁSICA ====================
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(RegisterParams params);
  Future<UserModel> registerWithParentalConsent(RegisterParams params);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  
  // ==================== GESTIÓN DE TOKENS ====================
  Future<Map<String, dynamic>> validateToken(String token);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> revokeToken(String token);
  
  // ==================== CONSENTIMIENTO PARENTAL ====================
  Future<Map<String, dynamic>> requestParentalConsent({
    required String minorUserId,
    required String parentEmail,
    required String parentName,
    required String relationship,
  });
  Future<Map<String, dynamic>> approveParentalConsent(String token);
  Future<Map<String, dynamic>> getParentalConsentStatus(String userId);
  
  // ==================== VERIFICACIÓN DE EMAIL ====================
  Future<void> sendEmailVerification(String userId);
  Future<Map<String, dynamic>> verifyEmail(String token);
  Future<void> resendEmailVerification(String email);
  Future<Map<String, dynamic>> getVerificationStatus(String userId);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  // ==================== AUTENTICACIÓN BÁSICA ====================
  
  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'] ?? response.data;
        return UserModel.fromJson(userData);
      } else {
        throw ServerException('Error en el login: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en login: $e');
    }
  }

  @override
  Future<UserModel> register(RegisterParams params) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': params.email,
          'password': params.password,
          'confirmPassword': params.confirmPassword,
          'age': params.age,
          'firstName': params.firstName,
          'lastName': params.lastName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = response.data['user'] ?? response.data;
        return UserModel.fromJson(userData);
      } else {
        throw ServerException('Error en el registro: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en registro: $e');
    }
  }

  @override
  Future<UserModel> registerWithParentalConsent(RegisterParams params) async {
    try {
      final requestData = {
        'email': params.email,
        'password': params.password,
        'confirmPassword': params.confirmPassword,
        'age': params.age,
        'firstName': params.firstName,
        'lastName': params.lastName,
        'needsParentalConsent': true,
      };

      // Agregar información parental si existe
      if (params.parentalInfo != null) {
        requestData.addAll({
          'guardianName': params.parentalInfo!.guardianName,
          'relationship': params.parentalInfo!.relationship,
          'guardianEmail': params.parentalInfo!.guardianEmail,
        });
      }

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = response.data['user'] ?? response.data;
        
        // Si es menor, solicitar consentimiento parental
        if (params.needsParentalConsent && params.parentalInfo != null) {
          await requestParentalConsent(
            minorUserId: userData['id'],
            parentEmail: params.parentalInfo!.guardianEmail,
            parentName: params.parentalInfo!.guardianName,
            relationship: params.parentalInfo!.relationship,
          );
        }
        
        return UserModel.fromJson(userData);
      } else {
        throw ServerException('Error en registro con consentimiento parental: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en registro parental: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.logout,
        data: {
          'logoutFromAllDevices': false,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Error al cerrar sesión: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en logout: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // Intentar validar token actual primero
      final tokenResponse = await _apiClient.post(ApiEndpoints.validateToken);
      
      if (tokenResponse.statusCode == 200) {
        final userData = tokenResponse.data['user'] ?? tokenResponse.data;
        return UserModel.fromJson(userData);
      } else if (tokenResponse.statusCode == 401) {
        return null; // Token inválido o expirado
      } else {
        throw ServerException('Error al obtener usuario actual: ${tokenResponse.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      return null; // Si hay error de conexión, considerar no autenticado
    }
  }

  // ==================== GESTIÓN DE TOKENS ====================
  
  @override
  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.validateToken,
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Token inválido: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error validando token: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Error renovando token: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión renovando token: $e');
    }
  }

  @override
  Future<void> revokeToken(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.revokeToken,
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        throw ServerException('Error revocando token: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión revocando token: $e');
    }
  }

  // ==================== CONSENTIMIENTO PARENTAL ====================
  
  @override
  Future<Map<String, dynamic>> requestParentalConsent({
    required String minorUserId,
    required String parentEmail,
    required String parentName,
    required String relationship,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.parentalConsentRequest,
        data: {
          'minorUserId': minorUserId,
          'parentEmail': parentEmail,
          'parentName': parentName,
          'relationship': relationship,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ServerException('Error solicitando consentimiento parental: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en consentimiento parental: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> approveParentalConsent(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.getParentalConsentApprove(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Error aprobando consentimiento parental: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión aprobando consentimiento: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getParentalConsentStatus(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getParentalConsentStatus(userId),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Error obteniendo estado de consentimiento: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión obteniendo estado: $e');
    }
  }

  // ==================== VERIFICACIÓN DE EMAIL ====================
  
  @override
  Future<void> sendEmailVerification(String userId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.sendVerification,
        data: {'userId': userId},
      );

      if (response.statusCode != 200) {
        throw ServerException('Error enviando verificación de email: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión enviando verificación: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.getVerifyEmail(token),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Error verificando email: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión verificando email: $e');
    }
  }

  @override
  Future<void> resendEmailVerification(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resendVerification,
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException('Error reenviando verificación: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión reenviando verificación: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getVerificationStatus(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.getVerificationStatus(userId),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException('Error obteniendo estado de verificación: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión obteniendo estado: $e');
    }
  }
}