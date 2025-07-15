// lib/features/tips/data/datasources/tips_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/tip_model.dart';

abstract class TipsRemoteDataSource {
  Future<List<TipModel>> getAllTips({int page = 1, int limit = 50});
  Future<TipModel> getTipById(String id);
  Future<List<TipModel>> getTipsByCategory(String category, {int page = 1, int limit = 20});
}

@LazySingleton(as: TipsRemoteDataSource)
class TipsRemoteDataSourceImpl implements TipsRemoteDataSource {
  final ApiClient _apiClient;
  
  // URL del servicio de contenido
  static const String _contentServiceUrl = 'https://content-service-xumaa-production.up.railway.app';
  static const String _allTipsEndpoint = '/api/content/all-tips';
  static const String _tipsEndpoint = '/api/content/tips';

  TipsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<TipModel>> getAllTips({int page = 1, int limit = 50}) async {
    try {
      print('🌐 [TIPS] Fetching all tips from API...');
      print('🌐 [TIPS] URL: $_contentServiceUrl$_allTipsEndpoint');
      print('🌐 [TIPS] Params: page=$page, limit=$limit');
      
      final response = await _apiClient.get(
        _allTipsEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(extra: {'baseUrl': _contentServiceUrl}),
      );

      print('✅ [TIPS] Response received: ${response.statusCode}');
      print('📄 [TIPS] Response data type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<TipModel> tips = [];
        
        // Manejar diferentes estructuras de respuesta
        if (data is Map<String, dynamic>) {
          // Caso 1: Respuesta paginada con estructura { data: [...], total: X, page: Y }
          if (data.containsKey('data') && data['data'] is List) {
            final tipsData = data['data'] as List;
            tips = tipsData.map((tipJson) => TipModel.fromJson(tipJson)).toList();
            print('✅ [TIPS] Parsed ${tips.length} tips from paginated response');
          }
          // Caso 2: Respuesta directa con tips en la raíz
          else if (data.containsKey('tips') && data['tips'] is List) {
            final tipsData = data['tips'] as List;
            tips = tipsData.map((tipJson) => TipModel.fromJson(tipJson)).toList();
            print('✅ [TIPS] Parsed ${tips.length} tips from tips array');
          }
          // Caso 3: Respuesta con estructura diferente
          else {
            print('⚠️ [TIPS] Unexpected response structure: ${data.keys}');
            throw const ServerException('Estructura de respuesta inesperada');
          }
        }
        // Caso 4: Respuesta directa como array
        else if (data is List) {
          tips = data.map((tipJson) => TipModel.fromJson(tipJson)).toList();
          print('✅ [TIPS] Parsed ${tips.length} tips from direct array');
        }
        else {
          print('❌ [TIPS] Unexpected response type: ${data.runtimeType}');
          throw const ServerException('Tipo de respuesta inesperado');
        }

        print('🎯 [TIPS] Final tips count: ${tips.length}');
        return tips;
      } else {
        print('❌ [TIPS] HTTP Error: ${response.statusCode}');
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TIPS] Exception getting all tips: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error obteniendo tips: $e');
    }
  }

  @override
  Future<TipModel> getTipById(String id) async {
    try {
      print('🌐 [TIPS] Fetching tip by ID: $id');
      
      final response = await _apiClient.get(
        '$_tipsEndpoint/$id',
        options: Options(extra: {'baseUrl': _contentServiceUrl}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Manejar respuesta
        Map<String, dynamic> tipData;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            tipData = data['data'];
          } else {
            tipData = data;
          }
        } else {
          throw const ServerException('Formato de respuesta inválido');
        }

        final tip = TipModel.fromJson(tipData);
        print('✅ [TIPS] Tip retrieved: ${tip.title}');
        return tip;
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TIPS] Exception getting tip by ID: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error obteniendo tip: $e');
    }
  }

  @override
  Future<List<TipModel>> getTipsByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🌐 [TIPS] Fetching tips by category: $category');
      
      final response = await _apiClient.get(
        _allTipsEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
          'category': category, // Filtro por categoría si la API lo soporta
        },
        options: Options(extra: {'baseUrl': _contentServiceUrl}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<TipModel> allTips = [];
        
        // Parsear respuesta (similar a getAllTips)
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is List) {
            final tipsData = data['data'] as List;
            allTips = tipsData.map((tipJson) => TipModel.fromJson(tipJson)).toList();
          }
        } else if (data is List) {
          allTips = data.map((tipJson) => TipModel.fromJson(tipJson)).toList();
        }

        // Filtrar por categoría localmente si la API no lo soporta
        final filteredTips = allTips
            .where((tip) => tip.category.toLowerCase() == category.toLowerCase())
            .toList();

        print('✅ [TIPS] Found ${filteredTips.length} tips for category: $category');
        return filteredTips;
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TIPS] Exception getting tips by category: $e');
      if (e is ServerException) rethrow;
      throw ServerException('Error obteniendo tips por categoría: $e');
    }
  }
}