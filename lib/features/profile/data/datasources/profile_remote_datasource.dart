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
          // Overrides para usar el servicio de usuarios
          extra: {'baseUrl': _userServiceBaseUrl},
        ),
      );

      print('🔍 Profile Response Status: ${response.statusCode}');
      print('🔍 Profile Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        // Verificar estructura de respuesta
        if (responseData['success'] == true && responseData['data'] != null) {
          return UserProfileModel.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
          // Si la respuesta es directa sin wrapper
          return UserProfileModel.fromJson(responseData);
        } else {
          throw ServerException('Formato de respuesta inválido para perfil de usuario');
        }
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
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return UserProfileModel.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
          return UserProfileModel.fromJson(responseData);
        } else {
          throw ServerException('Formato de respuesta inválido para actualización de avatar');
        }
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