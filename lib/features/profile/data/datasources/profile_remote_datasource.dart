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
  
  // URL base para el servicio de usuarios
  static const String _userServiceBaseUrl = 'https://user-service-xumaa-production.up.railway.app';

  ProfileRemoteDataSourceImpl(this._apiClient);

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      print('🔍 Obteniendo perfil para userId: $userId');
      
      final response = await _apiClient.get(
        '/api/users/profile/$userId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // 🆕 AGREGAR EL OVERRIDE DE BASE URL
          extra: {'baseUrl': _userServiceBaseUrl},
        ),
      );

      print('🔍 Profile Response Status: ${response.statusCode}');
      print('🔍 Profile Response Data (Raw): ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // 🆕 MANEJO MEJORADO DE LA RESPUESTA
        Map<String, dynamic> userData;
        
        if (responseData is Map<String, dynamic>) {
          // Verificar si hay un wrapper de success
          if (responseData.containsKey('success') && responseData['success'] == true) {
            if (responseData.containsKey('data') && responseData['data'] != null) {
              userData = responseData['data'] as Map<String, dynamic>;
            } else {
              throw ServerException('No se encontraron datos del usuario en la respuesta');
            }
          } else if (responseData.containsKey('data')) {
            userData = responseData['data'] as Map<String, dynamic>;
          } else {
            // La respuesta es directamente los datos del usuario
            userData = responseData;
          }
        } else {
          throw ServerException('Formato de respuesta inválido para perfil de usuario');
        }

        print('🔍 Profile User Data (Processed): $userData');
        
        // 🆕 VALIDAR QUE TENGAMOS LOS CAMPOS BÁSICOS
        if (!userData.containsKey('id') && !userData.containsKey('userId')) {
          print('⚠️ No se encontró ID de usuario, usando el userId de la petición');
          userData['id'] = userId;
        }
        
        // 🆕 VALIDAR EMAIL
        if (!userData.containsKey('email') || userData['email'] == null) {
          print('⚠️ No se encontró email, usando placeholder');
          userData['email'] = 'usuario@xumaa.com';
        }
        
        // 🆕 VALIDAR NOMBRES
        if (!userData.containsKey('firstName') || userData['firstName'] == null) {
          print('⚠️ No se encontró firstName, usando placeholder');
          userData['firstName'] = 'Usuario';
        }
        
        if (!userData.containsKey('lastName') || userData['lastName'] == null) {
          print('⚠️ No se encontró lastName, usando placeholder');
          userData['lastName'] = '';
        }
        
        // 🆕 VALIDAR Y CORREGIR EDAD ESPECÍFICAMENTE
        if (!userData.containsKey('age') || userData['age'] == null) {
          print('⚠️ No se encontró age, usando 18 por defecto');
          userData['age'] = 18;
        } else {
          // Asegurar que la edad sea un número válido
          final ageValue = userData['age'];
          if (ageValue is String) {
            final parsedAge = int.tryParse(ageValue);
            if (parsedAge != null && parsedAge > 0 && parsedAge <= 120) {
              userData['age'] = parsedAge;
              print('✅ Edad parseada correctamente: $parsedAge');
            } else {
              print('⚠️ Edad inválida en string: $ageValue, usando 18');
              userData['age'] = 18;
            }
          } else if (ageValue is num) {
            final ageInt = ageValue.toInt();
            if (ageInt > 0 && ageInt <= 120) {
              userData['age'] = ageInt;
              print('✅ Edad válida: $ageInt');
            } else {
              print('⚠️ Edad fuera de rango: $ageInt, usando 18');
              userData['age'] = 18;
            }
          } else {
            print('⚠️ Tipo de edad no válido: ${ageValue.runtimeType}, usando 18');
            userData['age'] = 18;
          }
        }
        
        // 🆕 VALIDAR FECHAS
        if (!userData.containsKey('createdAt') || userData['createdAt'] == null) {
          print('⚠️ No se encontró createdAt, usando fecha actual');
          userData['createdAt'] = DateTime.now().toIso8601String();
        }
        
        print('🔍 Final userData before model creation: $userData');
        
        return UserProfileModel.fromJson(userData);
      } else {
        throw ServerException('Error obteniendo perfil: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ Error obteniendo perfil: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión obteniendo perfil: $e');
    }
  }

  @override
  Future<UserProfileModel> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      print('🔍 Actualizando avatar para userId: $userId');
      print('🔍 Nueva URL de avatar: $avatarUrl');
      
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

      print('🔍 Avatar Update Response Status: ${response.statusCode}');
      print('🔍 Avatar Update Response Data: ${response.data}');

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
        
        return UserProfileModel.fromJson(userData);
      } else {
        throw ServerException('Error actualizando avatar: ${response.data['message'] ?? 'Código: ${response.statusCode}'}');
      }
    } catch (e) {
      print('❌ Error actualizando avatar: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error de conexión actualizando avatar: $e');
    }
  }
}