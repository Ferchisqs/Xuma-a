// lib/core/utils/media_debug_helper.dart - HERRAMIENTA DE DEBUGGING PARA MEDIA
import 'package:xuma_a/features/learning/data/datasources/media_remote_datasource.dart';

import '../../di/injection.dart';
import '../../core/network/api_client.dart';

class MediaDebugHelper {
  
  /// Probar todos los endpoints posibles para un Media ID específico
  static Future<void> debugAllEndpoints(String mediaId) async {
    print('🧪 [MEDIA DEBUG] ===============================================');
    print('🧪 [MEDIA DEBUG] TESTING ALL ENDPOINTS FOR MEDIA ID: $mediaId');
    print('🧪 [MEDIA DEBUG] ===============================================');
    
    final apiClient = getIt<ApiClient>();
    
    // Lista de todos los endpoints posibles
    final endpoints = [
      '/api/media/files/$mediaId',
      '/api/files/$mediaId',
      '/api/media/file/$mediaId',
      '/api/content/files/$mediaId',
      '/files/$mediaId',
      '/api/media/$mediaId',
      '/api/content/media/$mediaId',
      '/media/$mediaId',
      '/api/uploads/$mediaId',
      '/uploads/$mediaId',
      '/api/assets/$mediaId',
      '/assets/$mediaId',
      '/public/$mediaId',
      '/api/public/$mediaId',
      '/public/media/$mediaId',
      '/public/files/$mediaId',
      '/api/storage/$mediaId',
      '/storage/$mediaId',
      '/api/attachments/$mediaId',
      '/attachments/$mediaId',
    ];
    
    final results = <String, Map<String, dynamic>>{};
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      print('\n🧪 [MEDIA DEBUG] Testing ${i + 1}/${endpoints.length}: $endpoint');
      
      try {
        final response = await apiClient.get(endpoint);
        
        final result = {
          'status': 'SUCCESS',
          'statusCode': response.statusCode,
          'dataType': response.data.runtimeType.toString(),
          'hasData': response.data != null,
        };
        
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          result['keys'] = data.keys.take(10).toList();
          result['sampleData'] = _getSafeDataSample(data);
          
          // Buscar URLs en la respuesta
          final urls = _extractAllUrls(data);
          if (urls.isNotEmpty) {
            result['foundUrls'] = urls;
            print('🧪 [MEDIA DEBUG] ✅ $endpoint - FOUND ${urls.length} URLs!');
            for (final url in urls) {
              print('🧪 [MEDIA DEBUG]    📎 URL: $url');
            }
          } else {
            print('🧪 [MEDIA DEBUG] ✅ $endpoint - No URLs found');
          }
        } else if (response.data is String) {
          final dataStr = response.data.toString();
          result['stringData'] = dataStr.length > 100 ? '${dataStr.substring(0, 100)}...' : dataStr;
          
          if (_isValidUrl(dataStr)) {
            result['isDirectUrl'] = true;
            print('🧪 [MEDIA DEBUG] ✅ $endpoint - DIRECT URL: $dataStr');
          } else {
            print('🧪 [MEDIA DEBUG] ✅ $endpoint - String response (not URL)');
          }
        } else {
          print('🧪 [MEDIA DEBUG] ✅ $endpoint - Success (${response.data.runtimeType})');
        }
        
        results[endpoint] = result;
        
      } catch (e) {
        print('🧪 [MEDIA DEBUG] ❌ $endpoint - ERROR: $e');
        results[endpoint] = {
          'status': 'ERROR',
          'error': e.toString(),
        };
      }
    }
    
    // Resumen final
    print('\n🧪 [MEDIA DEBUG] ===============================================');
    print('🧪 [MEDIA DEBUG] SUMMARY FOR MEDIA ID: $mediaId');
    print('🧪 [MEDIA DEBUG] ===============================================');
    
    final successfulEndpoints = <String>[];
    final endpointsWithUrls = <String>[];
    
    results.forEach((endpoint, result) {
      if (result['status'] == 'SUCCESS') {
        successfulEndpoints.add(endpoint);
        if (result['foundUrls'] != null || result['isDirectUrl'] == true) {
          endpointsWithUrls.add(endpoint);
        }
      }
    });
    
    print('🧪 [MEDIA DEBUG] Successful endpoints: ${successfulEndpoints.length}/${endpoints.length}');
    for (final endpoint in successfulEndpoints) {
      print('🧪 [MEDIA DEBUG]   ✅ $endpoint');
    }
    
    print('\n🧪 [MEDIA DEBUG] Endpoints with URLs: ${endpointsWithUrls.length}');
    for (final endpoint in endpointsWithUrls) {
      print('🧪 [MEDIA DEBUG]   🔗 $endpoint');
    }
    
    if (endpointsWithUrls.isNotEmpty) {
      print('\n🎉 [MEDIA DEBUG] RECOMMENDED ENDPOINT: ${endpointsWithUrls.first}');
    } else {
      print('\n⚠️ [MEDIA DEBUG] NO ENDPOINTS RETURNED VALID URLS');
    }
    
    print('🧪 [MEDIA DEBUG] ===============================================');
  }
  
  /// Probar el MediaRemoteDataSource actual
  static Future<void> testMediaDataSource(String mediaId) async {
    print('\n🧪 [MEDIA DEBUG] ===============================================');
    print('🧪 [MEDIA DEBUG] TESTING MediaRemoteDataSource');
    print('🧪 [MEDIA DEBUG] ===============================================');
    
    try {
      final mediaDataSource = getIt<MediaRemoteDataSource>();
      
      print('🧪 [MEDIA DEBUG] Testing getMediaResponse...');
      final response = await mediaDataSource.getMediaResponse(mediaId);
      
      if (response != null) {
        print('🧪 [MEDIA DEBUG] ✅ MediaRemoteDataSource SUCCESS');
        print('🧪 [MEDIA DEBUG] Response: $response');
        print('🧪 [MEDIA DEBUG] URL: ${response.url}');
        print('🧪 [MEDIA DEBUG] Type: ${response.type}');
        print('🧪 [MEDIA DEBUG] Valid: ${response.isValid}');
        print('🧪 [MEDIA DEBUG] Metadata: ${response.metadata}');
      } else {
        print('🧪 [MEDIA DEBUG] ❌ MediaRemoteDataSource returned null');
      }
      
    } catch (e, stackTrace) {
      print('🧪 [MEDIA DEBUG] ❌ MediaRemoteDataSource ERROR: $e');
      print('🧪 [MEDIA DEBUG] Stack trace: $stackTrace');
    }
    
    print('🧪 [MEDIA DEBUG] ===============================================');
  }
  
  /// Método conveniente para probar un Media ID completo
  static Future<void> fullDebugTest(String mediaId) async {
    await debugAllEndpoints(mediaId);
    await testMediaDataSource(mediaId);
  }
  
  /// Probar con el Media ID problemático actual
  static Future<void> testProblematicMediaId() async {
    const problematicId = '3ea8ff47-ca30-4f3d-bdef-28bf5562cd34';
    await fullDebugTest(problematicId);
  }
  
  // ==================== MÉTODOS HELPER ====================
  
  static List<String> _extractAllUrls(Map<String, dynamic> data) {
    final urls = <String>[];
    
    void searchForUrls(dynamic value, String path) {
      if (value is String && _isValidUrl(value)) {
        urls.add('$path: $value');
      } else if (value is Map<String, dynamic>) {
        value.forEach((key, val) {
          searchForUrls(val, path.isEmpty ? key : '$path.$key');
        });
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          searchForUrls(value[i], '$path[$i]');
        }
      }
    }
    
    searchForUrls(data, '');
    return urls;
  }
  
  static bool _isValidUrl(String url) {
    return url.isNotEmpty && 
           (url.startsWith('http://') || 
            url.startsWith('https://') || 
            url.startsWith('/') || 
            url.startsWith('data:'));
  }
  
  static Map<String, dynamic> _getSafeDataSample(Map<String, dynamic> data) {
    final sample = <String, dynamic>{};
    
    // Solo incluir campos importantes para debugging
    final importantFields = [
      'url', 'fileUrl', 'file_url', 'downloadUrl', 'download_url',
      'publicUrl', 'public_url', 'src', 'source', 'href', 'link',
      'filename', 'name', 'mimeType', 'fileType', 'size'
    ];
    
    for (final field in importantFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value is String && value.length > 100) {
          sample[field] = '${value.substring(0, 100)}...';
        } else {
          sample[field] = value;
        }
      }
    }
    
    return sample;
  }
  
  /// Método para obtener recomendaciones basadas en el backend
  static void printRecommendations() {
    print('\n📋 [MEDIA DEBUG] RECOMENDACIONES PARA CONFIGURAR EL BACKEND:');
    print('📋 [MEDIA DEBUG] ===============================================');
    print('📋 [MEDIA DEBUG]');
    print('📋 [MEDIA DEBUG] 1. VERIFICAR ENDPOINTS EN EL BACKEND:');
    print('📋 [MEDIA DEBUG]    - ¿Existe el endpoint /api/media/files/{id}?');
    print('📋 [MEDIA DEBUG]    - ¿Cuál es el endpoint correcto para obtener archivos?');
    print('📋 [MEDIA DEBUG]');
    print('📋 [MEDIA DEBUG] 2. VERIFICAR ESTRUCTURA DE RESPUESTA:');
    print('📋 [MEDIA DEBUG]    - ¿Qué campo contiene la URL del archivo?');
    print('📋 [MEDIA DEBUG]    - ¿La respuesta es JSON o URL directa?');
    print('📋 [MEDIA DEBUG]');
    print('📋 [MEDIA DEBUG] 3. VERIFICAR ID DEL MEDIA:');
    print('📋 [MEDIA DEBUG]    - ¿El ID 3ea8ff47-ca30-4f3d-bdef-28bf5562cd34 existe?');
    print('📋 [MEDIA DEBUG]    - ¿Es necesario algún prefijo o sufijo?');
    print('📋 [MEDIA DEBUG]');
    print('📋 [MEDIA DEBUG] 4. VERIFICAR AUTENTICACIÓN:');
    print('📋 [MEDIA DEBUG]    - ¿Se requiere token de autenticación?');
    print('📋 [MEDIA DEBUG]    - ¿Los archivos son públicos o privados?');
    print('📋 [MEDIA DEBUG]');
    print('📋 [MEDIA DEBUG] Ejecuta MediaDebugHelper.testProblematicMediaId()');
    print('📋 [MEDIA DEBUG] para probar con tu Media ID problemático actual.');
    print('📋 [MEDIA DEBUG] ===============================================');
  }
}