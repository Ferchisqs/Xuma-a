// lib/features/challenges/data/datasources/challenges_remote_datasource.dart - ACTUALIZADO PARA API
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/challenge_model.dart';
import '../models/user_challenge_stats_model.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../../learning/data/models/topic_model.dart'; // 🆕 IMPORT TOPIC MODEL

abstract class ChallengesRemoteDataSource {
  // 🔧 MÉTODO ACTUALIZADO - ahora usa topics del content service
  Future<List<TopicModel>> getTopics();
  
  // 🆕 NUEVOS MÉTODOS PARA CHALLENGES API
  Future<List<ChallengeModel>> getChallenges({
    ChallengeType? type,
    String? category,
  });
  Future<List<ChallengeModel>> getActiveChallenges();
  Future<ChallengeModel> getChallengeById(String id);
  Future<void> joinChallenge(String challengeId, String userId);
  Future<void> submitEvidence({
    required String userChallengeId,
    required String submissionType,
    required String contentText,
    required List<String> mediaUrls,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? measurementData,
    Map<String, dynamic>? metadata,
  });
  Future<UserChallengeStatsModel> getUserStats(String userId);
  Future<List<ChallengeModel>> getUserChallenges(String userId);
}

@Injectable(as: ChallengesRemoteDataSource)
class ChallengesRemoteDataSourceImpl implements ChallengesRemoteDataSource {
  final ApiClient apiClient;

  ChallengesRemoteDataSourceImpl(this.apiClient) {
    print('✅ [CHALLENGES REMOTE] Constructor - Challenge API datasource initialized');
  }

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING TOPICS AS CHALLENGE CATEGORIES ===');
      print('🎯 [CHALLENGES] Using content service: /api/content/topics');
      
      // 🔧 USAR EL MISMO ENDPOINT QUE LEARNING Y TRIVIA
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      
      List<dynamic> topicsJson = _extractListFromResponse(response.data, 'topics');
      print('🔍 [CHALLENGES] Found ${topicsJson.length} topics in response');
      
