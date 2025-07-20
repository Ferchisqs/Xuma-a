// lib/core/utils/companion_api_test_helper.dart - HERRAMIENTA PARA PROBAR LA API
import 'package:flutter/foundation.dart';
import '../../di/injection.dart';
import '../../features/companion/data/datasources/companion_remote_datasource.dart';
import '../../features/companion/domain/repositories/companion_repository.dart';
import '../../features/companion/domain/usecases/get_user_companions_usecase.dart';
import '../../features/companion/domain/usecases/get_available_companions_usecase.dart';
import '../../core/services/token_manager.dart';

class CompanionApiTestHelper {
  
  /// Probar todos los endpoints de la API de compañeros
  static Future<void> testAllEndpoints() async {
    debugPrint('🧪 [API_TEST] ======================================');
    debugPrint('🧪 [API_TEST] INICIANDO PRUEBAS DE API DE COMPAÑEROS');
    debugPrint('🧪 [API_TEST] ======================================');
    
    try {
      // 1. Verificar dependencias
      await _testDependencies();
      
      // 2. Verificar token de autenticación
      await _testAuthentication();
      
      // 3. Probar endpoints públicos (sin autenticación)
      await _testPublicEndpoints();
      
      // 4. Probar endpoints privados (con autenticación)
      await _testPrivateEndpoints();
      
      debugPrint('🎉 [API_TEST] ======================================');
      debugPrint('🎉 [API_TEST] TODAS LAS PRUEBAS COMPLETADAS');
      debugPrint('🎉 [API_TEST] ======================================');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [API_TEST] ERROR EN PRUEBAS: $e');
      debugPrint('❌ [API_TEST] Stack trace: $stackTrace');
    }
  }
  
  /// Verificar que todas las dependencias estén registradas
  static Future<void> _testDependencies() async {
    debugPrint('🔧 [API_TEST] === VERIFICANDO DEPENDENCIAS ===');
    
    try {
      final remoteDataSource = getIt<CompanionRemoteDataSource>();
      debugPrint('✅ [API_TEST] CompanionRemoteDataSource: OK');
      
      final repository = getIt<CompanionRepository>();
      debugPrint('✅ [API_TEST] CompanionRepository: OK');
      
      final tokenManager = getIt<TokenManager>();
      debugPrint('✅ [API_TEST] TokenManager: OK');
      
      debugPrint('✅ [API_TEST] Todas las dependencias están disponibles');
    } catch (e) {
      debugPrint('❌ [API_TEST] Error verificando dependencias: $e');
      throw Exception('Dependencias no disponibles: $e');
    }
  }
  
  /// Verificar estado de autenticación
  static Future<void> _testAuthentication() async {
    debugPrint('🔐 [API_TEST] === VERIFICANDO AUTENTICACIÓN ===');
    
    try {
      final tokenManager = getIt<TokenManager>();
      
      final hasValidToken = await tokenManager.hasValidAccessToken();
      debugPrint('🔐 [API_TEST] Token válido: $hasValidToken');
      
      if (hasValidToken) {
        final tokenInfo = await tokenManager.getTokenInfo();
        debugPrint('🔐 [API_TEST] Info del token: $tokenInfo');
      } else {
        debugPrint('⚠️ [API_TEST] Sin token válido - solo se probarán endpoints públicos');
      }
    } catch (e) {
      debugPrint('❌ [API_TEST] Error verificando autenticación: $e');
    }
  }
  
  /// Probar endpoints que no requieren autenticación
  static Future<void> _testPublicEndpoints() async {
    debugPrint('🌐 [API_TEST] === PROBANDO ENDPOINTS PÚBLICOS ===');
    
    try {
      final remoteDataSource = getIt<CompanionRemoteDataSource>();
      
      // 1. Probar mascotas disponibles
      debugPrint('🧪 [API_TEST] Probando getAvailableCompanions...');
      try {
        final availableCompanions = await remoteDataSource.getAvailableCompanions();
        debugPrint('✅ [API_TEST] Available Companions: ${availableCompanions.length} encontradas');
        
        if (availableCompanions.isNotEmpty) {
          final first = availableCompanions.first;
          debugPrint('🐾 [API_TEST] Primera mascota: ${first.displayName} (${first.type.name}_${first.stage.name})');
          debugPrint('💰 [API_TEST] Precio: ${first.purchasePrice} puntos');
        }
      } catch (e) {
        debugPrint('❌ [API_TEST] Error en getAvailableCompanions: $e');
      }
      
      // 2. Probar tienda de mascotas
      debugPrint('🧪 [API_TEST] Probando getStoreCompanions...');
      try {
        final storeCompanions = await remoteDataSource.getStoreCompanions(userId: '');
        debugPrint('✅ [API_TEST] Store Companions: ${storeCompanions.length} encontradas');
        
        if (storeCompanions.isNotEmpty) {
          final cheapest = storeCompanions.reduce((a, b) => 
            a.purchasePrice < b.purchasePrice ? a : b);
          final mostExpensive = storeCompanions.reduce((a, b) => 
            a.purchasePrice > b.purchasePrice ? a : b);
          
          debugPrint('💰 [API_TEST] Más barata: ${cheapest.displayName} (${cheapest.purchasePrice}★)');
          debugPrint('💎 [API_TEST] Más cara: ${mostExpensive.displayName} (${mostExpensive.purchasePrice}★)');
        }
      } catch (e) {
        debugPrint('❌ [API_TEST] Error en getStoreCompanions: $e');
      }
      
    } catch (e) {
      debugPrint('❌ [API_TEST] Error en endpoints públicos: $e');
    }
  }
  
