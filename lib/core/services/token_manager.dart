// lib/core/services/token_manager.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';


@lazySingleton
class TokenManager {
  final SharedPreferences _prefs;
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';

  TokenManager(this._prefs);

  // ==================== SAVE TOKENS ====================
  
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? userId,
  }) async {
    try {
      print('🔐 [TOKEN] Saving tokens...');
      print('🔐 [TOKEN] Access Token: ${accessToken.substring(0, 20)}...');
      print('🔐 [TOKEN] Refresh Token: ${refreshToken?.substring(0, 20) ?? 'null'}...');
      print('🔐 [TOKEN] Expires At: $expiresAt');
      print('🔐 [TOKEN] User ID: $userId');
      
      await _prefs.setString(_accessTokenKey, accessToken);
      
      if (refreshToken != null) {
        await _prefs.setString(_refreshTokenKey, refreshToken);
      }
      
      if (expiresAt != null) {
        await _prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());
      }
      
      if (userId != null) {
        await _prefs.setString(_userIdKey, userId);
      }
      
      print('✅ [TOKEN] Tokens saved successfully');
    } catch (e) {
      print('❌ [TOKEN] Error saving tokens: $e');
      throw Exception('Failed to save tokens: $e');
    }
  }
  // ==================== MÉTODO ORIGINAL saveTokensFromResponse ====================
Future<void> saveTokensFromResponse(Map<String, dynamic> response) async {
  try {
    print('🔐 [TOKEN] Extracting tokens from response...');
    print('🔐 [TOKEN] Response keys: ${response.keys.toList()}');
    
    String? accessToken;
    String? refreshToken;
    String? userId;
    DateTime? expiresAt;
    
    // Buscar access token en diferentes campos
    accessToken = response['token'] ?? 
                 response['accessToken'] ?? 
                 response['access_token'];
    
    // Buscar refresh token
    refreshToken = response['refreshToken'] ?? 
                  response['refresh_token'];
    
    // Buscar user ID
    userId = response['userId']?.toString() ?? 
            response['user_id']?.toString() ??
            response['id']?.toString();
    
    // Si hay datos anidados, buscar ahí también
    if (response.containsKey('data')) {
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        accessToken ??= data['token'] ?? data['accessToken'] ?? data['access_token'];
        refreshToken ??= data['refreshToken'] ?? data['refresh_token'];
        userId ??= data['userId']?.toString() ?? data['user_id']?.toString() ?? data['id']?.toString();
      }
    }
    
    // Si hay tokens anidados
    if (response.containsKey('tokens')) {
      final tokens = response['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        accessToken ??= tokens['accessToken'] ?? tokens['access_token'];
        refreshToken ??= tokens['refreshToken'] ?? tokens['refresh_token'];
      }
    }
    
    // Calcular fecha de expiración (por defecto 1 hora)
    if (response.containsKey('expiresIn')) {
      final expiresIn = response['expiresIn'];
      if (expiresIn is int) {
        expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      } else if (expiresIn is String) {
        final seconds = int.tryParse(expiresIn);
        if (seconds != null) {
          expiresAt = DateTime.now().add(Duration(seconds: seconds));
        }
      }
    } else {
      // Por defecto, 24 horas de vida (más tiempo para evitar expiraciones frecuentes)
      expiresAt = DateTime.now().add(const Duration(hours: 24));
    }
    
    if (accessToken != null && accessToken.isNotEmpty) {
      await saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        userId: userId,
      );
      
      // Verificar que se guardó correctamente
      final verifyToken = await getAccessToken();
      if (verifyToken == null) {
        throw Exception('Token no se guardó correctamente en SharedPreferences');
      }
      
      print('✅ [TOKEN] Tokens extracted and saved successfully');
      print('✅ [TOKEN] Token verification passed');
    } else {
      print('⚠️ [TOKEN] No access token found in response');
      print('🔍 [TOKEN] Response structure: ${response.toString()}');
      throw Exception('No access token found in server response');
    }
  } catch (e) {
    print('❌ [TOKEN] Error extracting tokens from response: $e');
    throw Exception('Failed to extract tokens: $e');
  }
}

 Future<bool> saveTokensFromResponseOptional(Map<String, dynamic> response) async {
  try {
    print('🔐 [TOKEN] Extracting tokens from response (optional)...');
    print('🔐 [TOKEN] Response keys: ${response.keys.toList()}');
    
    String? accessToken;
    String? refreshToken;
    String? userId;
    DateTime? expiresAt;
    
    // Buscar access token en diferentes campos
    accessToken = response['token'] ?? 
                 response['accessToken'] ?? 
                 response['access_token'];
    
    // Buscar refresh token
    refreshToken = response['refreshToken'] ?? 
                  response['refresh_token'];
    
    // Buscar user ID
    userId = response['userId']?.toString() ?? 
            response['user_id']?.toString() ??
            response['id']?.toString();
    
    // Si hay datos anidados, buscar ahí también
    if (response.containsKey('data')) {
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        accessToken ??= data['token'] ?? data['accessToken'] ?? data['access_token'];
        refreshToken ??= data['refreshToken'] ?? data['refresh_token'];
        userId ??= data['userId']?.toString() ?? data['user_id']?.toString() ?? data['id']?.toString();
      }
    }
    
    // Si hay tokens anidados
    if (response.containsKey('tokens')) {
      final tokens = response['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        accessToken ??= tokens['accessToken'] ?? tokens['access_token'];
        refreshToken ??= tokens['refreshToken'] ?? tokens['refresh_token'];
      }
    }
    
    // SI NO HAY ACCESS TOKEN, NO ES UN ERROR - ES OPCIONAL
    if (accessToken == null || accessToken.isEmpty) {
      print('ℹ️ [TOKEN] No access token found in response - this is OK for some registration flows');
      return false; // Indica que no se guardaron tokens, pero no es error
    }
    
    // Calcular fecha de expiración (por defecto 1 hora)
    if (response.containsKey('expiresIn')) {
      final expiresIn = response['expiresIn'];
      if (expiresIn is int) {
        expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      } else if (expiresIn is String) {
        final seconds = int.tryParse(expiresIn);
        if (seconds != null) {
          expiresAt = DateTime.now().add(Duration(seconds: seconds));
        }
      }
    } else {
      // Por defecto, 24 horas de vida
      expiresAt = DateTime.now().add(const Duration(hours: 24));
    }
    
    // Guardar tokens si los encontramos
    await saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
    );
    
    // Verificar que se guardó correctamente
    final verifyToken = await getAccessToken();
    if (verifyToken == null) {
      throw Exception('Token no se guardó correctamente en SharedPreferences');
    }
    
    print('✅ [TOKEN] Tokens extracted and saved successfully');
    return true; // Indica que se guardaron tokens exitosamente
    
  } catch (e) {
    print('❌ [TOKEN] Error extracting tokens from response: $e');
    throw Exception('Failed to extract tokens: $e');
  }
}


