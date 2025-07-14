// lib/features/auth/data/datasources/auth_local_datasource.dart - VERSIÓN CORREGIDA
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/token_manager.dart'; // 🆕 USAR TOKEN MANAGER
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  // 🆕 ELIMINAR MÉTODOS DE TOKEN - AHORA LOS MANEJA TOKEN MANAGER
  // Future<void> saveToken(String token);
  // Future<String?> getToken();
  // Future<void> clearToken();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _sharedPreferences;
  final TokenManager _tokenManager; // 🆕 AGREGAR TOKEN MANAGER
  
  static const String _userKey = 'cached_user';
  static const String _currentUserEmailKey = 'current_user_email'; // 🆕 PARA TRACK DEL USUARIO ACTUAL

  AuthLocalDataSourceImpl(this._sharedPreferences, this._tokenManager);

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      print('🗂️ [CACHE] Caching user: ${user.email} (ID: ${user.id})');
      
      final userJson = json.encode(user.toJson());
      await _sharedPreferences.setString(_userKey, userJson);
      
      // 🆕 GUARDAR EMAIL DEL USUARIO ACTUAL PARA VERIFICACIÓN
      await _sharedPreferences.setString(_currentUserEmailKey, user.email);
      
      print('✅ [CACHE] User cached successfully');
    } catch (e) {
      print('❌ [CACHE] Error caching user: $e');
      throw CacheException('Failed to cache user: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      print('🗂️ [CACHE] Getting cached user...');
      
      // 🆕 VERIFICAR QUE TENGAMOS TOKEN VÁLIDO PRIMERO
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      if (!hasValidToken) {
        print('⚠️ [CACHE] No valid token, clearing cached user');
        await clearCache();
        return null;
      }
      
      final userJson = _sharedPreferences.getString(_userKey);
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        final cachedUser = UserModel.fromJson(userMap);
        
        print('✅ [CACHE] Cached user found: ${cachedUser.email} (ID: ${cachedUser.id})');
        return cachedUser;
      }
      
      print('⚠️ [CACHE] No cached user found');
      return null;
    } catch (e) {
      print('❌ [CACHE] Error getting cached user: $e');
      throw CacheException('Failed to get cached user: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      print('🗂️ [CACHE] Clearing user cache...');
      
      await _sharedPreferences.remove(_userKey);
      await _sharedPreferences.remove(_currentUserEmailKey);
      
      // 🆕 TAMBIÉN LIMPIAR TOKENS
      await _tokenManager.clearAllTokens();
      
      print('✅ [CACHE] Cache cleared successfully');
    } catch (e) {
      print('❌ [CACHE] Error clearing cache: $e');
      throw CacheException('Failed to clear user cache: $e');
    }
  }

  // 🆕 MÉTODO HELPER PARA VERIFICAR CONSISTENCIA
  Future<bool> isUserConsistent(String email) async {
    try {
      final currentUserEmail = _sharedPreferences.getString(_currentUserEmailKey);
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      
      print('🔍 [CACHE] Checking user consistency:');
      print('   - Current cached email: $currentUserEmail');
      print('   - Requested email: $email');
      print('   - Has valid token: $hasValidToken');
      
      // Si no hay token válido, no es consistente
      if (!hasValidToken) {
        print('⚠️ [CACHE] No valid token - not consistent');
        return false;
      }
      
      // Si no hay email guardado, asumimos que es consistente (primer login)
      if (currentUserEmail == null) {
        print('✅ [CACHE] No cached email - assuming consistent');
        return true;
      }
      
      // Verificar que el email coincida
      final isConsistent = currentUserEmail.toLowerCase() == email.toLowerCase();
      print('${isConsistent ? "✅" : "❌"} [CACHE] User consistency: $isConsistent');
      
      return isConsistent;
    } catch (e) {
      print('❌ [CACHE] Error checking user consistency: $e');
      return false;
    }
  }

  // 🆕 MÉTODO PARA CAMBIAR DE USUARIO (LOGOUT + LOGIN NUEVO)
  Future<void> switchUser(String newEmail) async {
    try {
      print('🔄 [CACHE] Switching user to: $newEmail');
      
      // Limpiar cache anterior
      await clearCache();
      
      // Actualizar email actual
      await _sharedPreferences.setString(_currentUserEmailKey, newEmail);
      
      print('✅ [CACHE] User switched successfully');
    } catch (e) {
      print('❌ [CACHE] Error switching user: $e');
      throw CacheException('Failed to switch user: $e');
    }
  }

  // 🆕 MÉTODO PARA DEBUG
  Future<void> debugCacheState() async {
    try {
      print('🔍 [CACHE] ========== CACHE DEBUG ==========');
      
      final userJson = _sharedPreferences.getString(_userKey);
      final currentEmail = _sharedPreferences.getString(_currentUserEmailKey);
      final hasValidToken = await _tokenManager.hasValidAccessToken();
      
      print('🔍 [CACHE] Current cached email: $currentEmail');
      print('🔍 [CACHE] Has cached user data: ${userJson != null}');
      print('🔍 [CACHE] Has valid token: $hasValidToken');
      
      if (userJson != null) {
        try {
          final userMap = json.decode(userJson) as Map<String, dynamic>;
          print('🔍 [CACHE] Cached user email: ${userMap['email']}');
          print('🔍 [CACHE] Cached user ID: ${userMap['id']}');
        } catch (e) {
          print('❌ [CACHE] Error parsing cached user: $e');
        }
      }
      
      await _tokenManager.debugTokenInfo();
      
      print('🔍 [CACHE] ================================');
    } catch (e) {
      print('❌ [CACHE] Error in debug: $e');
    }
  }
}