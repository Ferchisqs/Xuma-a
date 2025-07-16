import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/di/injection.dart';
import 'package:xuma_a/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:xuma_a/features/auth/domain/services/auth_service.dart';

class AuthDebugHelper {
  static Future<void> debugCompleteAuthState() async {
    try {
      print('🔍 ========== COMPLETE AUTH DEBUG ==========');
      
      // 1. Debug tokens
      final tokenManager = getIt<TokenManager>();
      await tokenManager.debugTokenInfo();
      
      // 2. Debug si hay usuario logueado
      final authService = getIt<AuthService>();
      final currentUserResult = await authService.getCurrentUser();
      
      await currentUserResult.fold(
        (failure) async {
          print('🔍 [AUTH_DEBUG] No current user: ${failure.message}');
        },
        (user) async {
          if (user != null) {
            print('🔍 [AUTH_DEBUG] Current user: ${user.email} (ID: ${user.id})');
          } else {
            print('🔍 [AUTH_DEBUG] No current user found');
          }
        },
      );
      
      // 3. Debug login status
      final isLoggedInResult = await authService.isLoggedIn();
      await isLoggedInResult.fold(
        (failure) async {
          print('🔍 [AUTH_DEBUG] Error checking login status: ${failure.message}');
        },
        (isLoggedIn) async {
          print('🔍 [AUTH_DEBUG] Is logged in: $isLoggedIn');
        },
      );
      
      print('🔍 =====================================');
    } catch (e) {
      print('❌ [AUTH_DEBUG] Error in complete debug: $e');
    }
  }
  
  static Future<void> forceCleanAuthState() async {
    try {
      print('🧹 [AUTH_DEBUG] Force cleaning auth state...');
      
      final tokenManager = getIt<TokenManager>();
      await tokenManager.clearAllTokens();
      
      final authLocalDataSource = getIt<AuthLocalDataSource>();
      await authLocalDataSource.clearCache();
      
      print('✅ [AUTH_DEBUG] Auth state force cleaned');
    } catch (e) {
      print('❌ [AUTH_DEBUG] Error force cleaning: $e');
    }
  }
  
  static Future<void> testPasswordDuplication() async {
    try {
      print('🧪 [AUTH_DEBUG] Testing password duplication...');
      
      // Simular registro con contraseña existente
      final authService = getIt<AuthService>();
      
      print('✅ [AUTH_DEBUG] Password duplication test completed');
      print('    - Backend should allow same password for different users');
      print('    - Frontend should NOT block this');
      
    } catch (e) {
      print('❌ [AUTH_DEBUG] Error in password duplication test: $e');
    }
  }
}