  /// Probar endpoints que requieren autenticación
  static Future<void> _testPrivateEndpoints() async {
    debugPrint('🔐 [API_TEST] === PROBANDO ENDPOINTS PRIVADOS ===');
    
    try {
      final tokenManager = getIt<TokenManager>();
      final hasValidToken = await tokenManager.hasValidAccessToken();
      
      if (!hasValidToken) {
        debugPrint('⚠️ [API_TEST] Sin token válido, saltando endpoints privados');
        return;
      }
      
      final remoteDataSource = getIt<CompanionRemoteDataSource>();
      const testUserId = 'user_123'; // Usuario de prueba
      
      // 1. Probar mascotas del usuario
      debugPrint('🧪 [API_TEST] Probando getUserCompanions...');
      try {
        final userCompanions = await remoteDataSource.getUserCompanions(testUserId);
        debugPrint('✅ [API_TEST] User Companions: ${userCompanions.length} encontradas');
        
        if (userCompanions.isNotEmpty) {
          final owned = userCompanions.where((c) => c.isOwned).length;
          final active = userCompanions.where((c) => c.isSelected).length;
          debugPrint('🏠 [API_TEST] Poseídas: $owned, Activas: $active');
        }
      } catch (e) {
        debugPrint('❌ [API_TEST] Error en getUserCompanions: $e');
      }
      
      // 2. Probar estadísticas
      debugPrint('🧪 [API_TEST] Probando getCompanionStats...');
      try {
        final stats = await remoteDataSource.getCompanionStats(testUserId);
        debugPrint('✅ [API_TEST] Stats obtenidas:');
        debugPrint('📊 [API_TEST] Total: ${stats.totalCompanions}, Poseídas: ${stats.ownedCompanions}');
        debugPrint('💰 [API_TEST] Puntos: ${stats.availablePoints} disponibles');
      } catch (e) {
        debugPrint('❌ [API_TEST] Error en getCompanionStats: $e');
      }
      
    } catch (e) {
      debugPrint('❌ [API_TEST] Error en endpoints privados: $e');
    }
  }
  
  /// Probar la integración completa usando los Use Cases
  static Future<void> testUseCaseIntegration() async {
    debugPrint('🔧 [API_TEST] === PROBANDO INTEGRACIÓN DE USE CASES ===');
    
    try {
      // 1. Probar GetAvailableCompanionsUseCase
      debugPrint('🧪 [API_TEST] Probando GetAvailableCompanionsUseCase...');
      try {
        final useCase = getIt<GetAvailableCompanionsUseCase>();
        final result = await useCase();
        
        result.fold(
          (failure) {
            debugPrint('❌ [API_TEST] UseCase falló: ${failure.message}');
          },
          (companions) {
            debugPrint('✅ [API_TEST] UseCase exitoso: ${companions.length} compañeros');
          },
        );
      } catch (e) {
        debugPrint('❌ [API_TEST] Error en UseCase: $e');
      }
      
      // 2. Probar GetUserCompanionsUseCase (si hay token)
      final tokenManager = getIt<TokenManager>();
      final hasValidToken = await tokenManager.hasValidAccessToken();
      
      if (hasValidToken) {
        debugPrint('🧪 [API_TEST] Probando GetUserCompanionsUseCase...');
        try {
          final useCase = getIt<GetUserCompanionsUseCase>();
          const testUserId = 'user_123';
          
          final result = await useCase(const GetUserCompanionsParams(userId: testUserId));
          
          result.fold(
            (failure) {
              debugPrint('❌ [API_TEST] UserCompanions UseCase falló: ${failure.message}');
            },
            (companions) {
              debugPrint('✅ [API_TEST] UserCompanions UseCase exitoso: ${companions.length} compañeros');
            },
          );
        } catch (e) {
          debugPrint('❌ [API_TEST] Error en UserCompanions UseCase: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ [API_TEST] Error en integración de Use Cases: $e');
    }
  }
  
  /// Probar un endpoint específico con parámetros personalizados
  static Future<void> testSpecificEndpoint(String endpoint, {Map<String, dynamic>? data}) async {
    debugPrint('🎯 [API_TEST] === PROBANDO ENDPOINT ESPECÍFICO ===');
    debugPrint('🎯 [API_TEST] Endpoint: $endpoint');
    debugPrint('🎯 [API_TEST] Data: $data');
    
    try {
      // Aquí puedes agregar lógica específica para probar endpoints individuales
      debugPrint('⚠️ [API_TEST] Implementar lógica específica según endpoint');
    } catch (e) {
      debugPrint('❌ [API_TEST] Error en endpoint específico: $e');
    }
  }
  
  /// Método para probar la conectividad básica con la API
  static Future<bool> testConnectivity() async {
    debugPrint('🌐 [API_TEST] === PROBANDO CONECTIVIDAD BÁSICA ===');
    
    try {
      final remoteDataSource = getIt<CompanionRemoteDataSource>();
      
      // Intentar un endpoint simple y público
      await remoteDataSource.getAvailableCompanions();
      
      debugPrint('✅ [API_TEST] Conectividad OK');
      return true;
    } catch (e) {
      debugPrint('❌ [API_TEST] Sin conectividad: $e');
      return false;
    }
  }
  
  /// Método de conveniencia para hacer pruebas rápidas desde la UI
  static Future<void> quickTest() async {
    debugPrint('⚡ [API_TEST] === PRUEBA RÁPIDA ===');
    
    // Test básico de conectividad
    final isConnected = await testConnectivity();
    
    if (isConnected) {
      debugPrint('🚀 [API_TEST] API funcionando - ejecutando prueba completa');
      await testAllEndpoints();
    } else {
      debugPrint('❌ [API_TEST] API no disponible - verifica conexión y URL');
    }
  }
}