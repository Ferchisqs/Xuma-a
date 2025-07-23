// lib/core/utils/quiz_debug_helper.dart - NUEVO ARCHIVO DE DEBUG
import '../../di/injection.dart';
import '../network/api_client.dart';
import '../config/api_endpoints.dart';

class QuizDebugHelper {
  
  /// Probar todos los endpoints de quiz con un topicId específico
  static Future<void> debugAllQuizEndpoints(String topicId) async {
    print('🧪 [QUIZ DEBUG] ===============================================');
    print('🧪 [QUIZ DEBUG] TESTING ALL QUIZ ENDPOINTS');
    print('🧪 [QUIZ DEBUG] Topic ID: $topicId');
    print('🧪 [QUIZ DEBUG] Quiz Service URL: ${ApiEndpoints.quizServiceUrl}');
    print('🧪 [QUIZ DEBUG] ===============================================');
    
    final apiClient = getIt<ApiClient>();
    
    // 1. Probar /by-topic/{topicId}
    await _testEndpoint(
      'Get Quizzes by Topic',
      () => apiClient.getQuiz('/by-topic/$topicId'),
      apiClient,
    );
    
    // 2. Probar con un quiz ID de ejemplo
    const exampleQuizId = 'quiz_example_001';
    
    await _testEndpoint(
      'Get Quiz by ID',
      () => apiClient.getQuiz('/$exampleQuizId'),
      apiClient,
    );
    
    // 3. Probar obtener preguntas
    await _testEndpoint(
      'Get Quiz Questions',
      () => apiClient.getQuiz('/questions/quiz/$exampleQuizId'),
      apiClient,
    );
    
    // 4. Probar iniciar sesión
    await _testEndpoint(
      'Start Quiz Session',
      () => apiClient.postQuiz('/start', data: {
        'quizId': exampleQuizId,
        'userId': 'test_user_123',
      }),
      apiClient,
    );
    
    // 5. Probar obtener resultados
    const exampleSessionId = 'session_example_001';
    await _testEndpoint(
      'Get Quiz Results',
      () => apiClient.getQuiz('/results/$exampleSessionId', queryParameters: {
        'userId': 'test_user_123',
      }),
      apiClient,
    );
    
    // 6. Probar progreso del usuario
    await _testEndpoint(
      'Get User Progress',
      () => apiClient.getQuiz('/user-progress/test_user_123'),
      apiClient,
    );
    
    print('🧪 [QUIZ DEBUG] ===============================================');
    print('🧪 [QUIZ DEBUG] QUIZ ENDPOINTS TEST COMPLETED');
    print('🧪 [QUIZ DEBUG] ===============================================');
  }
  
  static Future<void> _testEndpoint(
    String testName,
    Future<dynamic> Function() testFunction,
    ApiClient apiClient,
  ) async {
    print('\n🧪 [QUIZ DEBUG] Testing: $testName');
    
    try {
      final stopwatch = Stopwatch()..start();
      final response = await testFunction();
      stopwatch.stop();
      
      print('✅ [QUIZ DEBUG] $testName - SUCCESS');
      print('   Status: ${response.statusCode}');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');
      print('   Data Type: ${response.data.runtimeType}');
      
      if (response.data is Map) {
        final data = response.data as Map;
        print('   Keys: ${data.keys.take(5).toList()}${data.keys.length > 5 ? '...' : ''}');
      } else if (response.data is List) {
        final data = response.data as List;
        print('   Items Count: ${data.length}');
      }
      
    } catch (e) {
      print('❌ [QUIZ DEBUG] $testName - ERROR: $e');
    }
  }
  
  /// Probar endpoints con datos reales del sistema
  static Future<void> testWithRealData() async {
    print('🔍 [QUIZ DEBUG] Testing with real data...');
    
    final apiClient = getIt<ApiClient>();
    
    try {
      // 1. Primero obtener topics reales
      print('🔍 [QUIZ DEBUG] 1. Getting real topics...');
      final topicsResponse = await apiClient.getContent('/api/content/topics');
      
      if (topicsResponse.data is List && (topicsResponse.data as List).isNotEmpty) {
        final topics = topicsResponse.data as List;
        final firstTopic = topics.first;
        final topicId = firstTopic['id']?.toString() ?? 'unknown';
        
        print('✅ [QUIZ DEBUG] Found topic: $topicId');
        
        // 2. Probar obtener quizzes para este topic real
        print('🔍 [QUIZ DEBUG] 2. Getting quizzes for real topic...');
        await _testEndpoint(
          'Real Topic Quizzes',
          () => apiClient.getQuiz('/by-topic/$topicId'),
          apiClient,
        );
        
      } else {
        print('⚠️ [QUIZ DEBUG] No topics found, skipping real data test');
      }
      
    } catch (e) {
      print('❌ [QUIZ DEBUG] Error in real data test: $e');
    }
  }
  
