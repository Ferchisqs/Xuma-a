// lib/core/network/api_client.dart - ACTUALIZADO CON QUIZ SERVICE
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../services/cache_service.dart';
import '../services/token_manager.dart';
import 'network_info.dart';

@lazySingleton
class ApiClient {
  late final Dio _authDio;     
  late final Dio _userDio;     
  late final Dio _contentDio;  
  late final Dio _gamificationDio;
  late final Dio _quizDio;
  late final Dio _mediaDio;
  final NetworkInfo _networkInfo;
  final CacheService _cacheService;
  final TokenManager _tokenManager;

  ApiClient(
    this._networkInfo, 
    this._cacheService,
    this._tokenManager,
  ) {
    _setupAuthDio();
    _setupUserDio();
    _setupContentDio();
    _setupGamificationDio();
    _setupQuizDio();
    _setupMediaDio();

  }

void _setupMediaDio() {
  _mediaDio = Dio(BaseOptions(
    baseUrl: 'https://media-service-production-6446.up.railway.app', // Tu URL de media service
    connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
    receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
    sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  _setupInterceptors(_mediaDio, 'MEDIA');
}
  void _setupAuthDio() {
    _authDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.authServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.defaultHeaders,
    ));

    _setupInterceptors(_authDio, 'AUTH');
  }