// 🆕 MÉTODO PARA VERIFICAR SI UNA RESPUESTA CONTIENE TOKENS
bool responseHasTokens(Map<String, dynamic> response) {
  // Verificar en el nivel principal
  if (response.containsKey('token') || 
      response.containsKey('accessToken') || 
      response.containsKey('access_token')) {
    return true;
  }
  
  // Verificar en data
  if (response.containsKey('data')) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null) {
      if (data.containsKey('token') || 
          data.containsKey('accessToken') || 
          data.containsKey('access_token')) {
        return true;
      }
    }
  }
  
  // Verificar en tokens
  if (response.containsKey('tokens')) {
    final tokens = response['tokens'] as Map<String, dynamic>?;
    if (tokens != null) {
      if (tokens.containsKey('accessToken') || 
          tokens.containsKey('access_token')) {
        return true;
      }
    }
  }
  
  return false;
}

bool responseRequiresVerification(Map<String, dynamic> response) {
  // Verificar en el nivel principal
  if (response['requiresEmailVerification'] == true ||
      response['accountStatus'] == 'pending_verification') {
    return true;
  }
  
  // Verificar en data
  if (response.containsKey('data')) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null) {
      if (data['requiresEmailVerification'] == true ||
          data['accountStatus'] == 'pending_verification') {
        return true;
      }
    }
  }
  
  return false;
}


