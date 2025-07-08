import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/challenge_model.dart';
import '../models/user_challenge_stats_model.dart';
import '../../domain/entities/challenge_entity.dart';

abstract class ChallengesRemoteDataSource {
  Future<List<ChallengeModel>> getChallenges({
    ChallengeType? type,
    String? category,
  });
  Future<ChallengeModel> getChallengeById(String id);
  Future<UserChallengeStatsModel> getUserStats(String userId);
  Future<void> joinChallenge(String challengeId, String userId);
  Future<void> updateProgress(String challengeId, String userId, int progress);
  Future<List<ChallengeModel>> getActiveChallenges(String userId);
  Future<List<ChallengeModel>> getCompletedChallenges(String userId);
}

@Injectable(as: ChallengesRemoteDataSource)
class ChallengesRemoteDataSourceImpl implements ChallengesRemoteDataSource {
  final ApiClient apiClient;

  ChallengesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ChallengeModel>> getChallenges({
    ChallengeType? type,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type.name;
      if (category != null) queryParams['category'] = category;

      final response = await apiClient.get(
        '/challenges',
        queryParameters: queryParams,
      );
      
      final List<dynamic> challengesJson = response.data['data'];
      return challengesJson
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching challenges: ${e.toString()}');
    }
  }

  @override
  Future<ChallengeModel> getChallengeById(String id) async {
    try {
      final response = await apiClient.get('/challenges/$id');
      return ChallengeModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error fetching challenge: ${e.toString()}');
    }
  }

  @override
  Future<UserChallengeStatsModel> getUserStats(String userId) async {
    try {
      final response = await apiClient.get('/challenges/users/$userId/stats');
      return UserChallengeStatsModel.fromJson(response.data['data']);
    } catch (e) {
      throw ServerException('Error fetching user stats: ${e.toString()}');
    }
  }

  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      await apiClient.post(
        '/challenges/$challengeId/join',
        data: {'userId': userId},
      );
    } catch (e) {
      throw ServerException('Error joining challenge: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProgress(String challengeId, String userId, int progress) async {
    try {
      await apiClient.put(
        '/challenges/$challengeId/progress',
        data: {
          'userId': userId,
          'progress': progress,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ServerException('Error updating progress: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getActiveChallenges(String userId) async {
    try {
      final response = await apiClient.get('/challenges/users/$userId/active');
      final List<dynamic> challengesJson = response.data['data'];
      return challengesJson
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching active challenges: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getCompletedChallenges(String userId) async {
    try {
      final response = await apiClient.get('/challenges/users/$userId/completed');
      final List<dynamic> challengesJson = response.data['data'];
      return challengesJson
          .map((json) => ChallengeModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Error fetching completed challenges: ${e.toString()}');
    }
  }
}