      if (topicsJson.isEmpty) {
        throw ServerException('No topics found in API response');
      }
      
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [CHALLENGES] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topic = TopicModel.fromJson(rawTopic);
          topics.add(topic);
          print('✅ [CHALLENGES] Parsed topic ${i + 1}: "${topic.title}"');
          
        } catch (e) {
          print('❌ [CHALLENGES] Failed to parse topic $i: $e');
          continue;
        }
      }
      
      if (topics.isEmpty) {
        throw ServerException('No valid topics could be parsed from API response');
      }
      
      print('🎉 [CHALLENGES] Successfully processed: ${topics.length} topics');
      return topics;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching topics: $e');
      throw ServerException('Failed to fetch topics from API: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getChallenges({
    ChallengeType? type,
    String? category,
  }) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING ALL CHALLENGES ===');
      print('🎯 [CHALLENGES] Type: $type, Category: $category');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges');
      
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type.name;
      if (category != null) queryParams['category'] = category;
      
      final response = await apiClient.getQuiz(
        '/api/quiz/challenges',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      List<dynamic> challengesJson = _extractListFromResponse(response.data, 'challenges');
      print('🔍 [CHALLENGES] Found ${challengesJson.length} challenges in response');
      
      if (challengesJson.isEmpty) {
        print('⚠️ [CHALLENGES] No challenges found, returning empty list');
        return [];
      }
      
      final challenges = <ChallengeModel>[];
      
      for (int i = 0; i < challengesJson.length; i++) {
        try {
          final rawChallenge = challengesJson[i];
          if (rawChallenge is! Map<String, dynamic>) {
            print('⚠️ [CHALLENGES] Challenge $i is not a Map: ${rawChallenge.runtimeType}');
            continue;
          }
          
          final adaptedChallenge = _adaptChallengeStructure(rawChallenge, i);
          final challenge = ChallengeModel.fromJson(adaptedChallenge);
          challenges.add(challenge);
          
          print('✅ [CHALLENGES] Processed challenge ${i + 1}: "${challenge.title}"');
          
        } catch (e) {
          print('❌ [CHALLENGES] Failed to parse challenge $i: $e');
          print('❌ [CHALLENGES] Challenge data: ${challengesJson[i]}');
          continue;
        }
      }
      
      print('🎉 [CHALLENGES] Successfully processed: ${challenges.length} challenges');
      return challenges;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching challenges: $e');
      throw ServerException('Failed to fetch challenges: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getActiveChallenges() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING ACTIVE CHALLENGES ===');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/active');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/active');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      List<dynamic> challengesJson = _extractListFromResponse(response.data, 'challenges');
      print('🔍 [CHALLENGES] Found ${challengesJson.length} active challenges');
      
      if (challengesJson.isEmpty) {
        return [];
      }
      
      final challenges = <ChallengeModel>[];
      
      for (int i = 0; i < challengesJson.length; i++) {
        try {
          final rawChallenge = challengesJson[i];
          if (rawChallenge is Map<String, dynamic>) {
            final adaptedChallenge = _adaptChallengeStructure(rawChallenge, i);
            final challenge = ChallengeModel.fromJson(adaptedChallenge);
            challenges.add(challenge);
            print('✅ [CHALLENGES] Processed active challenge ${i + 1}: "${challenge.title}"');
          }
        } catch (e) {
          print('❌ [CHALLENGES] Failed to parse active challenge $i: $e');
          continue;
        }
      }
      
      print('🎉 [CHALLENGES] Successfully processed: ${challenges.length} active challenges');
      return challenges;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching active challenges: $e');
      throw ServerException('Failed to fetch active challenges: ${e.toString()}');
    }
  }

  @override
  Future<ChallengeModel> getChallengeById(String id) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING CHALLENGE BY ID ===');
      print('🎯 [CHALLENGES] Challenge ID: $id');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/$id');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/$id');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      Map<String, dynamic> challengeData = _extractMapFromResponse(response.data);
      
      // Ensure challenge has required ID
      if (!challengeData.containsKey('id')) {
        challengeData['id'] = id;
      }
      
      final adaptedChallenge = _adaptChallengeStructure(challengeData, 0);
      final challenge = ChallengeModel.fromJson(adaptedChallenge);
      
      print('✅ [CHALLENGES] Successfully fetched challenge: ${challenge.title}');
      return challenge;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching challenge by ID: $e');
      throw ServerException('Failed to fetch challenge $id: ${e.toString()}');
    }
  }

  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      print('🎯 [CHALLENGES] === JOINING CHALLENGE ===');
      print('🎯 [CHALLENGES] Challenge ID: $challengeId, User ID: $userId');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/join/$challengeId');
      
      await apiClient.postQuiz(
        '/api/quiz/challenges/join/$challengeId',
        data: {
          'userId': userId,
        },
      );
      
      print('✅ [CHALLENGES] Successfully joined challenge: $challengeId');
      
    } catch (e) {
      print('❌ [CHALLENGES] Error joining challenge: $e');
      throw ServerException('Failed to join challenge: ${e.toString()}');
    }
  }

  @override
  Future<void> submitEvidence({
    required String userChallengeId,
    required String submissionType,
    required String contentText,
    required List<String> mediaUrls,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? measurementData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🎯 [CHALLENGES] === SUBMITTING EVIDENCE ===');
      print('🎯 [CHALLENGES] User Challenge ID: $userChallengeId');
      print('🎯 [CHALLENGES] Submission Type: $submissionType');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/submit-evidence');
      
      final requestData = {
        'userChallengeId': userChallengeId,
        'submissionType': submissionType,
        'contentText': contentText,
        'mediaUrls': mediaUrls,
      };
      
      if (locationData != null) {
        requestData['locationData'] = locationData;
      }
      
      if (measurementData != null) {
        requestData['measurementData'] = measurementData;
      }
      
      if (metadata != null) {
        requestData['metadata'] = metadata;
      }
      
      print('🎯 [CHALLENGES] Request Data: $requestData');
      
      await apiClient.postQuiz(
        '/api/quiz/challenges/submit-evidence',
        data: requestData,
      );
      
      print('✅ [CHALLENGES] Evidence submitted successfully');
      
    } catch (e) {
      print('❌ [CHALLENGES] Error submitting evidence: $e');
      throw ServerException('Failed to submit evidence: ${e.toString()}');
    }
  }

  @override
  Future<UserChallengeStatsModel> getUserStats(String userId) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING USER STATS ===');
      print('🎯 [CHALLENGES] User ID: $userId');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/user-challenges/$userId');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/user-challenges/$userId');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      Map<String, dynamic> statsData = _extractMapFromResponse(response.data);
      
      // Adapt stats structure if needed
      final adaptedStats = _adaptUserStatsStructure(statsData, userId);
      final stats = UserChallengeStatsModel.fromJson(adaptedStats);
      
      print('✅ [CHALLENGES] User stats fetched successfully');
      return stats;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching user stats: $e');
      throw ServerException('Failed to fetch user stats: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getUserChallenges(String userId) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING USER CHALLENGES ===');
      print('🎯 [CHALLENGES] User ID: $userId');
      print('🎯 [CHALLENGES] Endpoint: /api/quiz/challenges/user-challenges/$userId');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/user-challenges/$userId');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      
      List<dynamic> challengesJson = _extractListFromResponse(response.data, 'challenges');
      print('🔍 [CHALLENGES] Found ${challengesJson.length} user challenges');
      
      final challenges = <ChallengeModel>[];
      
      for (int i = 0; i < challengesJson.length; i++) {
        try {
          final rawChallenge = challengesJson[i];
          if (rawChallenge is Map<String, dynamic>) {
            final adaptedChallenge = _adaptChallengeStructure(rawChallenge, i);
            final challenge = ChallengeModel.fromJson(adaptedChallenge);
            challenges.add(challenge);
            print('✅ [CHALLENGES] Processed user challenge ${i + 1}: "${challenge.title}"');
          }
        } catch (e) {
          print('❌ [CHALLENGES] Failed to parse user challenge $i: $e');
          continue;
        }
      }
      
      print('🎉 [CHALLENGES] Successfully processed: ${challenges.length} user challenges');
      return challenges;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching user challenges: $e');
      throw ServerException('Failed to fetch user challenges: ${e.toString()}');
    }
  }

  // ==================== HELPER METHODS ====================

  List<dynamic> _extractListFromResponse(dynamic responseData, String preferredKey) {
    if (responseData is List) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      // Try preferred key first
      if (responseData.containsKey(preferredKey) && responseData[preferredKey] is List) {
        return responseData[preferredKey] as List<dynamic>;
      }
      
      // Try common list keys
      for (final key in ['data', 'items', 'results', preferredKey]) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key] as List<dynamic>;
        }
      }
      
      // If no list found, wrap single object in list
      return [responseData];
    }
    
    throw ServerException('Invalid response format: expected List or Map with list data');
  }

  Map<String, dynamic> _extractMapFromResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    
    if (responseData is Map && responseData['data'] is Map<String, dynamic>) {
      return responseData['data'] as Map<String, dynamic>;
    }
    
    throw ServerException('Invalid response format: expected Map<String, dynamic>');
  }

  Map<String, dynamic> _adaptChallengeStructure(
    Map<String, dynamic> serverChallenge,
    int index,
  ) {
    print('🔄 [CHALLENGES] Adapting challenge structure for index $index');
    
    // Si ya tiene la estructura correcta, devolver tal como está
    if (serverChallenge.containsKey('title') && 
        serverChallenge.containsKey('type') &&
        serverChallenge.containsKey('difficulty')) {
      print('✅ [CHALLENGES] Challenge already has correct structure');
      
      // Asegurar campos requeridos
      final adaptedChallenge = Map<String, dynamic>.from(serverChallenge);
      
      adaptedChallenge['id'] ??= 'challenge_${index + 1}';
      adaptedChallenge['isParticipating'] ??= false;
      adaptedChallenge['currentProgress'] ??= 0;
      adaptedChallenge['targetProgress'] ??= 10;
      adaptedChallenge['status'] ??= 'notStarted';
      adaptedChallenge['createdAt'] ??= DateTime.now().toIso8601String();
      
      return adaptedChallenge;
    }
    
    // Adaptar estructura del servidor a estructura esperada
    return {
      'id': serverChallenge['id'] ?? 'challenge_${index + 1}',
      'title': serverChallenge['title'] ?? serverChallenge['name'] ?? 'Challenge ${index + 1}',
      'description': serverChallenge['description'] ?? 'Challenge description',
      'category': serverChallenge['category'] ?? 'general',
      'imageUrl': serverChallenge['imageUrl'] ?? '',
      'iconCode': _getIconForCategory(serverChallenge['category'] ?? 'general'),
      'type': _mapChallengeType(serverChallenge['type']),
      'difficulty': _mapChallengeDifficulty(serverChallenge['difficulty']),
      'totalPoints': serverChallenge['points'] ?? serverChallenge['totalPoints'] ?? 100,
      'currentProgress': serverChallenge['currentProgress'] ?? 0,
      'targetProgress': serverChallenge['targetProgress'] ?? serverChallenge['target'] ?? 10,
      'status': _mapChallengeStatus(serverChallenge['status']),
      'startDate': serverChallenge['startDate'] ?? DateTime.now().toIso8601String(),
      'endDate': serverChallenge['endDate'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'requirements': _extractRequirements(serverChallenge),
      'rewards': _extractRewards(serverChallenge),
      'isParticipating': serverChallenge['isParticipating'] ?? false,
      'completedAt': serverChallenge['completedAt'],
      'createdAt': serverChallenge['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _adaptUserStatsStructure(
    Map<String, dynamic> serverStats,
    String userId,
  ) {
    return {
      'totalChallengesCompleted': serverStats['completed'] ?? serverStats['totalCompleted'] ?? 0,
      'currentActiveChallenges': serverStats['active'] ?? serverStats['currentActive'] ?? 0,
      'totalPointsEarned': serverStats['points'] ?? serverStats['totalPoints'] ?? 0,
      'currentStreak': serverStats['streak'] ?? serverStats['currentStreak'] ?? 0,
      'bestStreak': serverStats['bestStreak'] ?? serverStats['maxStreak'] ?? 0,
      'currentRank': serverStats['rank'] ?? 'Eco Principiante',
      'rankPosition': serverStats['position'] ?? serverStats['rankPosition'] ?? 1000,
      'achievedBadges': serverStats['badges'] ?? serverStats['achievedBadges'] ?? [],
      'categoryProgress': serverStats['categoryProgress'] ?? {},
      'lastActivityDate': serverStats['lastActivity'] ?? DateTime.now().toIso8601String(),
    };
  }

  String _mapChallengeType(dynamic type) {
    if (type == null) return 'daily';
    final typeStr = type.toString().toLowerCase();
    
    switch (typeStr) {
      case 'weekly':
        return 'weekly';
      case 'monthly':
        return 'monthly';
      case 'special':
        return 'special';
      default:
        return 'daily';
    }
  }

  String _mapChallengeDifficulty(dynamic difficulty) {
    if (difficulty == null) return 'easy';
    final difficultyStr = difficulty.toString().toLowerCase();
    
    switch (difficultyStr) {
      case 'medium':
      case 'medio':
        return 'medium';
      case 'hard':
      case 'difícil':
      case 'dificil':
        return 'hard';
      default:
        return 'easy';
    }
  }

  String _mapChallengeStatus(dynamic status) {
    if (status == null) return 'notStarted';
    final statusStr = status.toString().toLowerCase();
    
    switch (statusStr) {
      case 'active':
      case 'activo':
        return 'active';
      case 'completed':
      case 'completado':
        return 'completed';
      case 'expired':
      case 'expirado':
        return 'expired';
      default:
        return 'notStarted';
    }
  }

  List<String> _extractRequirements(Map<String, dynamic> serverChallenge) {
    if (serverChallenge.containsKey('requirements') && serverChallenge['requirements'] is List) {
      return List<String>.from(serverChallenge['requirements']);
    }
    
    // Default requirements based on category
    final category = serverChallenge['category'] ?? 'general';
    switch (category.toLowerCase()) {
      case 'reciclaje':
        return ['Materiales reciclables', 'Contenedor apropiado'];
      case 'energia':
        return ['Dispositivos electrónicos', 'Monitor de consumo'];
      case 'agua':
        return ['Medidor de agua', 'Recipientes'];
      default:
        return ['Seguir las instrucciones', 'Tomar fotografías'];
    }
  }

  List<String> _extractRewards(Map<String, dynamic> serverChallenge) {
    if (serverChallenge.containsKey('rewards') && serverChallenge['rewards'] is List) {
      return List<String>.from(serverChallenge['rewards']);
    }
    
    final points = serverChallenge['points'] ?? serverChallenge['totalPoints'] ?? 100;
    return ['$points puntos', 'Badge de logro'];
  }

  int _getIconForCategory(String category) {
    final categoryLower = category.toLowerCase();
    
    switch (categoryLower) {
      case 'reciclaje':
      case 'recycling':
        return 0xe567; // Icons.recycling
      case 'agua':
      case 'water':
        return 0xe798; // Icons.water_drop
      case 'energia':
      case 'energy':
        return 0xe1ac; // Icons.energy_savings_leaf
      case 'compostaje':
      case 'compost':
        return 0xe1b1; // Icons.compost
      default:
        return 0xe567; // Icons.recycling
    }
  }
}