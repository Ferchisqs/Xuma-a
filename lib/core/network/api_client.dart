// lib/core/network/api_client.dart - ACTUALIZADO CON CONTENT SERVICE
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../services/cache_service.dart';
import '../services/token_manager.dart';
import 'network_info.dart';

@lazySingleton
class ApiClient {
  late final Dio _authDio;     // Para servicio de auth
  late final Dio _userDio;     // Para servicio de usuarios
  late final Dio _contentDio;  // 🆕 Para servicio de contenido
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
    _setupContentDio(); // 🆕
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

  // 🆕 CONFIGURAR DIO PARA CONTENT SERVICE
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

    // 3. Logging Interceptor
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


  Dio _getDioForPath(String path, Options? options) {
    final baseUrl = options?.extra?['baseUrl'] as String?;
    
    if (baseUrl != null) {
      if (baseUrl.contains('content-service')) {
        print('🎯 [API CLIENT] Using CONTENT service for: $path');
        return _contentDio;
      } else if (baseUrl.contains('user-service')) {
        print('🎯 [API CLIENT] Using USER service for: $path');
        return _userDio;
      } else if (baseUrl.contains('auth-service')) {
        print('🎯 [API CLIENT] Using AUTH service for: $path');
        return _authDio;
      }
    }

    if (ApiEndpoints.isContentEndpoint(path)) {
      print('🎯 [API CLIENT] Auto-detected CONTENT service for: $path');
      return _contentDio;
    } else if (ApiEndpoints.isUserEndpoint(path)) {
      print('🎯 [API CLIENT] Auto-detected USER service for: $path');
      return _userDio;
    } else if (ApiEndpoints.isAuthEndpoint(path)) {
      print('🎯 [API CLIENT] Auto-detected AUTH service for: $path');
      return _authDio;
    }

    print('🎯 [API CLIENT] Using default AUTH service for: $path');
    return _authDio;
  }


  Future<void> _addAuthToken(RequestOptions options, String serviceName) async {
    final authEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refreshToken,
    ];
    
    final isAuthEndpoint = authEndpoints.any((endpoint) => 
      options.path.contains(endpoint));
    
   
    if (!isAuthEndpoint) {
      final token = await _tokenManager.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔍 [$serviceName] Added auth token to request: ${options.path}');
      } else {
        print('⚠️ [$serviceName] No access token available for: ${options.path}');
        
        // Para content service, esto podría ser normal (contenido público)
        if (serviceName == 'CONTENT') {
          print('ℹ️ [$serviceName] Content request without token (public content)');
        }
      }
    } else {
      print('🔍 [$serviceName] Skipping auth token for auth endpoint: ${options.path}');
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

  Future<DioException> _handleTokenError(DioException error) async {
    if (error.response?.statusCode == 401) {
      print('⚠️ Token expired or invalid, clearing tokens');
      await _tokenManager.clearAllTokens();
    }
    return error;
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

  // ==================== MÉTODOS HELPER ====================

  Future<void> _checkConnection() async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException('Sin conexión a internet');
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
}