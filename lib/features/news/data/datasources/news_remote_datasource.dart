// lib/features/news/data/datasources/news_remote_datasource.dart
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/news_model.dart';

abstract class NewsRemoteDataSource {
  Future<List<NewsModel>> getClimateNews({
    int page = 1,
    int limit = 20,
  });
}

@LazySingleton(as: NewsRemoteDataSource)
class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  final Dio _dio;
  
  // API Key para NewsData.io
  static const String _apiKey = 'pub_05d3f62946c64ee0b928b79ec563644b';
  static const String _baseUrl = 'https://newsdata.io/api/1';

  NewsRemoteDataSourceImpl() : _dio = Dio() {
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 30000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.sendTimeout = const Duration(milliseconds: 30000);
    
    // Interceptor para logging en desarrollo
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => print('🌐 [NEWS API] $obj'),
      ),
    );
  }

  @override
  Future<List<NewsModel>> getClimateNews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🌐 [NEWS API] Fetching climate news - Page: $page, Limit: $limit');
      
      // 🔧 PARÁMETROS CORREGIDOS para evitar error 422
      final queryParams = <String, dynamic>{
        'apikey': _apiKey,
        // Simplificar la query - NewsData.io es sensible a queries complejas
        'q': 'climate change',
        // Usar solo un idioma para evitar problemas
        'language': 'en',
        // Categoría válida para el plan gratuito
        'category': 'environment',
        // Tamaño máximo permitido (API gratuita tiene límites)
        'size': limit > 10 ? 10 : limit,
      };
      
      // ⚠️ IMPORTANTE: No usar 'prioritydomain' ni 'excludeduplicate' 
      // estos parámetros pueden no estar disponibles en el plan gratuito
      
      // No usar paginación tradicional - NewsData.io usa nextPage token
      // Para el plan gratuito, solo usar la primera página
      
      print('🌐 [NEWS API] Query parameters: $queryParams');

      final response = await _dio.get(
        '/latest',
        queryParameters: queryParams,
      );

      print('🌐 [NEWS API] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('🌐 [NEWS API] Raw response structure: ${responseData.keys}');
        
        // Verificar la estructura de la respuesta
        if (responseData['status'] == 'success' && responseData['results'] != null) {
          final results = responseData['results'] as List;
          print('✅ [NEWS API] Success - Articles received: ${results.length}');
          
          // Convertir a NewsModel
          final newsModels = results.map((article) {
            try {
              return NewsModel.fromJson(article);
            } catch (e) {
              print('⚠️ [NEWS API] Error parsing article: $e');
              print('⚠️ [NEWS API] Article data: $article');
              return null;
            }
          }).where((model) => model != null).cast<NewsModel>().toList();
          
          print('✅ [NEWS API] Successfully parsed ${newsModels.length} articles');
          return newsModels;
        } else {
          print('❌ [NEWS API] Unexpected response format: $responseData');
          throw ServerException('Formato de respuesta inesperado');
        }
      } else {
        throw ServerException('Failed to fetch news: HTTP ${response.statusCode}');
      }
      
    } on DioException catch (e) {
      print('❌ [NEWS API] DioException: ${e.message}');
      print('❌ [NEWS API] Response: ${e.response?.data}');
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const ServerException('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.connectionError) {
        throw const ServerException('Sin conexión a internet');
      } else if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        // Mostrar detalles del error para debugging
        print('❌ [NEWS API] Error details: $responseData');
        
        switch (statusCode) {
          case 401:
            throw const ServerException('API key inválida');
          case 403:
            throw const ServerException('Acceso denegado a la API');
          case 422:
            // Error específico para 422 - parámetros inválidos
            final errorMessage = responseData is Map && responseData['message'] != null
                ? responseData['message']
                : 'Parámetros de búsqueda inválidos';
            throw ServerException('Error de parámetros: $errorMessage');
          case 429:
            throw const ServerException('Límite de solicitudes excedido');
          case 500:
            throw const ServerException('Error interno del servidor de noticias');
          default:
            throw ServerException('Error del servidor: $statusCode');
        }
      } else {
        throw ServerException('Error de red: ${e.message}');
      }
    } catch (e) {
      print('❌ [NEWS API] Unexpected error: $e');
      throw ServerException('Error inesperado: $e');
    }
  }
}

// 🔧 VERSIÓN ALTERNATIVA MÁS SIMPLE PARA TESTING
class NewsRemoteDataSourceSimple implements NewsRemoteDataSource {
  final Dio _dio;
  
  static const String _apiKey = 'pub_05d3f62946c64ee0b928b79ec563644b';
  static const String _baseUrl = 'https://newsdata.io/api/1';

  NewsRemoteDataSourceSimple() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: 30000);
    _dio.options.receiveTimeout = const Duration(milliseconds: 30000);
    _dio.options.sendTimeout = const Duration(milliseconds: 30000);
  }

  @override
  Future<List<NewsModel>> getClimateNews({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Versión mínima de parámetros
      final response = await _dio.get(
        '/latest',
        queryParameters: {
          'apikey': _apiKey,
          'q': 'climate',
          'language': 'en',
          'size': 10,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' && responseData['results'] != null) {
          final results = responseData['results'] as List;
          return results.map((article) => NewsModel.fromJson(article)).toList();
        }
      }
      
      throw ServerException('Failed to fetch news');
    } catch (e) {
      throw ServerException('Error fetching news: $e');
    }
  }
}