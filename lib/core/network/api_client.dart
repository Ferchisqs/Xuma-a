// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../services/cache_service.dart';
import 'network_info.dart';

@lazySingleton
class ApiClient {
  late final Dio _dio;
  final NetworkInfo _networkInfo;
  final CacheService _cacheService;

  ApiClient(this._networkInfo, this._cacheService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: Duration(milliseconds: ApiEndpoints.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiEndpoints.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiEndpoints.sendTimeout),
      headers: ApiEndpoints.defaultHeaders,
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 1. Auth Interceptor - Manejo de tokens
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthToken(options);
          handler.next(options);
        },
        onResponse: (response, handler) async {
          await _handleTokenResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          final newError = await _handleTokenError(error);
          handler.next(newError);
        },
      ),
    );

    // 2. Retry Interceptor - Reintentar con token renovado
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final retryResponse = await _retryWithRefreshToken(error);
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
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('🌐 API: $obj'),
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
    
    try {
      return await _dio.get(
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
    
    try {
      return await _dio.post(
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
    
    try {
      return await _dio.put(
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
    
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== GESTIÓN DE TOKENS ====================

  Future<void> _addAuthToken(RequestOptions options) async {
    // No agregar token para endpoints de autenticación
    final authEndpoints = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.refreshToken,
    ];
    
    final isAuthEndpoint = authEndpoints.any((endpoint) => 
      options.path.contains(endpoint));
    
    if (!isAuthEndpoint) {
      final token = await _cacheService.get<String>('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
  }

  Future<void> _handleTokenResponse(Response response) async {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      
      // Guardar tokens de la respuesta
      await _saveTokensFromResponse(data);
    }
  }

  Future<DioException> _handleTokenError(DioException error) async {
    if (error.response?.statusCode == 401) {
      // Token expirado, limpiar tokens
      await _clearAllTokens();
    }
    return error;
  }

  Future<Response?> _retryWithRefreshToken(DioException error) async {
    try {
      final refreshToken = await _cacheService.get<String>('refresh_token');
      if (refreshToken == null) return null;

      // Intentar renovar token
      final refreshResponse = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}), // Sin token para refresh
      );

      if (refreshResponse.statusCode == 200) {
        // Guardar nuevos tokens
        await _saveTokensFromResponse(refreshResponse.data);
        
        // Reintentar request original con nuevo token
        final newToken = await _cacheService.get<String>('access_token');
        final originalRequest = error.requestOptions;
        originalRequest.headers['Authorization'] = 'Bearer $newToken';
        
        return await _dio.fetch(originalRequest);
      }
    } catch (e) {
      print('❌ Error renovando token: $e');
      await _clearAllTokens();
    }
    
    return null;
  }

  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    // Buscar tokens en diferentes formatos de respuesta
    String? accessToken;
    String? refreshToken;
    
    // Formato 1: tokens directos
    if (data.containsKey('token')) {
      accessToken = data['token'];
    } else if (data.containsKey('accessToken')) {
      accessToken = data['accessToken'];
    } else if (data.containsKey('access_token')) {
      accessToken = data['access_token'];
    }
    
    if (data.containsKey('refreshToken')) {
      refreshToken = data['refreshToken'];
    } else if (data.containsKey('refresh_token')) {
      refreshToken = data['refresh_token'];
    }
    
    // Formato 2: tokens anidados
    if (data.containsKey('tokens')) {
      final tokens = data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        accessToken ??= tokens['accessToken'] ?? tokens['access_token'];
        refreshToken ??= tokens['refreshToken'] ?? tokens['refresh_token'];
      }
    }
    
    // Guardar tokens si se encontraron
    if (accessToken != null) {
      await _cacheService.set('access_token', accessToken);
    }
    if (refreshToken != null) {
      await _cacheService.set('refresh_token', refreshToken);
    }
  }

  // ==================== MÉTODOS HELPER ====================

  Future<void> _checkConnection() async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException('Sin conexión a internet');
    }
  }

  Future<void> _clearAllTokens() async {
    await _cacheService.remove('access_token');
    await _cacheService.remove('refresh_token');
    await _cacheService.remove('cached_user');
  }

  Future<void> clearTokens() async {
    await _clearAllTokens();
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