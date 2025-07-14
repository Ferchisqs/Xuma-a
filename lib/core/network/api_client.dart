// lib/core/network/api_client.dart - VERSIÓN ACTUALIZADA CON TOKEN MANAGER
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../services/cache_service.dart';
import '../services/token_manager.dart'; // 🆕 IMPORTAR TOKEN MANAGER
import 'network_info.dart';

@lazySingleton
class ApiClient {
  late final Dio _authDio;  // Para servicio de auth
  late final Dio _userDio;  // Para servicio de usuarios
  final NetworkInfo _networkInfo;
  final CacheService _cacheService;
  final TokenManager _tokenManager; // 🆕 AGREGAR TOKEN MANAGER

  // URLs de los diferentes servicios
  static const String _authServiceUrl = 'https://auth-service-production-e333.up.railway.app';
  static const String _userServiceUrl = 'https://user-service-xumaa-production.up.railway.app';

  ApiClient(
    this._networkInfo, 
    this._cacheService,
    this._tokenManager, // 🆕 INYECTAR TOKEN MANAGER
  ) {
    _setupAuthDio();
    _setupUserDio();
  }

  void _setupAuthDio() {
    _authDio = Dio(BaseOptions(
      baseUrl: _authServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.defaultHeaders,
    ));

    _setupInterceptors(_authDio, 'AUTH');
  }

  void _setupUserDio() {
    _userDio = Dio(BaseOptions(
      baseUrl: _userServiceUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.defaultHeaders,
    ));

    _setupInterceptors(_userDio, 'USER');
  }

  void _setupInterceptors(Dio dio, String serviceName) {
    // 1. Auth Interceptor - 🆕 MEJORADO CON TOKEN MANAGER
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

    // 2. Retry Interceptor - Reintentar con token renovado
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

    // 3. Logging Interceptor (solo en desarrollo)
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 [$serviceName] API: $obj'),
      ),
    );
  }

  // ==================== MÉTODOS PÚBLICOS ====================

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

  // ==================== SELECCIÓN DE DIO SEGÚN SERVICIO ====================

  Dio _getDioForPath(String path, Options? options) {
    // Si las options especifican un baseUrl, usar el servicio correspondiente
    final baseUrl = options?.extra?['baseUrl'] as String?;
    
    if (baseUrl != null) {
      if (baseUrl.contains('user-service')) {
        return _userDio;
      } else if (baseUrl.contains('auth-service')) {
        return _authDio;
      }
    }

    // Determinar por el path
    if (path.startsWith('/api/users') || path.contains('profile')) {
      return _userDio;
    } else {
      return _authDio; // Por defecto auth service
    }
  }

  // ==================== GESTIÓN DE TOKENS - 🆕 MEJORADO ====================

  Future<void> _addAuthToken(RequestOptions options, String serviceName) async {
    // No agregar token para endpoints de autenticación
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
        print('🔍 [$serviceName] Token preview: ${token.substring(0, 20)}...');
      } else {
        print('⚠️ [$serviceName] No access token available for: ${options.path}');
      }
    } else {
      print('🔍 [$serviceName] Skipping auth token for auth endpoint: ${options.path}');
    }
  }

  Future<void> _handleTokenResponse(Response response, String serviceName) async {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      
      // Solo guardar tokens del servicio de auth
      if (serviceName == 'AUTH' && _shouldSaveTokens(response.requestOptions.path)) {
        try {
          await _tokenManager.saveTokensFromResponse(data);
          print('✅ [$serviceName] Tokens saved from response');
        } catch (e) {
          print('⚠️ [$serviceName] Could not save tokens: $e');
          // No fallar por esto, solo loggear
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
      
      // Intentar renovar token usando el servicio de auth
      final refreshResponse = await _authDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      if (refreshResponse.statusCode == 200) {
        // Guardar nuevos tokens
        await _tokenManager.saveTokensFromResponse(refreshResponse.data);
        
        // Reintentar request original con nuevo token
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

  // 🆕 MÉTODOS PARA DEBUG
  Future<void> debugTokens() async {
    await _tokenManager.debugTokenInfo();
  }

  Future<bool> hasValidToken() async {
    return await _tokenManager.hasValidAccessToken();
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
    
    // Extraer mensaje de error de diferentes formatos
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