  /// Verificar configuración de URLs
  static void verifyConfiguration() {
    print('🔧 [QUIZ DEBUG] ===============================================');
    print('🔧 [QUIZ DEBUG] VERIFYING QUIZ CONFIGURATION');
    print('🔧 [QUIZ DEBUG] ===============================================');
    
    print('🔧 [QUIZ DEBUG] Quiz Service URL: ${ApiEndpoints.quizServiceUrl}');
    print('🔧 [QUIZ DEBUG] Content Service URL: ${ApiEndpoints.contentServiceUrl}');
    
    // Verificar headers
    print('🔧 [QUIZ DEBUG] Quiz Headers:');
    ApiEndpoints.quizHeaders.forEach((key, value) {
      print('   $key: $value');
    });
    
    // Verificar métodos de detección
    final testEndpoints = [
      '/by-topic/test',
      '/start',
      '/submit-answer',
      '/results/test',
      '/questions/quiz/test',
      '/user-progress/test',
    ];
    
    print('🔧 [QUIZ DEBUG] Endpoint Detection:');
    for (final endpoint in testEndpoints) {
      final isDetected = ApiEndpoints.isQuizEndpoint(endpoint);
      print('   $endpoint: ${isDetected ? '✅ DETECTED' : '❌ NOT DETECTED'}');
    }
    
    print('🔧 [QUIZ DEBUG] ===============================================');
  }
  
  /// Test específico para el endpoint que ya funciona vs los que no
  static Future<void> compareWorkingVsNonWorking() async {
    print('🔍 [QUIZ DEBUG] ===============================================');
    print('🔍 [QUIZ DEBUG] COMPARING WORKING VS NON-WORKING ENDPOINTS');
    print('🔍 [QUIZ DEBUG] ===============================================');
    
    final apiClient = getIt<ApiClient>();
    
    // 1. Endpoint que SÍ funciona
    print('\n🟢 [QUIZ DEBUG] Testing WORKING endpoint: /api/content/topics');
    try {
      final workingResponse = await apiClient.getContent('/api/content/topics');
      print('✅ [QUIZ DEBUG] Working endpoint - Status: ${workingResponse.statusCode}');
      print('✅ [QUIZ DEBUG] Working endpoint - Data: ${workingResponse.data.runtimeType}');
    } catch (e) {
      print('❌ [QUIZ DEBUG] Working endpoint failed: $e');
    }
    
    // 2. Endpoint que NO funciona
    print('\n🔴 [QUIZ DEBUG] Testing NON-WORKING endpoint: /by-topic/test');
    try {
      final nonWorkingResponse = await apiClient.getQuiz('/by-topic/test');
      print('✅ [QUIZ DEBUG] Non-working endpoint - Status: ${nonWorkingResponse.statusCode}');
      print('✅ [QUIZ DEBUG] Non-working endpoint - Data: ${nonWorkingResponse.data.runtimeType}');
    } catch (e) {
      print('❌ [QUIZ DEBUG] Non-working endpoint failed: $e');
      
      // Analizar el error
      if (e.toString().contains('404')) {
        print('💡 [QUIZ DEBUG] 404 Error - Endpoint might not exist on server');
      } else if (e.toString().contains('Connection')) {
        print('💡 [QUIZ DEBUG] Connection Error - Server might be down');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        print('💡 [QUIZ DEBUG] Auth Error - Check authentication');
      }
    }
    
    print('🔍 [QUIZ DEBUG] ===============================================');
  }
  
  /// Generar recomendaciones basadas en los errores
  static void generateRecommendations() {
    print('💡 [QUIZ DEBUG] ===============================================');
    print('💡 [QUIZ DEBUG] RECOMMENDATIONS FOR FIXING QUIZ ENDPOINTS');
    print('💡 [QUIZ DEBUG] ===============================================');
    print('💡 [QUIZ DEBUG]');
    print('💡 [QUIZ DEBUG] 1. VERIFY SERVER ENDPOINTS:');
    print('💡 [QUIZ DEBUG]    - Check if ${ApiEndpoints.quizServiceUrl} is accessible');
    print('💡 [QUIZ DEBUG]    - Verify these endpoints exist on the server:');
    print('💡 [QUIZ DEBUG]      • GET /by-topic/{topicId}');
    print('💡 [QUIZ DEBUG]      • GET /{id}');
    print('💡 [QUIZ DEBUG]      • GET /questions/quiz/{quizId}');
    print('💡 [QUIZ DEBUG]      • POST /start');
    print('💡 [QUIZ DEBUG]      • GET /results/{sessionId}');
    print('💡 [QUIZ DEBUG]      • GET /user-progress/{userId}');
    print('💡 [QUIZ DEBUG]');
    print('💡 [QUIZ DEBUG] 2. CHECK SERVER CONFIGURATION:');
    print('💡 [QUIZ DEBUG]    - Ensure quiz-challenge-service is running');
    print('💡 [QUIZ DEBUG]    - Verify CORS settings allow your domain');
    print('💡 [QUIZ DEBUG]    - Check if authentication is required');
    print('💡 [QUIZ DEBUG]');
    print('💡 [QUIZ DEBUG] 3. VERIFY API DOCUMENTATION:');
    print('💡 [QUIZ DEBUG]    - Confirm endpoint paths match server implementation');
    print('💡 [QUIZ DEBUG]    - Check required parameters and request format');
    print('💡 [QUIZ DEBUG]    - Verify response format matches expected structure');
    print('💡 [QUIZ DEBUG]');
    print('💡 [QUIZ DEBUG] 4. TEST WITH POSTMAN/CURL:');
    print('💡 [QUIZ DEBUG]    - Test endpoints directly outside the app');
    print('💡 [QUIZ DEBUG]    - curl ${ApiEndpoints.quizServiceUrl}/by-topic/test_topic');
    print('💡 [QUIZ DEBUG]');
    print('💡 [QUIZ DEBUG] Run QuizDebugHelper.compareWorkingVsNonWorking()');
    print('💡 [QUIZ DEBUG] to compare working vs non-working endpoints.');
    print('💡 [QUIZ DEBUG] ===============================================');
  }
}