  void _setupUserDio() {
    _userDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.userServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.defaultHeaders,
    ));

    _setupInterceptors(_userDio, 'USER');
  }

  void _setupContentDio() {
    _contentDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.contentServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.contentHeaders,
    ));

    _setupInterceptors(_contentDio, 'CONTENT');
  }

  void _setupGamificationDio() {
    _gamificationDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.gamificationServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.gamificationHeaders,
    ));

    _setupInterceptors(_gamificationDio, 'GAMIFICATION');
  }

  void _setupQuizDio() {
    _quizDio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.quizServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.quizHeaders,
    ));

    _setupInterceptors(_quizDio, 'QUIZ');
  }

  void _setupInterceptors(Dio dio, String serviceName) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthToken(options, serviceName);
          handler.next(options);
        },
        onResponse: (response, handler) async {
          await _handleTokenResponse(response, serviceName);
          handler.next(response);
        },
        onError: (error, handler) async {
          final newError = await _handleTokenError(error);
          handler.next(newError);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final retryResponse = await _retryWithRefreshToken(error, dio);
            if (retryResponse != null) {
              handler.resolve(retryResponse);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );

    // Logging Interceptor
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 [$serviceName] API: $obj'),
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnection();
    
    final dio = _getDioForPath(path, options);
    
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnection();
    
    final dio = _getDioForPath(path, options);
    
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnection();
    
    final dio = _getDioForPath(path, options);
    
    try {
      return await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnection();
    
    final dio = _getDioForPath(path, options);
    
    try {
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnection();
    
    final dio = _getDioForPath(path, options);
    
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Dio _getDioForPath(String path, Options? options) {
    final baseUrl = options?.extra?['baseUrl'] as String?;
    
    if (baseUrl != null) {
      if (baseUrl.contains('quiz-challenge-service')) {
        print('🧠 [API CLIENT] Using QUIZ service for: $path');
        return _quizDio;
      } else if (baseUrl.contains('gamification-service')) {
        print('🎮 [API CLIENT] Using GAMIFICATION service for: $path');
        return _gamificationDio;
      } else if (baseUrl.contains('content-service')) {
        print('🎯 [API CLIENT] Using CONTENT service for: $path');
        return _contentDio;
      } else if (baseUrl.contains('user-service')) {
        print('👤 [API CLIENT] Using USER service for: $path');
        return _userDio;
      } else if (baseUrl.contains('auth-service')) {
        print('🔐 [API CLIENT] Using AUTH service for: $path');
        return _authDio;
      }
       if (baseUrl.contains('media-service-production')) {
      print('🎬 [API CLIENT] Using MEDIA service for: $path');
      return _mediaDio;
    }
    }

    if (ApiEndpoints.isQuizEndpoint(path) || 
        path.startsWith('/api/quiz/') || 
        path.contains('/api/quiz/')) {
      print('🧠 [API CLIENT] Auto-detected QUIZ service for: $path');
      return _quizDio;
    } else if (ApiEndpoints.isGamificationEndpoint(path)) {
      print('🎮 [API CLIENT] Auto-detected GAMIFICATION service for: $path');
      return _gamificationDio;
    } else if (ApiEndpoints.isContentEndpoint(path)) {
      print('🎯 [API CLIENT] Auto-detected CONTENT service for: $path');
      return _contentDio;
    } else if (ApiEndpoints.isUserEndpoint(path)) {
      print('👤 [API CLIENT] Auto-detected USER service for: $path');
      return _userDio;
    } else if (ApiEndpoints.isAuthEndpoint(path)) {
      print('🔐 [API CLIENT] Auto-detected AUTH service for: $path');
      return _authDio;
    }
      if (path.startsWith('/api/media/') || path.contains('/api/media/')) {
    print('🎬 [API CLIENT] Auto-detected MEDIA service for: $path');
    return _mediaDio;
  }
  

    print('🔐 [API CLIENT] Using default AUTH service for: $path');
    return _authDio;
  }

  Future<Response> uploadToGamification(
  String endpoint, {
  required FormData formData,
}) async {
  await _checkConnection();
  
  print('📤 [API CLIENT] Gamification upload: $endpoint');
  print('📤 [API CLIENT] Full URL: ${ApiEndpoints.gamificationServiceUrl}$endpoint');
  
  try {
    final response = await _gamificationDio.post(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          ...ApiEndpoints.gamificationHeaders,
        },
      ),
    );
    
    print('✅ [API CLIENT] Gamification upload successful: ${response.statusCode}');
    return response;
  } on DioException catch (e) {
    print('❌ [API CLIENT] Gamification upload error: $e');
    throw _handleDioError(e);
  }
}


// Método getMedia() mejorado para api_client.dart
Future<Response> getMedia(String endpoint) async {
  await _checkConnection();
  
  print('🎬 [API CLIENT] === MEDIA REQUEST WITH AUTH ===');
  print('🎬 [API CLIENT] Endpoint: $endpoint');
  
  try {
    // 🔧 OBTENER TOKEN DE AUTENTICACIÓN
    final token = await _tokenManager.getAccessToken();
    print('🎬 [API CLIENT] Has auth token: ${token != null}');
    
    if (token == null) {
      throw Exception('No authentication token available for media service');
    }
    
    // 🔧 USAR EL _mediaDio QUE YA ESTÁ CONFIGURADO
    print('🎬 [API CLIENT] Using configured _mediaDio');
    print('🎬 [API CLIENT] Media service base URL: ${_mediaDio.options.baseUrl}');
    print('🎬 [API CLIENT] Full URL: ${_mediaDio.options.baseUrl}$endpoint');
    
    final response = await _mediaDio.get(
      endpoint,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    print('✅ [API CLIENT] Media request successful: ${response.statusCode}');
    print('✅ [API CLIENT] Response data type: ${response.data.runtimeType}');
    
    // 🔧 DEBUG DE LA RESPUESTA
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      print('✅ [API CLIENT] Response keys: ${data.keys.toList()}');
      
      if (data.containsKey('data')) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          print('✅ [API CLIENT] Inner data keys: ${innerData.keys.toList()}');
          print('✅ [API CLIENT] Has publicUrl: ${innerData.containsKey('publicUrl')}');
          if (innerData.containsKey('publicUrl')) {
            print('✅ [API CLIENT] publicUrl: ${innerData['publicUrl']}');
          }
        }
      }
    }
    
    return response;
    
  } on DioException catch (e) {
    print('❌ [API CLIENT] Media DioException: ${e.type}');
    print('❌ [API CLIENT] Status code: ${e.response?.statusCode}');
    print('❌ [API CLIENT] Error message: ${e.message}');
    print('❌ [API CLIENT] Response data: ${e.response?.data}');
    
    // 🔧 MANEJO ESPECÍFICO DE ERRORES DE MEDIA
    if (e.response?.statusCode == 401) {
      print('🔑 [API CLIENT] Media service authentication failed');
      print('🔑 [API CLIENT] Token may be expired or invalid');
      
      // Intentar refrescar token automáticamente
      try {
        print('🔄 [API CLIENT] Attempting to refresh token for media request...');
        final refreshed = await _retryWithRefreshToken(e, _mediaDio);
        if (refreshed != null) {
          print('✅ [API CLIENT] Token refreshed, media request successful');
          return refreshed;
        }
      } catch (refreshError) {
        print('❌ [API CLIENT] Token refresh failed: $refreshError');
      }
    } else if (e.response?.statusCode == 403) {
      print('🚫 [API CLIENT] Media service access forbidden');
    } else if (e.response?.statusCode == 404) {
      print('🔍 [API CLIENT] Media not found on service');
    }
    
    throw _handleDioError(e);
  } catch (e) {
    print('❌ [API CLIENT] Unexpected media error: $e');
    throw Exception('Error inesperado en media: $e');
  }
}

  Future<void> _handleTokenResponse(Response response, String serviceName) async {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      
      if (serviceName == 'AUTH' && _shouldSaveTokens(response.requestOptions.path)) {
        try {
          await _tokenManager.saveTokensFromResponse(data);
          print('✅ [$serviceName] Tokens saved from response');
        } catch (e) {
          print('⚠️ [$serviceName] Could not save tokens: $e');
        }
      }
    }
  }

  bool _shouldSaveTokens(String path) {
    final tokenSavingEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refreshToken,
    ];
    
    return tokenSavingEndpoints.any((endpoint) => path.contains(endpoint));
  }

  Future<Response?> _retryWithRefreshToken(DioException error, Dio dio) async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        print('⚠️ No refresh token available for retry');
        return null;
      }

      print('🔄 Attempting to refresh token...');
      
      final refreshResponse = await _authDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      if (refreshResponse.statusCode == 200) {
        await _tokenManager.saveTokensFromResponse(refreshResponse.data);
        
        final newToken = await _tokenManager.getAccessToken();
        if (newToken != null) {
          final originalRequest = error.requestOptions;
          originalRequest.headers['Authorization'] = 'Bearer $newToken';
          
          print('✅ Token refreshed, retrying original request');
          return await dio.fetch(originalRequest);
        }
      }
    } catch (e) {
      print('❌ Error renovando token: $e');
      await _tokenManager.clearAllTokens();
    }
    
    return null;
  }

  Future<DioException> _handleTokenError(DioException error) async {
    if (error.response?.statusCode == 401) {
      print('⚠️ Token expired or invalid, clearing tokens');
      await _tokenManager.clearAllTokens();
    }
    return error;
  }

  Future<void> _checkConnection() async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException('Sin conexión a internet');
    }
  }

  // Métodos específicos para Quiz Service
 Future<Response> getQuiz(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true,
  }) async {
    print('🧠 [API CLIENT] === QUIZ GET REQUEST ===');
    print('🧠 [API CLIENT] Raw endpoint: $endpoint');
    
    try {
      // Corregir endpoint para que SIEMPRE tenga el prefijo correcto
      String correctedEndpoint = endpoint;
      if (!endpoint.startsWith('/api/quiz/')) {
        if (endpoint.startsWith('/api/')) {
          // Si ya tiene /api/ pero no /api/quiz/, reemplazar
          correctedEndpoint = endpoint.replaceFirst('/api/', '/api/quiz/');
        } else if (endpoint.startsWith('/')) {
          // Si empieza con /, agregar /api/quiz
          correctedEndpoint = '/api/quiz$endpoint';
        } else {
          // Si no tiene /, agregar /api/quiz/
          correctedEndpoint = '/api/quiz/$endpoint';
        }
      }
      
      print('🧠 [API CLIENT] Corrected endpoint: $correctedEndpoint');
      print('🧠 [API CLIENT] Full URL: ${ApiEndpoints.quizServiceUrl}$correctedEndpoint');
      print('🧠 [API CLIENT] Query params: $queryParameters');
      print('🧠 [API CLIENT] Require auth: $requireAuth');
      
      final response = await get(
        correctedEndpoint,
        queryParameters: queryParameters,
        options: Options(
          extra: {'baseUrl': ApiEndpoints.quizServiceUrl},
          headers: requireAuth ? ApiEndpoints.quizHeaders : {
            ...ApiEndpoints.quizHeaders,
            'Authorization': null,
          },
        ),
      );
      
      print('✅ [API CLIENT] Quiz GET successful');
      print('✅ [API CLIENT] Status: ${response.statusCode}');
      print('✅ [API CLIENT] Response type: ${response.data.runtimeType}');
      
      // Debug response structure
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        print('✅ [API CLIENT] Response keys: ${data.keys.take(10).toList()}');
      } else if (response.data is List) {
        final data = response.data as List;
        print('✅ [API CLIENT] Response items: ${data.length}');
      }
      
      return response;
    } catch (e) {
      print('❌ [API CLIENT] Quiz GET error: $e');
      
      // Debug específico para errores
      if (e.toString().contains('404')) {
        print('💡 [API CLIENT] 404 Error - Check if endpoint exists on Quiz Service');
        print('💡 [API CLIENT] Expected URL: ${ApiEndpoints.quizServiceUrl}');
      } else if (e.toString().contains('401')) {
        print('💡 [API CLIENT] 401 Error - Check authentication token');
      } else if (e.toString().contains('500')) {
        print('💡 [API CLIENT] 500 Error - Quiz Service internal error');
      } else if (e.toString().contains('connection')) {
        print('💡 [API CLIENT] Connection Error - Check if Quiz Service is running');
      }
      
      rethrow;
    }
  }

 Future<Response> postQuiz(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    print('🧠 [API CLIENT] === QUIZ POST REQUEST ===');
    print('🧠 [API CLIENT] Raw endpoint: $endpoint');
    print('🧠 [API CLIENT] Data: $data');
    
    try {
      // Corregir endpoint igual que en GET
      String correctedEndpoint = endpoint;
      if (!endpoint.startsWith('/api/quiz/')) {
        if (endpoint.startsWith('/api/')) {
          correctedEndpoint = endpoint.replaceFirst('/api/', '/api/quiz/');
        } else if (endpoint.startsWith('/')) {
          correctedEndpoint = '/api/quiz$endpoint';
        } else {
          correctedEndpoint = '/api/quiz/$endpoint';
        }
      }
      
      print('🧠 [API CLIENT] Corrected endpoint: $correctedEndpoint');
      print('🧠 [API CLIENT] Full URL: ${ApiEndpoints.quizServiceUrl}$correctedEndpoint');
      
      final response = await post(
        correctedEndpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          extra: {'baseUrl': ApiEndpoints.quizServiceUrl},
          headers: ApiEndpoints.quizHeaders,
        ),
      );
      
      print('✅ [API CLIENT] Quiz POST successful');
      print('✅ [API CLIENT] Status: ${response.statusCode}');
      print('✅ [API CLIENT] Response: ${response.data}');
      
      return response;
    } catch (e) {
      print('❌ [API CLIENT] Quiz POST error: $e');
      
      // Debug específico para errores POST
      if (e.toString().contains('400')) {
        print('💡 [API CLIENT] 400 Error - Check request data format');
        print('💡 [API CLIENT] Sent data: $data');
      } else if (e.toString().contains('422')) {
        print('💡 [API CLIENT] 422 Error - Validation failed');
      }
      
      rethrow;
    }
  }
  // Métodos específicos para Gamificación
  Future<Response> getGamification(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true,
  }) async {
    print('🎮 [API CLIENT] Gamification request: $endpoint');
    
    return await get(
      endpoint,
      queryParameters: queryParameters,
      options: Options(
        extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl},
        headers: requireAuth ? null : {'Authorization': null},
      ),
    );
  }

  Future<Response> postGamification(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    print('🎮 [API CLIENT] Gamification post: $endpoint');
    
    return await post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
    );
  }
