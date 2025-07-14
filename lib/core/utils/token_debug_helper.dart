// lib/core/utils/token_debug_helper.dart - CREAR ESTE ARCHIVO
import '../../di/injection.dart';
import '../services/token_manager.dart';

class TokenDebugHelper {
  static Future<void> debugTokens() async {
    try {
      final tokenManager = getIt<TokenManager>();
      await tokenManager.debugTokenInfo();
      print('✅ [DEBUG] Token debug completed');
    } catch (e) {
      print('❌ [DEBUG] Error debugging tokens: $e');
    }
  }

  static Future<void> clearAllTokens() async {
    try {
      final tokenManager = getIt<TokenManager>();
      await tokenManager.clearAllTokens();
      print('✅ [DEBUG] All tokens cleared');
    } catch (e) {
      print('❌ [DEBUG] Error clearing tokens: $e');
    }
  }

  static Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final tokenManager = getIt<TokenManager>();
      return await tokenManager.getTokenInfo();
    } catch (e) {
      print('❌ [DEBUG] Error getting token info: $e');
      return {};
    }
  }

  static Future<bool> hasValidToken() async {
    try {
      final tokenManager = getIt<TokenManager>();
      return await tokenManager.hasValidAccessToken();
    } catch (e) {
      print('❌ [DEBUG] Error checking token validity: $e');
      return false;
    }
  }
}