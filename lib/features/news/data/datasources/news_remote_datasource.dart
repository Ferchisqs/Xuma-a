// lib/features/news/data/datasources/news_remote_datasource.dart - VERSIÓN CORREGIDA
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
      print('🇲🇽 [NEWS API] Fetching Mexico news - Page: $page, Limit: $limit');
      
      var newsModels = await _tryFetchNews(
        query: 'clima mexico',
        language: 'es',
        limit: limit,
      );
      
      // Si no hay suficientes noticias en español, intentar en inglés
      if (newsModels.length < 3) {
        print('🔄 [NEWS API] Few Spanish results, trying English...');
        final englishNews = await _tryFetchNews(
          query: 'climate mexico',
          language: 'en',
          limit: limit,
        );
        newsModels.addAll(englishNews);
      }
      
      // Si aún no hay suficientes, intentar con términos más amplios
      if (newsModels.length < 3) {
        print('🔄 [NEWS API] Still few results, trying broader terms...');
        final broaderNews = await _tryFetchNews(
          query: 'mexico',
          language: 'es',
          limit: limit,
          category: 'environment',
        );
        newsModels.addAll(broaderNews);
      }
      
      // Remover duplicados basándose en el título
      final uniqueNews = _removeDuplicates(newsModels);
      
      print('✅ [NEWS API] Final unique articles: ${uniqueNews.length}');
      return uniqueNews;
      
    } catch (e) {
      print('❌ [NEWS API] Error in main method: $e');
      throw ServerException('Error inesperado: $e');
    }
  }

  Future<List<NewsModel>> _tryFetchNews({
    required String query,
    required String language,
    required int limit,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'apikey': _apiKey,
        'q': query,
        'language': language,
        'size': limit > 10 ? 10 : limit,
      };
      
      if (category != null) {
        queryParams['category'] = category;
      }
      
      print('🔍 [NEWS API] Trying query: $queryParams');

      final response = await _dio.get(
        '/latest',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        
        if (responseData['status'] == 'success' && responseData['results'] != null) {
          final results = responseData['results'] as List;
          print('📰 [NEWS API] Found ${results.length} articles for "$query" in $language');
          
          final newsModels = results.map((article) {
            try {
              return NewsModel.fromJson(article);
            } catch (e) {
              print('⚠️ [NEWS API] Error parsing article: $e');
              return null;
            }
          }).where((model) => model != null).cast<NewsModel>().toList();
          
          return newsModels;
        }
      }
      
      return [];
    } catch (e) {
      print('⚠️ [NEWS API] Error with query "$query": $e');
      return [];
    }
  }

  List<NewsModel> _removeDuplicates(List<NewsModel> news) {
    final seen = <String>{};
    final uniqueNews = <NewsModel>[];
    
    for (final article in news) {
      final titleKey = article.title.toLowerCase().trim();
      if (!seen.contains(titleKey)) {
        seen.add(titleKey);
        uniqueNews.add(article);
      }
    }
    
    return uniqueNews;
  }
}