// Agrega este método a tu clase ApiClient

Future<void> _addAuthToken(RequestOptions options, String serviceName) async {
  try {
    // Solo agregar token si no se ha excluido explícitamente
    if (options.headers['Authorization'] != null && options.headers['Authorization'] == null) {
      // Si Authorization está explícitamente establecido como null, no agregar token
      print('🔓 [$serviceName] Authorization explicitly disabled for: ${options.path}');
      options.headers.remove('Authorization');
      return;
    }

    final token = await _tokenManager.getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 [$serviceName] Auth token added for: ${options.path}');
    } else {
      print('⚠️ [$serviceName] No auth token available for: ${options.path}');
      
      // Para servicios que requieren autenticación, no eliminar el header
      // Dejar que el servidor responda con 401 si es necesario
      if (serviceName != 'CONTENT') {
        // Content service puede funcionar sin auth para algunos endpoints
        print('🔐 [$serviceName] Service requires auth but no token available');
      }
    }
  } catch (e) {
    print('❌ [$serviceName] Error adding auth token: $e');
    // No lanzar error aquí, dejar que la request continúe
  }
}
  Future<Response> patchGamification(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    print('🎮 [API CLIENT] Gamification patch: $endpoint');
    
    return await patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'baseUrl': ApiEndpoints.gamificationServiceUrl}),
    );
  }

  // Métodos existentes de contenido
  Future<Response> getContent(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = false,
  }) async {
    print('🎯 [API CLIENT] Content request: $endpoint');
    
    return await get(
      endpoint,
      queryParameters: queryParameters,
      options: Options(
        extra: {'baseUrl': ApiEndpoints.contentServiceUrl},
        headers: requireAuth ? null : {'Authorization': null},
      ),
    );
  }

  Future<Response> postContent(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    print('🎯 [API CLIENT] Content post: $endpoint');
    
    return await post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'baseUrl': ApiEndpoints.contentServiceUrl}),
    );
  }

  // Media service methods
  Future<Response> getMedia(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    print('📁 [API CLIENT] Media get: $endpoint');
    
    return await get(
      endpoint,
      queryParameters: queryParameters,
      options: Options(extra: {'baseUrl': 'https://media-service-production-6446.up.railway.app'}),
    );
  }

  Future<Response> postMedia(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    print('📁 [API CLIENT] Media post: $endpoint');
    
    return await post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: Options(extra: {'baseUrl': 'https://media-service-production-6446.up.railway.app'}),
    );
  }

  ServerException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException('Tiempo de conexión agotado');

      case DioExceptionType.connectionError:
        return const ServerException('Sin conexión a internet');

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada');

      default:
        return ServerException('Error inesperado: ${error.message}');
    }
  }

  ServerException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;
    
    String message = 'Error del servidor';
    
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? 
                data['error'] ?? 
                data['msg'] ?? 
                message;
    } else if (data is String) {
      message = data;
    }
    
    switch (statusCode) {
      case 400:
        return ServerException('Datos inválidos: $message');
      case 401:
        return const AuthException('Credenciales inválidas o sesión expirada');
      case 403:
        return const ServerException('No tienes permisos para esta acción');
      case 404:
        return const ServerException('Recurso no encontrado');
      case 422:
        return ServerException('Error de validación: $message');
      case 429:
        return const ServerException('Demasiadas solicitudes. Intenta más tarde');
      case 500:
        return const ServerException('Error interno del servidor');
      case 502:
        return const ServerException('Servidor no disponible');
      case 503:
        return const ServerException('Servicio temporalmente no disponible');
      default:
        return ServerException('$message (Código: $statusCode)');
    }
  }

  Future<void> clearTokens() async {
    await _tokenManager.clearAllTokens();
  }

  Future<void> debugTokens() async {
    await _tokenManager.debugTokenInfo();
  }

  Future<bool> hasValidToken() async {
    return await _tokenManager.hasValidAccessToken();
  }
}