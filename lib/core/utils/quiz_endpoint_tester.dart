// lib/core/utils/quiz_endpoint_tester.dart - ACTUALIZADO CON RUTAS CORRECTAS
import '../../di/injection.dart';
import '../network/api_client.dart';
import '../config/api_endpoints.dart';

class QuizEndpointTesterUpdated {
  
  /// Probar todos los endpoints corregidos del quiz
  static Future<void> testCorrectedEndpoints() async {
    print('🔧 [QUIZ TEST] ===============================================');
    print('🔧 [QUIZ TEST] TESTING CORRECTED QUIZ ENDPOINTS');
    print('🔧 [QUIZ TEST] Base URL: ${ApiEndpoints.quizServiceUrl}');
    print('🔧 [QUIZ TEST] ===============================================');
    
    final apiClient = getIt<ApiClient>();
    final testTopicId = 'a90d3ede-42ae-4b81-a185-9336ea6e195b';
    
    // Lista de endpoints corregidos para probar
    final endpointsToTest = [
      {
        'name': '1. Content Topics (FUNCIONA)',
        'endpoint': '/api/content/topics',
        'method': 'content', // Usar content service
        'expected': 'Lista de topics'
      },
      {
        'name': '2. Quizzes by Topic (CORREGIDO)',
        'endpoint': '/api/quiz/by-topic/$testTopicId',
        'method': 'quiz',
        'expected': 'Lista de quizzes para el topic'
      },
      {
        'name': '3. Quiz by ID (CORREGIDO)',
        'endpoint': '/api/quiz/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
        'method': 'quiz',
        'expected': 'Datos del quiz específico'
      },
      {
        'name': '4. Quiz Questions (CORREGIDO)',
        'endpoint': '/api/quiz/questions/quiz/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
        'method': 'quiz',
        'expected': 'Lista de preguntas del quiz'
      },
      {
        'name': '5. Question by ID (NUEVO)',
        'endpoint': '/api/quiz/questions/ef325182-70d8-4c18-abd0-bf037762c652',
        'method': 'quiz',
        'expected': 'Datos de la pregunta específica'
      },
      {
        'name': '6. Quiz Results (CORREGIDO)',
        'endpoint': '/api/quiz/results/session_example_001',
        'method': 'quiz',
        'expected': 'Resultados de la sesión'
      },
      {
        'name': '7. User Progress (CORREGIDO)',
        'endpoint': '/api/quiz/user-progress/test_user_123',
        'method': 'quiz',
        'expected': 'Progreso del usuario'
      },
    ];
    
    final results = <String, Map<String, dynamic>>{};
    
    for (int i = 0; i < endpointsToTest.length; i++) {
      final test = endpointsToTest[i];
      print('\n🔧 [QUIZ TEST] Testing ${test['name']}');
      print('🔧 [QUIZ TEST] GET ${test['endpoint']}');
      
      final result = await _testSingleCorrectedEndpoint(
        apiClient,
        test['endpoint'] as String,
        test['method'] as String,
      );
      
      results[test['endpoint'] as String] = {
        'name': test['name'],
        'expected': test['expected'],
        ...result,
      };
      
      // Pausa entre requests
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Mostrar resumen
    _showCorrectedTestResults(results);
  }
  
  static Future<Map<String, dynamic>> _testSingleCorrectedEndpoint(
    ApiClient apiClient,
    String endpoint,
    String method,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      late dynamic response;
      
      if (method == 'content') {
        // Para el endpoint de topics, usar content service
        response = await apiClient.getContent(endpoint);
      } else if (method == 'quiz') {
        // Para endpoints de quiz, usar quiz service
        response = await apiClient.getQuiz(endpoint);
      }
      
      stopwatch.stop();
      
      return {
        'status': 'SUCCESS',
        'statusCode': response.statusCode,
        'responseTime': '${stopwatch.elapsedMilliseconds}ms',
        'dataType': response.data.runtimeType.toString(),
        'hasData': response.data != null,
        'dataPreview': _getDataPreview(response.data),
      };
      
    } catch (e) {
      String errorType = 'UNKNOWN';
      String statusCode = 'N/A';
      
      if (e.toString().contains('404')) {
        errorType = 'NOT_FOUND';
        statusCode = '404';
      } else if (e.toString().contains('500')) {
        errorType = 'SERVER_ERROR';
        statusCode = '500';
      } else if (e.toString().contains('401')) {
        errorType = 'UNAUTHORIZED';
        statusCode = '401';
      } else if (e.toString().contains('403')) {
        errorType = 'FORBIDDEN';
        statusCode = '403';
      } else if (e.toString().contains('timeout')) {
        errorType = 'TIMEOUT';
      } else if (e.toString().contains('connection')) {
        errorType = 'CONNECTION_ERROR';
      }
      
      return {
        'status': 'ERROR',
        'errorType': errorType,
        'statusCode': statusCode,
        'error': e.toString(),
      };
    }
  }
  
