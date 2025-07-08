// lib/features/companion/data/datasources/companion_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/companion_model.dart';
import '../models/companion_stats_model.dart';

abstract class CompanionRemoteDataSource {
  Future<List<CompanionModel>> getUserCompanions(String userId);
  Future<CompanionStatsModel> getCompanionStats(String userId);
  Future<CompanionModel> purchaseCompanion(String userId, String companionId);
  Future<CompanionModel> evolveCompanion(String userId, String companionId);
  Future<CompanionModel> feedCompanion(String userId, String companionId);
  Future<CompanionModel> loveCompanion(String userId, String companionId);
}

@Injectable(as: CompanionRemoteDataSource)
class CompanionRemoteDataSourceImpl implements CompanionRemoteDataSource {
  final ApiClient apiClient;

  CompanionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<CompanionModel>> getUserCompanions(String userId) async {
    try {
      final response = await apiClient.get('/companions/users/$userId');
      final List<dynamic> companionsJson = response.data['data'];
      return companionsJson
          .map((json) => CompanionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching companions: ${e.toString()}');
    }
  }

  @override
  Future<CompanionStatsModel> getCompanionStats(String userId) async {
    try {
      final response = await apiClient.get('/companions/users/$userId/stats');
      return CompanionStatsModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error fetching companion stats: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> purchaseCompanion(String userId, String companionId) async {
    try {
      final response = await apiClient.post(
        '/companions/purchase',
        data: {
          'userId': userId,
          'companionId': companionId,
        },
      );
      return CompanionModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error purchasing companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> evolveCompanion(String userId, String companionId) async {
    try {
      final response = await apiClient.post(
        '/companions/evolve',
        data: {
          'userId': userId,
          'companionId': companionId,
        },
      );
      return CompanionModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error evolving companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> feedCompanion(String userId, String companionId) async {
    try {
      final response = await apiClient.post(
        '/companions/feed',
        data: {
          'userId': userId,
          'companionId': companionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return CompanionModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error feeding companion: ${e.toString()}');
    }
  }

  @override
  Future<CompanionModel> loveCompanion(String userId, String companionId) async {
    try {
      final response = await apiClient.post(
        '/companions/love',
        data: {
          'userId': userId,
          'companionId': companionId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      return CompanionModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error loving companion: ${e.toString()}');
    }
  }
}