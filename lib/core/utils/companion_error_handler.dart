// lib/core/utils/companion_error_handler.dart - MANEJO ROBUSTO DE ERRORES API
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../features/companion/data/models/companion_model.dart';
import '../../features/companion/domain/entities/companion_entity.dart';

class CompanionErrorHandler {
  
  /// Verificar si un error debe activar fallback local
  static bool shouldUseFallback(dynamic error) {
    debugPrint('🔍 [ERROR_HANDLER] Analizando error: ${error.runtimeType}');
    debugPrint('🔍 [ERROR_HANDLER] Error details: $error');
    
    // Errors de Dio (problemas de red/servidor)
    if (error is DioException) {
      debugPrint('🌐 [ERROR_HANDLER] DioException detectado');
      
      // Error 500 - Internal Server Error
      if (error.response?.statusCode == 500) {
        debugPrint('❌ [ERROR_HANDLER] Error 500 detectado - usando fallback');
        return true;
      }
      
      // Error 404 - Not Found (usuario nuevo sin mascotas)
      if (error.response?.statusCode == 404) {
        debugPrint('⚠️ [ERROR_HANDLER] Error 404 detectado - usuario sin mascotas, usando fallback');
        return true;
      }
      
      // Errores de timeout
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        debugPrint('⏱️ [ERROR_HANDLER] Timeout detectado - usando fallback');
        return true;
      }
      
      // Errores de conexión
      if (error.type == DioExceptionType.connectionError) {
        debugPrint('📡 [ERROR_HANDLER] Error de conexión - usando fallback');
        return true;
      }
      
      // Errores del servidor (5xx)
      if (error.response?.statusCode != null && 
          error.response!.statusCode! >= 500) {
        debugPrint('🔥 [ERROR_HANDLER] Error servidor 5xx - usando fallback');
        return true;
      }
    }
    
    // Excepciones generales
    if (error is Exception) {
      final errorMsg = error.toString().toLowerCase();
      
      // Mensajes que indican problemas de servidor
      if (errorMsg.contains('server') || 
          errorMsg.contains('internal') ||
          errorMsg.contains('500') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('connection')) {
        debugPrint('🔍 [ERROR_HANDLER] Error de servidor por mensaje - usando fallback');
        return true;
      }
    }
    
    // Por defecto, usar fallback para cualquier error no manejado
    debugPrint('🔍 [ERROR_HANDLER] Error no categorizado - usando fallback por seguridad');
    return true;
  }
  
  /// Obtener mensaje amigable para el usuario
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 500:
          return 'El servidor está temporalmente no disponible. Usando datos locales.';
        case 404:
          return 'Aún no tienes mascotas. ¡Aquí está tu primer compañero!';
        case 401:
        case 403:
          return 'Problema de autenticación. Usando datos locales.';
        default:
          if (error.type == DioExceptionType.connectionTimeout) {
            return 'Conexión lenta. Usando datos locales.';
          }
          if (error.type == DioExceptionType.connectionError) {
            return 'Sin conexión. Mostrando datos guardados.';
          }
          return 'Problema temporal con el servidor. Usando datos locales.';
      }
    }
    
    return 'Usando datos locales por seguridad.';
  }
  
  /// Verificar si una respuesta de API está vacía o es inválida
  static bool isEmptyOrInvalidResponse(dynamic responseData) {
    if (responseData == null) {
      debugPrint('⚠️ [ERROR_HANDLER] Respuesta nula detectada');
      return true;
    }
    
    // Lista vacía
    if (responseData is List && responseData.isEmpty) {
      debugPrint('⚠️ [ERROR_HANDLER] Lista vacía detectada');
      return true;
    }
    
    // Mapa vacío o sin datos útiles
    if (responseData is Map<String, dynamic>) {
      // Verificar si tiene campos de datos
      final hasData = responseData.containsKey('data') || 
                     responseData.containsKey('pets') ||
                     responseData.containsKey('companions') ||
                     responseData.containsKey('items');
      
      if (!hasData) {
        debugPrint('⚠️ [ERROR_HANDLER] Respuesta sin campos de datos útiles');
        return true;
      }
      
      // Verificar si los datos están vacíos
      final dataField = responseData['data'] ?? 
                       responseData['pets'] ?? 
                       responseData['companions'] ?? 
                       responseData['items'];
      
      if (dataField is List && dataField.isEmpty) {
        debugPrint('⚠️ [ERROR_HANDLER] Campo de datos vacío');
        return true;
      }
    }
    
    return false;
  }
  
  /// Loggear error de forma estructurada
  static void logError(String operation, dynamic error, {String? userId}) {
    debugPrint('❌ [ERROR_HANDLER] ==========================================');
    debugPrint('❌ [ERROR_HANDLER] OPERATION: $operation');
    if (userId != null) {
      debugPrint('❌ [ERROR_HANDLER] USER_ID: $userId');
    }
    debugPrint('❌ [ERROR_HANDLER] ERROR_TYPE: ${error.runtimeType}');
    debugPrint('❌ [ERROR_HANDLER] ERROR_MESSAGE: $error');
    
    if (error is DioException) {
      debugPrint('❌ [ERROR_HANDLER] STATUS_CODE: ${error.response?.statusCode}');
      debugPrint('❌ [ERROR_HANDLER] RESPONSE_DATA: ${error.response?.data}');
      debugPrint('❌ [ERROR_HANDLER] DIO_TYPE: ${error.type}');
    }
    
    debugPrint('❌ [ERROR_HANDLER] FALLBACK_NEEDED: ${shouldUseFallback(error)}');
    debugPrint('❌ [ERROR_HANDLER] ==========================================');
  }
  
  /// Generar ID local único para un compañero
  /// Verificar si el servidor está disponible
  static Future<bool> isServerAvailable(String baseUrl) async {
    try {
      debugPrint('🔍 [ERROR_HANDLER] Verificando disponibilidad del servidor: $baseUrl');
      
      // Aquí puedes agregar una verificación real de conectividad
      // Por ahora, simulamos una verificación básica
      await Future.delayed(const Duration(seconds: 1));
      
      debugPrint('✅ [ERROR_HANDLER] Servidor disponible');
      return true;
    } catch (e) {
      debugPrint('❌ [ERROR_HANDLER] Servidor no disponible: $e');
      return false;
    }
  }
  
  /// Crear mensaje de estado para la UI
  static Map<String, dynamic> createStatusMessage(String operation, dynamic error) {
    final shouldFallback = shouldUseFallback(error);
    final userMessage = getUserFriendlyMessage(error);
    
    return {
      'operation': operation,
      'hasError': true,
      'shouldUseFallback': shouldFallback,
      'userMessage': userMessage,
      'technicalMessage': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Método para mostrar notificación al usuario (opcional)
  static void showErrorNotification(String operation, dynamic error) {
    final message = getUserFriendlyMessage(error);
    debugPrint('🔔 [ERROR_HANDLER] NOTIFICACIÓN: $message');
    
    // Aquí puedes integrar con tu sistema de notificaciones
    // Por ejemplo, mostrar un SnackBar o Toast
  }
}