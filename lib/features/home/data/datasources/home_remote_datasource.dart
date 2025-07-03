import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/eco_tip_model.dart';
import '../models/user_stats_model.dart';

abstract class HomeRemoteDataSource {
  Future<EcoTipModel> getDailyTip();
  Future<UserStatsModel> getUserStats();
  Future<bool> updateUserActivity(String activityType);
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  HomeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<EcoTipModel> getDailyTip() async {
    try {
      final response = await _apiClient.get('/api/eco-tips/daily');
      return EcoTipModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Failed to fetch daily tip: $e');
    }
  }

  @override
  Future<UserStatsModel> getUserStats() async {
    try {
      final response = await _apiClient.get('/api/user/stats');
      return UserStatsModel.fromJson(response.data);
    } catch (e) {
      throw ServerException('Failed to fetch user stats: $e');
    }
  }

  @override
  Future<bool> updateUserActivity(String activityType) async {
    try {
      final response = await _apiClient.post('/api/user/activity', data: {
        'activity_type': activityType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      throw ServerException('Failed to update user activity: $e');
    }
  }
}