  static String _getDataPreview(dynamic data) {
    if (data == null) return 'null';
    
    if (data is String) {
      return data.length > 100 ? '${data.substring(0, 100)}...' : data;
    } else if (data is List) {
      return 'Array[${data.length}]';
    } else if (data is Map) {
      final keys = (data as Map).keys.take(5).join(', ');
      return 'Object{$keys${(data as Map).keys.length > 5 ? '...' : ''}}';
    }
    
    return data.runtimeType.toString();
  }
  
  static void _showCorrectedTestResults(Map<String, Map<String, dynamic>> results) {
    print('\n📊 [QUIZ TEST] ===============================================');
    print('📊 [QUIZ TEST] CORRECTED ENDPOINTS TEST RESULTS');
    print('📊 [QUIZ TEST] ===============================================');
    
    final successful = <String>[];
    final failed = <String>[];
    
    results.forEach((endpoint, result) {
      final status = result['status'] as String;
      final name = result['name'] as String;
      
      if (status == 'SUCCESS') {
        successful.add('✅ $name');
        print('   ✅ $name: $endpoint (${result['statusCode']})');
      } else {
        failed.add('❌ $name');
        print('   ❌ $name: $endpoint (${result['errorType']})');
      }
    });
    
    print('\n📊 [QUIZ TEST] SUMMARY:');
    print('📊 [QUIZ TEST] ✅ Success: ${successful.length}/${results.length}');
    print('📊 [QUIZ TEST] ❌ Failed: ${failed.length}/${results.length}');
    
    if (successful.length == results.length) {
      print('🎉 [QUIZ TEST] ¡TODOS LOS ENDPOINTS FUNCIONAN!');
    } else if (successful.length > 0) {
      print('⚠️ [QUIZ TEST] Algunos endpoints funcionan, revisar los que fallan');
    } else {
      print('💥 [QUIZ TEST] NINGÚN ENDPOINT FUNCIONA - Revisar configuración');
    }
    
    print('📊 [QUIZ TEST] ===============================================');
  }
  
  /// Test rápido solo para verificar la corrección
  static Future<void> quickCorrectionTest() async {
    print('⚡ [QUICK TEST] Verificando correcciones...');
    
    final apiClient = getIt<ApiClient>();
    
    final tests = [
      '/api/content/topics', // Este debe funcionar
      '/api/quiz/by-topic/test_topic', // Este debería dar 404 pero llegar al servidor
    ];
    
    for (final endpoint in tests) {
      try {
        dynamic response;
        if (endpoint.contains('/api/content/')) {
          response = await apiClient.getContent(endpoint);
        } else {
          response = await apiClient.getQuiz(endpoint);
        }
        print('✅ [QUICK TEST] $endpoint - FUNCIONA (${response.statusCode})');
      } catch (e) {
        if (e.toString().contains('404')) {
          print('⚠️ [QUICK TEST] $endpoint - 404 (Endpoint existe pero recurso no encontrado)');
        } else {
          print('❌ [QUICK TEST] $endpoint - ERROR: ${e.toString().substring(0, 50)}...');
        }
      }
    }
  }
}