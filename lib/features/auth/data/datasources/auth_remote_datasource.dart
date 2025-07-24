// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_manager.dart';
import '../models/user_model.dart';
import '../../domain/usecases/register_usecase.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(RegisterParams params);
  Future<UserModel> registerWithParentalConsent(RegisterParams params);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  
  Future<Map<String, dynamic>> validateToken(String token);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> revokeToken(String token);
  
  Future<Map<String, dynamic>> requestParentalConsent({
    required String minorUserId,
    required String parentEmail,
    required String parentName,
    required String relationship,
  });
  Future<Map<String, dynamic>> approveParentalConsent(String token);
  Future<Map<String, dynamic>> getParentalConsentStatus(String userId);
  
  Future<void> sendEmailVerification(String userId);
  Future<Map<String, dynamic>> verifyEmail(String token);
  Future<void> resendEmailVerification(String email);
  Future<Map<String, dynamic>> getVerificationStatus(String userId);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  AuthRemoteDataSourceImpl(this._apiClient, this._tokenManager);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      print('🔍 [AUTH] Starting login for: $email');
      
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('🔍 [AUTH] Login Response Status: ${response.statusCode}');
      print('🔍 [AUTH] Login Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] != true) {
          throw ServerException('Login no exitoso: ${responseData['message'] ?? 'Error desconocido'}');
        }
        
        try {
          await _tokenManager.saveTokensFromResponse(responseData);
          print('✅ [AUTH] Tokens saved after successful login');
          
          final savedToken = await _tokenManager.getAccessToken();
          if (savedToken == null) {
            throw ServerException('Error: Token no se guardó correctamente');
          }
          
          await _tokenManager.debugTokenInfo();
        } catch (e) {
          print('❌ [AUTH] CRITICAL ERROR: Could not save tokens: $e');
          throw ServerException('Error guardando tokens de sesión: $e');
        }
        
        Map<String, dynamic> userData = {};
        
        if (responseData['data'] != null) {
          final data = responseData['data'];
          
          if (data['user'] != null) {
            userData = Map<String, dynamic>.from(data['user']);
            userData['userId'] = data['userId'];
            userData['id'] = data['userId'];
          } else {
            userData = Map<String, dynamic>.from(data);
          }
        } else {
          throw ServerException('Datos de usuario no encontrados en la respuesta');
        }
        
        print('🔍 [AUTH] Final user data for LOGIN model: $userData');
        
        return _createUserModelFromApiData(userData, isLogin: true);
      } else {
        throw ServerException('Error en el login: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ [AUTH] Login Error Details: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en login: $e');
    }
  }

  @override
  Future<UserModel> register(RegisterParams params) async {
    try {
      print('🔍 [AUTH] Starting registration for: ${params.email}');
      
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

      print('🔍 [AUTH] Register Response Status: ${response.statusCode}');
      print('🔍 [AUTH] Register Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['success'] != true) {
          throw ServerException('Registro no exitoso: ${responseData['message'] ?? 'Error desconocido'}');
        }
        
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw ServerException('Datos de usuario no encontrados en la respuesta de registro');
        }
        
        final requiresEmailVerification = data['requiresEmailVerification'] ?? false;
        final accountStatus = data['accountStatus'] ?? '';
        
        print('🔍 [AUTH] Registration analysis:');
        print('   - Requires email verification: $requiresEmailVerification');
        print('   - Account status: $accountStatus');
        
        if (requiresEmailVerification || accountStatus == 'pending_verification') {
          print('📧 [AUTH] Registration successful but requires email verification');
          return _createUserModelFromRegistrationData(data, params, needsEmailVerification: true);
        }
        
        try {
          await _tokenManager.saveTokensFromResponse(responseData);
          
          final savedToken = await _tokenManager.getAccessToken();
          if (savedToken == null) {
            throw ServerException('Error: Token de registro no se guardó correctamente');
          }
          
          print('✅ [AUTH] Registration tokens saved successfully');
        } catch (e) {
          print('❌ [AUTH] CRITICAL ERROR: Could not save registration tokens: $e');
          throw ServerException('Error guardando tokens de registro: $e');
        }
        
        return _createUserModelFromRegistrationData(data, params, needsEmailVerification: false);
        
      } else {
        throw ServerException('Error en el registro: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ [AUTH] Register Error Details: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en registro: $e');
    }
  }

  @override
  Future<UserModel> registerWithParentalConsent(RegisterParams params) async {
    try {
      print('🔍 [AUTH] Starting parental consent registration for: ${params.email}');
      
      final requestData = {
        'email': params.email,
        'password': params.password,
        'confirmPassword': params.confirmPassword,
        'age': params.age,
        'firstName': params.firstName,
        'lastName': params.lastName,
        'needsParentalConsent': true,
      };

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

      print('🔍 [AUTH] Parental Register Response Status: ${response.statusCode}');
      print('🔍 [AUTH] Parental Register Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        if (responseData['success'] != true) {
          throw ServerException('Registro con consentimiento parental no exitoso: ${responseData['message'] ?? 'Error desconocido'}');
        }
        
        final data = responseData['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw ServerException('Datos de usuario no encontrados en la respuesta de registro parental');
        }
        
        final requiresEmailVerification = data['requiresEmailVerification'] ?? false;
        final accountStatus = data['accountStatus'] ?? '';
        
        if (!requiresEmailVerification && accountStatus != 'pending_verification') {
          try {
            await _tokenManager.saveTokensFromResponse(responseData);
            print('✅ [AUTH] Parental registration tokens saved successfully');
          } catch (e) {
            print('⚠️ [AUTH] Warning: Could not save parental registration tokens: $e');
          }
        }
        
        final userModel = _createUserModelFromRegistrationData(
          data, 
          params, 
          needsEmailVerification: requiresEmailVerification || accountStatus == 'pending_verification'
        );
        
        if (params.needsParentalConsent && params.parentalInfo != null) {
          try {
            await requestParentalConsent(
              minorUserId: userModel.id,
              parentEmail: params.parentalInfo!.guardianEmail,
              parentName: params.parentalInfo!.guardianName,
              relationship: params.parentalInfo!.relationship,
            );
            print('✅ [AUTH] Parental consent request sent successfully');
          } catch (e) {
            print('⚠️ [AUTH] Warning: Could not send parental consent request: $e');
          }
        }
        
        return userModel;
      } else {
        throw ServerException('Error en registro con consentimiento parental: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ [AUTH] Parental Register Error Details: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión en registro parental: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      print('🔍 [AUTH] Sending logout request...');
      
      final response = await _apiClient.post(
        ApiEndpoints.logout,
        data: {
          'logoutFromAllDevices': false,
        },
      );

      print('🔍 [AUTH] Logout Response Status: ${response.statusCode}');
      print('🔍 [AUTH] Logout Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['success'] == true) {
          print('✅ [AUTH] Logout successful: ${responseData['message']}');
        } else {
          print('⚠️ [AUTH] Logout response not marked as success but status 200');
        }
      } else if (response.statusCode == 401) {
        print('⚠️ [AUTH] Token already invalid/expired during logout - proceeding anyway');
      } else {
        throw ServerException('Error al cerrar sesión: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
      
      await _tokenManager.clearAllTokens();
      print('✅ [AUTH] All tokens cleared after logout');
      
    } catch (e) {
      print('❌ [AUTH] Logout Error: $e');
      
      await _tokenManager.clearAllTokens();
      print('✅ [AUTH] Tokens cleared despite logout error');
      
      if (e is ServerException) {
        if (e.message.contains('401') || e.message.contains('inválido') || e.message.contains('expirado')) {
          print('✅ [AUTH] Token already invalid, logout successful locally');
          return;
        }
        rethrow;
      }
      throw ServerException('Error de conexión en logout: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      print('🔍 [AUTH] Getting current user...');
      
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [AUTH] No valid access token available');
        return null;
      }
      
      final tokenResponse = await _apiClient.post(ApiEndpoints.validateToken);
      
      print('🔍 [AUTH] Validate Token Response Status: ${tokenResponse.statusCode}');
      print('🔍 [AUTH] Validate Token Response Data: ${tokenResponse.data}');
      
      if (tokenResponse.statusCode == 200) {
        final responseData = tokenResponse.data;
        
        if (responseData['success'] == true && responseData['isValid'] == true) {
          final userData = responseData['user'] ?? responseData['data'];
          if (userData != null) {
            return _createUserModelFromApiData(userData, isLogin: true);
          } else {
            throw ServerException('Datos de usuario no encontrados en validación de token');
          }
        } else {
          print('⚠️ [AUTH] Token validation failed: ${responseData['error']}');
          await _tokenManager.clearAllTokens();
          return null;
        }
      } else if (tokenResponse.statusCode == 401) {
        print('⚠️ [AUTH] Token invalid or expired');
        await _tokenManager.clearAllTokens();
        return null;
      } else {
        throw ServerException('Error al obtener usuario actual: ${tokenResponse.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      print('❌ [AUTH] Get Current User Error: $e');
      if (e is ServerException) rethrow;
      return null;
    }
  }

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
        try {
          await _tokenManager.saveTokensFromResponse(response.data);
          print('✅ [AUTH] New tokens saved after refresh');
        } catch (e) {
          print('⚠️ [AUTH] Warning: Could not save refreshed tokens: $e');
        }
        
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

      if (response.statusCode == 200) {
        await _tokenManager.clearAllTokens();
        print('✅ [AUTH] Tokens cleared after revocation');
      } else {
        throw ServerException('Error revocando token: ${response.data['message'] ?? 'Error desconocido'}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión revocando token: $e');
    }
  }

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

  UserModel _createUserModelFromApiData(Map<String, dynamic> data, {bool isLogin = false}) {
    try {
      print('🔍 [AUTH] Creating UserModel from data (isLogin: $isLogin): $data');
      
      final String userId = (data['userId'] ?? data['id'] ?? 'temp_id').toString();
      final String email = (data['email'] ?? '').toString();
      final String firstName = (data['firstName'] ?? data['first_name'] ?? '').toString();
      final String lastName = (data['lastName'] ?? data['last_name'] ?? '').toString();
      
      int age;
      if (data['age'] != null) {
        age = int.tryParse(data['age'].toString()) ?? 18;
      } else {
        age = isLogin ? 25 : 18;
      }
      
      final String? profilePicture = data['profilePicture']?.toString() ?? 
                                  data['profile_picture']?.toString();
      
      final bool isEmailVerified = data['isVerified'] ?? 
                                 data['is_verified'] ?? 
                                 data['emailVerified'] ?? 
                                 data['email_verified'] ??
                                 data['verified'] ??
                                 (isLogin ? true : false);
      
      DateTime createdAt;
      try {
        if (data['createdAt'] != null) {
          createdAt = DateTime.parse(data['createdAt'].toString());
        } else if (data['created_at'] != null) {
          createdAt = DateTime.parse(data['created_at'].toString());
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        print('⚠️ [AUTH] Error parsing createdAt: $e');
        createdAt = DateTime.now();
      }
      
      DateTime? lastLogin;
      try {
        if (data['lastLogin'] != null) {
          lastLogin = DateTime.parse(data['lastLogin'].toString());
        } else if (data['last_login'] != null) {
          lastLogin = DateTime.parse(data['last_login'].toString());
        } else if (isLogin) {
          lastLogin = DateTime.now();
        }
      } catch (e) {
        print('⚠️ [AUTH] Error parsing lastLogin: $e');
        lastLogin = isLogin ? DateTime.now() : null;
      }
      
      final bool needsParentalConsent = data['requiresParentalConsent'] ?? 
                                     data['requires_parental_consent'] ?? 
                                     data['needsParentalConsent'] ??
                                     (age < 13);

      print('🔍 [AUTH] UserModel data summary:');
      print('  - Context: ${isLogin ? "LOGIN" : "API_DATA"}');
      print('  - ID: $userId');
      print('  - Email: $email');
      print('  - Name: $firstName $lastName');
      print('  - Age: $age');
      print('  - Email Verified: $isEmailVerified');
      print('  - Needs parental consent: $needsParentalConsent');
      
      return UserModel(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        age: age,
        profilePicture: profilePicture,
        createdAt: createdAt,
        lastLogin: lastLogin,
        needsParentalConsent: needsParentalConsent,
        isEmailVerified: isEmailVerified,
      );
      
    } catch (e) {
      print('❌ [AUTH] Error creating UserModel: $e');
      print('📄 [AUTH] Original data: $data');
      
      return UserModel(
        id: (data['userId'] ?? data['id'] ?? 'error_id').toString(),
        email: (data['email'] ?? 'unknown@email.com').toString(),
        firstName: (data['firstName'] ?? 'Usuario').toString(),
        lastName: (data['lastName'] ?? '').toString(),
        age: isLogin ? 25 : 18,
        profilePicture: null,
        createdAt: DateTime.now(),
        lastLogin: isLogin ? DateTime.now() : null,
        needsParentalConsent: false,
        isEmailVerified: isLogin,
      );
    }
  }

  UserModel _createUserModelFromRegistrationData(
    Map<String, dynamic> data, 
    RegisterParams params, {
    bool needsEmailVerification = false,
  }) {
    try {
      print('🔍 [AUTH] Creating UserModel from registration data:');
      print('   - Needs email verification: $needsEmailVerification');
      print('   - Server data: $data');
      print('   - Registration params: firstName=${params.firstName}, lastName=${params.lastName}, age=${params.age}');
      
      final String userId = (data['userId'] ?? data['id'] ?? 'temp_id').toString();
      final String email = (data['email'] ?? params.email).toString();
      final String firstName = params.firstName;
      final String lastName = params.lastName;
      final int age = params.age;
      final bool isEmailVerified = !needsEmailVerification;
      
      DateTime createdAt;
      try {
        if (data['createdAt'] != null) {
          createdAt = DateTime.parse(data['createdAt'].toString());
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        print('⚠️ [AUTH] Error parsing createdAt, using current time: $e');
        createdAt = DateTime.now();
      }
      
      final bool needsParentalConsent = data['requiresParentalConsent'] ?? (age < 13);

      print('🔍 [AUTH] UserModel data summary (REGISTRATION):');
      print('  - ID: $userId');
      print('  - Email: $email');
      print('  - Name: $firstName $lastName');
      print('  - Age: $age');
      print('  - Email Verified: $isEmailVerified');
      print('  - Needs email verification: $needsEmailVerification');
      print('  - Needs parental consent: $needsParentalConsent');
      
      return UserModel(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        age: age,
        profilePicture: null,
        createdAt: createdAt,
        lastLogin: null,
        needsParentalConsent: needsParentalConsent,
        isEmailVerified: isEmailVerified,
      );
      
    } catch (e) {
      print('❌ [AUTH] Error creating UserModel from registration: $e');
      print('📄 [AUTH] Registration data: $data');
      
      return UserModel(
        id: (data['userId'] ?? data['id'] ?? 'temp_registration_id').toString(),
        email: params.email,
        firstName: params.firstName,
        lastName: params.lastName,
        age: params.age,
        profilePicture: null,
        createdAt: DateTime.now(),
        lastLogin: null,
        needsParentalConsent: params.age < 13,
        isEmailVerified: !needsEmailVerification,
      );
    }
  }
}