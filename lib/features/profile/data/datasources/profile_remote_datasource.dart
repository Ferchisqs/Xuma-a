// lib/features/profile/data/datasources/profile_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../model/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserProfileModel> updateUserAvatar(String userId, String avatarUrl);
}

@LazySingleton(as: ProfileRemoteDataSource)
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;
  
  // 🆕 URL específica para el servicio de usuarios
  static const String _userServiceBaseUrl = 'https://user-service-xumaa-production.up.railway.app';

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      print('🔍 [PROFILE] Obteniendo perfil para userId: $userId');
      print('🔍 [PROFILE] URL del servicio: $_userServiceBaseUrl/api/users/profile/$userId');
      
      final response = await _apiClient.get(
        '/api/users/profile/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // 🆕 IMPORTANTE: Override del baseUrl para usar el servicio de usuarios
          extra: {'baseUrl': _userServiceBaseUrl},
        ),
      );

      print('🔍 [PROFILE] Response Status: ${response.statusCode}');
      print('🔍 [PROFILE] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        Map<String, dynamic> userData;
        
        if (responseData is Map<String, dynamic>) {
          // Verificar diferentes formatos de respuesta
          if (responseData.containsKey('success') && responseData['success'] == true) {
            if (responseData.containsKey('data') && responseData['data'] != null) {
              userData = responseData['data'] as Map<String, dynamic>;
              print('✅ [PROFILE] Datos extraídos del wrapper success/data');
            } else {
              throw ServerException('No se encontraron datos del usuario en la respuesta');
            }
          } else if (responseData.containsKey('data')) {
            userData = responseData['data'] as Map<String, dynamic>;
            print('✅ [PROFILE] Datos extraídos del campo data');
          } else {
            // La respuesta es directamente los datos del usuario
            userData = responseData;
            print('✅ [PROFILE] Datos extraídos directamente de la respuesta');
          }
        } else {
          throw ServerException('Formato de respuesta inválido para perfil de usuario');
        }

        print('🔍 [PROFILE] Datos procesados: $userData');
        
        // 🆕 Validar y completar campos faltantes
        userData = _validateAndCompleteUserData(userData, userId);
        
        print('🔍 [PROFILE] Datos finales para el modelo: $userData');
        
        return UserProfileModel.fromJson(userData);
      } else {
        throw ServerException('Error obteniendo perfil: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ [PROFILE] Error obteniendo perfil: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión obteniendo perfil: $e');
    }
  }

  @override
  Future<UserProfileModel> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      print('🔍 [PROFILE] Actualizando avatar para userId: $userId');
      print('🔍 [PROFILE] Nueva URL de avatar: $avatarUrl');
      
      final response = await _apiClient.put(
        '/api/users/profile/$userId/avatar',
        data: {
          'avatarUrl': avatarUrl,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: {'baseUrl': _userServiceBaseUrl},
        ),
      );

      print('🔍 [PROFILE] Avatar Update Response Status: ${response.statusCode}');
      print('🔍 [PROFILE] Avatar Update Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        Map<String, dynamic> userData;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('success') && responseData['success'] == true) {
            if (responseData.containsKey('data') && responseData['data'] != null) {
              userData = responseData['data'] as Map<String, dynamic>;
            } else {
              throw ServerException('No se encontraron datos actualizados del usuario');
            }
          } else if (responseData.containsKey('data')) {
            userData = responseData['data'] as Map<String, dynamic>;
          } else {
            userData = responseData;
          }
        } else {
          throw ServerException('Formato de respuesta inválido para actualización de avatar');
        }
        
        // Validar y completar datos
        userData = _validateAndCompleteUserData(userData, userId);
        
        return UserProfileModel.fromJson(userData);
      } else {
        throw ServerException('Error actualizando avatar: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ [PROFILE] Error actualizando avatar: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión actualizando avatar: $e');
    }
  }

  // 🆕 Método helper para validar y completar datos del usuario
  Map<String, dynamic> _validateAndCompleteUserData(Map<String, dynamic> userData, String userId) {
    // Asegurar que tengamos el ID
    if (!userData.containsKey('id') && !userData.containsKey('userId')) {
      print('⚠️ [PROFILE] No se encontró ID de usuario, usando el userId de la petición');
      userData['id'] = userId;
    }
    
    // Usar userId si no hay id
    if (!userData.containsKey('id') && userData.containsKey('userId')) {
      userData['id'] = userData['userId'];
    }
    
    // Validar email
    if (!userData.containsKey('email') || userData['email'] == null || userData['email'].toString().trim().isEmpty) {
      print('⚠️ [PROFILE] No se encontró email válido, usando placeholder');
      userData['email'] = 'usuario@xumaa.com';
    }
    
    // Validar nombres
    if (!userData.containsKey('firstName') || userData['firstName'] == null || userData['firstName'].toString().trim().isEmpty) {
      print('⚠️ [PROFILE] No se encontró firstName válido, usando placeholder');
      userData['firstName'] = 'Usuario';
    }
    
    if (!userData.containsKey('lastName') || userData['lastName'] == null) {
      print('⚠️ [PROFILE] No se encontró lastName, usando string vacío');
      userData['lastName'] = '';
    }
    
    // Validar edad específicamente
    if (!userData.containsKey('age') || userData['age'] == null) {
      print('⚠️ [PROFILE] No se encontró age, usando 18 por defecto');
      userData['age'] = 18;
    } else {
      userData['age'] = _parseAge(userData['age']);
    }
    
    // Validar fechas
    if (!userData.containsKey('createdAt') || userData['createdAt'] == null) {
      print('⚠️ [PROFILE] No se encontró createdAt, usando fecha actual');
      userData['createdAt'] = DateTime.now().toIso8601String();
    }
    
    // Campos opcionales con defaults
    userData['ecoPoints'] = userData['ecoPoints'] ?? userData['points'] ?? 0;
    userData['achievementsCount'] = userData['achievementsCount'] ?? userData['achievements'] ?? 0;
    userData['lessonsCompleted'] = userData['lessonsCompleted'] ?? userData['lessons'] ?? 0;
    userData['level'] = userData['level'] ?? _getLevelFromAge(_parseAge(userData['age']));
    userData['needsParentalConsent'] = userData['needsParentalConsent'] ?? (_parseAge(userData['age']) < 13);
    
    return userData;
  }

  // 🆕 Helper para parsear edad de forma robusta
  int _parseAge(dynamic value) {
    if (value == null) return 18;
    
    if (value is int) {
      return (value > 0 && value <= 120) ? value : 18;
    }
    
    if (value is double) {
      final intValue = value.toInt();
      return (intValue > 0 && intValue <= 120) ? intValue : 18;
    }
    
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed > 0 && parsed <= 120) {
        return parsed;
      }
    }
    
    return 18;
  }

  // 🆕 Helper para obtener nivel basado en edad
  String _getLevelFromAge(int age) {
    if (age < 13) return 'Eco Explorer';
    if (age < 18) return 'Eco Guardian';
    if (age < 25) return 'Eco Warrior';
    return 'Eco Master';
  }
}