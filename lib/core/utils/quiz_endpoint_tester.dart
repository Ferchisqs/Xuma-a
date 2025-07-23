// lib/core/utils/quiz_endpoint_tester.dart - NUEVO ARCHIVO
import '../../di/injection.dart';
import '../network/api_client.dart';
import '../config/api_endpoints.dart';

class QuizEndpointTester {
  
  /// Probar todos los endpoints posibles para encontrar cuáles realmente existen
  static Future<void> testAllPossibleEndpoints() async {
    print('🔍 [ENDPOINT TEST] ===============================================');
    print('🔍 [ENDPOINT TEST] TESTING ALL POSSIBLE QUIZ ENDPOINTS');
    print('🔍 [ENDPOINT TEST] Base URL: ${ApiEndpoints.quizServiceUrl}');
    print('🔍 [ENDPOINT TEST] ===============================================');
    
    final apiClient = getIt<ApiClient>();
    final testTopicId = 'a90d3ede-42ae-4b81-a185-9336ea6e195b'; // El que falla
    
    // Lista de todos los posibles endpoints según la documentación
    final endpointsToTest = [
      // Endpoints de la documentación
      {
        'name': 'Get Quizzes by Topic (Doc)',
        'endpoint': '/by-topic/$testTopicId',
        'method': 'GET',
        'expected': 'Lista de quizzes para el topic'
      },
      {
        'name': 'Get Quiz by ID (Doc)',
        'endpoint': '/00836d1c-dc92-4fb4-a21b-c04af5ef1569', // ID del JSON
        'method': 'GET',
        'expected': 'Datos del quiz específico'
      },
      {
        'name': 'Get Questions for Quiz (Doc)',
        'endpoint': '/questions/quiz/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
        'method': 'GET',
        'expected': 'Lista de preguntas del quiz'
      },
      {
        'name': 'Get Question by ID (Doc)',
        'endpoint': '/questions/ef325182-70d8-4c18-abd0-bf037762c652',
        'method': 'GET',
        'expected': 'Datos de la pregunta específica'
      },
      {
        'name': 'Get User Progress (Doc)',
        'endpoint': '/user-progress/test-user-id',
        'method': 'GET',
        'expected': 'Progreso del usuario'
      },
      
      // Posibles variaciones de endpoints
      {
        'name': 'Topic Quizzes (Variation 1)',
        'endpoint': '/topic/$testTopicId/quizzes',
        'method': 'GET',
        'expected': 'Quizzes del topic'
      },
      {
        'name': 'Topic Quizzes (Variation 2)',  
        'endpoint': '/topics/$testTopicId/quizzes',
        'method': 'GET',
        'expected': 'Quizzes del topic'
      },
      {
        'name': 'Quizzes Root',
        'endpoint': '/quizzes',
        'method': 'GET',
        'expected': 'Todos los quizzes'
      },
      {
        'name': 'Quizzes by Topic Query',
        'endpoint': '/quizzes?topicId=$testTopicId',
        'method': 'GET',
        'expected': 'Quizzes filtrados por topic'
      },
      {
        'name': 'Health Check',
        'endpoint': '/health',
        'method': 'GET',
        'expected': 'Estado del servicio'
      },
      {
        'name': 'Root Path',
        'endpoint': '/',
        'method': 'GET',
        'expected': 'Información del servicio'
      },
      {
        'name': 'API Root',
        'endpoint': '/api',
        'method': 'GET',
        'expected': 'API info'
      },
      {
        'name': 'Quiz API Root',
        'endpoint': '/api/quiz',
        'method': 'GET',
        'expected': 'Quiz API info'
      },
    ];
    
    final results = <String, Map<String, dynamic>>{};
    
    for (int i = 0; i < endpointsToTest.length; i++) {
      final test = endpointsToTest[i];
      print('\n🔍 [ENDPOINT TEST] Testing ${i + 1}/${endpointsToTest.length}: ${test['name']}');
      print('🔍 [ENDPOINT TEST] ${test['method']} ${test['endpoint']}');
      
      final result = await _testSingleEndpoint(
        apiClient,
        test['endpoint'] as String,
        test['method'] as String,
      );
      
      results[test['endpoint'] as String] = {
        'name': test['name'],
        'method': test['method'],
        'expected': test['expected'],
        ...result,
      };
      
      // Pequeña pausa para no saturar el servidor
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Mostrar resumen de resultados
    _showTestResults(results);
    _generateRecommendations(results);
  }
  
  static Future<Map<String, dynamic>> _testSingleEndpoint(
    ApiClient apiClient,
    String endpoint,
    String method,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      late dynamic response;
      if (method == 'GET') {
        response = await apiClient.getQuiz(endpoint);
      } else if (method == 'POST') {
        response = await apiClient.postQuiz(endpoint, data: {});
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
  
  static void _showTestResults(Map<String, Map<String, dynamic>> results) {
    print('\n📊 [ENDPOINT TEST] ===============================================');
    print('📊 [ENDPOINT TEST] TEST RESULTS SUMMARY');
    print('📊 [ENDPOINT TEST] ===============================================');
    
    final successful = <String>[];
    final failed = <String>[];
    final notFound = <String>[];
    
    results.forEach((endpoint, result) {
      final status = result['status'] as String;
      final name = result['name'] as String;
      
      if (status == 'SUCCESS') {
        successful.add('✅ $name: $endpoint (${result['statusCode']})');
      } else if (result['errorType'] == 'NOT_FOUND') {
        notFound.add('❌ $name: $endpoint (404 - Not Found)');
      } else {
        failed.add('⚠️ $name: $endpoint (${result['errorType']})');
      }
    });
    
    print('\n🟢 SUCCESSFUL ENDPOINTS (${successful.length}):');
    for (final success in successful) {
      print('   $success');
    }
    
    print('\n🔴 NOT FOUND ENDPOINTS (${notFound.length}):');
    for (final notFound404 in notFound) {
      print('   $notFound404');
    }
    
    print('\n⚠️ OTHER ERRORS (${failed.length}):');
    for (final fail in failed) {
      print('   $fail');
    }
    
    print('\n📊 [ENDPOINT TEST] ===============================================');
  }
  
  static void _generateRecommendations(Map<String, Map<String, dynamic>> results) {
    print('\n💡 [RECOMMENDATIONS] ===============================================');
    print('💡 [RECOMMENDATIONS] WHAT TO DO NEXT');
    print('💡 [RECOMMENDATIONS] ===============================================');
    
    final successful = results.values.where((r) => r['status'] == 'SUCCESS').toList();
    final notFound = results.values.where((r) => r['errorType'] == 'NOT_FOUND').toList();
    
    if (successful.isEmpty) {
      print('💡 [RECOMMENDATIONS] ❌ NO ENDPOINTS ARE WORKING!');
      print('💡 [RECOMMENDATIONS]');
      print('💡 [RECOMMENDATIONS] 1. CHECK SERVER STATUS:');
      print('💡 [RECOMMENDATIONS]    - Is ${ApiEndpoints.quizServiceUrl} running?');
      print('💡 [RECOMMENDATIONS]    - Try accessing it directly in a browser');
      print('💡 [RECOMMENDATIONS]');
      print('💡 [RECOMMENDATIONS] 2. VERIFY URL:');
      print('💡 [RECOMMENDATIONS]    - Current: ${ApiEndpoints.quizServiceUrl}');
      print('💡 [RECOMMENDATIONS]    - Is this the correct production URL?');
      print('💡 [RECOMMENDATIONS]');
      print('💡 [RECOMMENDATIONS] 3. CHECK RAILWAY DEPLOYMENT:');
      print('💡 [RECOMMENDATIONS]    - Is the quiz-challenge-service deployed?');
      print('💡 [RECOMMENDATIONS]    - Check Railway dashboard for errors');
      
    } else {
      print('💡 [RECOMMENDATIONS] ✅ ${successful.length} endpoints are working!');
      print('💡 [RECOMMENDATIONS]');
      print('💡 [RECOMMENDATIONS] WORKING ENDPOINTS:');
      for (final working in successful) {
        print('💡 [RECOMMENDATIONS]    - ${working['name']}');
      }
      
      if (notFound.isNotEmpty) {
        print('💡 [RECOMMENDATIONS]');
        print('💡 [RECOMMENDATIONS] ❌ MISSING ENDPOINTS:');
        for (final missing in notFound) {
          print('💡 [RECOMMENDATIONS]    - ${missing['name']}');
        }
        print('💡 [RECOMMENDATIONS]');
        print('💡 [RECOMMENDATIONS] ACTION NEEDED:');
        print('💡 [RECOMMENDATIONS]    - Update your server to implement missing endpoints');
        print('💡 [RECOMMENDATIONS]    - OR use alternative endpoints that work');
      }
    }
    
    print('💡 [RECOMMENDATIONS] ===============================================');
  }
  
  /// Test específico para endpoints que según la documentación deberían existir
  static Future<void> testDocumentedEndpoints() async {
    print('📋 [DOC TEST] Testing endpoints from API documentation...');
    
    final apiClient = getIt<ApiClient>();
    
    // Test con datos reales de la documentación
    final documentedTests = [
      {
        'name': 'Get Quiz by ID (from doc)',
        'endpoint': '/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
        'description': 'Should return quiz data'
      },
      {
        'name': 'Get Questions for Quiz (from doc)',
        'endpoint': '/questions/quiz/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
        'description': 'Should return array of questions'
      },
      {
        'name': 'Get Question by ID (from doc)',
        'endpoint': '/questions/ef325182-70d8-4c18-abd0-bf037762c652',
        'description': 'Should return specific question data'
      },
    ];
    
    for (final test in documentedTests) {
      print('\n📋 [DOC TEST] Testing: ${test['name']}');
      print('📋 [DOC TEST] Endpoint: ${test['endpoint']}');
      print('📋 [DOC TEST] Expected: ${test['description']}');
      
      try {
        final response = await apiClient.getQuiz(test['endpoint'] as String);
        print('✅ [DOC TEST] SUCCESS - Status: ${response.statusCode}');
        print('✅ [DOC TEST] Data type: ${response.data.runtimeType}');
        
        if (response.data is List) {
          print('✅ [DOC TEST] Array with ${(response.data as List).length} items');
        } else if (response.data is Map) {
          final keys = (response.data as Map).keys.take(3).join(', ');
          print('✅ [DOC TEST] Object with keys: $keys...');
        }
        
      } catch (e) {
        if (e.toString().contains('404')) {
          print('❌ [DOC TEST] NOT FOUND - Endpoint does not exist on server');
        } else {
          print('❌ [DOC TEST] ERROR - $e');
        }
      }
    }
  }
  
  /// Comando rápido para probar solo los endpoints más importantes
  static Future<void> quickTest() async {
    print('⚡ [QUICK TEST] Testing most important endpoints...');
    
    final apiClient = getIt<ApiClient>();
    final testTopicId = 'a90d3ede-42ae-4b81-a185-9336ea6e195b';
    
    final quickTests = [
      '/by-topic/$testTopicId',
      '/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
      '/questions/quiz/00836d1c-dc92-4fb4-a21b-c04af5ef1569',
      '/quizzes',
      '/',
    ];
    
    for (final endpoint in quickTests) {
      try {
        final response = await apiClient.getQuiz(endpoint);
        print('✅ [QUICK TEST] $endpoint - Works! (${response.statusCode})');
      } catch (e) {
        if (e.toString().contains('404')) {
          print('❌ [QUICK TEST] $endpoint - Not Found (404)');
        } else {
          print('⚠️ [QUICK TEST] $endpoint - Error: ${e.toString().substring(0, 50)}...');
        }
      }
    }
  }
}