Future<bool> hasValidAccessToken() async {
  try {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      print('⚠️ [TOKEN] No access token found');
      return false;
    }
    
    // Verificar que no haya expirado
    if (await isTokenExpired()) {
      print('⚠️ [TOKEN] Token has expired');
      await clearAllTokens(); // Limpiar token expirado
      return false;
    }
    
    print('✅ [TOKEN] Valid access token found');
    return true;
  } catch (e) {
    print('❌ [TOKEN] Error checking token validity: $e');
    return false;
  }
}

// MÉTODO mejorado  guardar tokens



  // ==================== GET TOKENS ====================
  
  Future<String?> getAccessToken() async {
    try {
      final token = _prefs.getString(_accessTokenKey);
      if (token != null) {
        print('🔐 [TOKEN] Retrieved access token: ${token.substring(0, 20)}...');
        
        // Verificar si el token ha expirado
        if (await isTokenExpired()) {
          print('⚠️ [TOKEN] Access token has expired');
          return null;
        }
        
        return token;
      } else {
        print('⚠️ [TOKEN] No access token found');
        return null;
      }
    } catch (e) {
      print('❌ [TOKEN] Error getting access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = _prefs.getString(_refreshTokenKey);
      if (token != null) {
        print('🔐 [TOKEN] Retrieved refresh token: ${token.substring(0, 20)}...');
      } else {
        print('⚠️ [TOKEN] No refresh token found');
      }
      return token;
    } catch (e) {
      print('❌ [TOKEN] Error getting refresh token: $e');
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      final userId = _prefs.getString(_userIdKey);
      if (userId != null) {
        print('🔐 [TOKEN] Retrieved user ID: $userId');
      } else {
        print('⚠️ [TOKEN] No user ID found');
      }
      return userId;
    } catch (e) {
      print('❌ [TOKEN] Error getting user ID: $e');
      return null;
    }
  }

  // ==================== TOKEN VALIDATION ====================
  
  

  Future<bool> isTokenExpired() async {
    try {
      final expiryString = _prefs.getString(_tokenExpiryKey);
      if (expiryString == null) {
        // Si no hay fecha de expiración, asumir que está vigente por 1 hora
        return false;
      }
      
      final expiryDate = DateTime.parse(expiryString);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiryDate);
      
      if (isExpired) {
        print('⚠️ [TOKEN] Token expired at: $expiryDate (now: $now)');
      } else {
        print('✅ [TOKEN] Token valid until: $expiryDate');
      }
      
      return isExpired;
    } catch (e) {
      print('❌ [TOKEN] Error checking token expiry: $e');
      return false; // Si hay error, asumir que es válido
    }
  }

  // ==================== CLEAR TOKENS ====================
  
  Future<void> clearAllTokens() async {
    try {
      print('🔐 [TOKEN] Clearing all tokens...');
      await _prefs.remove(_accessTokenKey);
      await _prefs.remove(_refreshTokenKey);
      await _prefs.remove(_tokenExpiryKey);
      await _prefs.remove(_userIdKey);
      print('✅ [TOKEN] All tokens cleared');
    } catch (e) {
      print('❌ [TOKEN] Error clearing tokens: $e');
    }
  }

  // ==================== TOKEN INFO ====================
  
  Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      return {
        'hasAccessToken': await getAccessToken() != null,
        'hasRefreshToken': await getRefreshToken() != null,
        'isExpired': await isTokenExpired(),
        'userId': await getUserId(),
        'expiryDate': _prefs.getString(_tokenExpiryKey),
      };
    } catch (e) {
      print('❌ [TOKEN] Error getting token info: $e');
      return {};
    }
  }

  // ==================== HELPERS ====================
  
  /// Extrae tokens de una respuesta JSON del servidor
  

  /// Debug: Imprime toda la información de tokens
  Future<void> debugTokenInfo() async {
    print('🔍 [TOKEN] ==================== TOKEN DEBUG INFO ====================');
    final info = await getTokenInfo();
    info.forEach((key, value) {
      print('🔍 [TOKEN] $key: $value');
    });
    
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      print('🔍 [TOKEN] Access Token Preview: ${accessToken.substring(0, 30)}...');
    }
    
    print('🔍 [TOKEN] ================================================================');
  }
}