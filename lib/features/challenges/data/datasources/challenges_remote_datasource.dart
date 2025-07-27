// lib/features/challenges/data/datasources/challenges_remote_datasource.dart - CORREGIDO PARA API REAL
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/challenge_model.dart';
import '../models/user_challenge_stats_model.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../../learning/data/models/topic_model.dart';

abstract class ChallengesRemoteDataSource {
  // Obtener categorías (topics) del content service
  Future<List<TopicModel>> getTopics();
  
  // 🆕 ENDPOINTS REALES DE CHALLENGES API
  Future<List<ChallengeModel>> getAllChallenges();
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
  Future<List<ChallengeModel>> getUserChallenges(String userId);
  Future<UserChallengeStatsModel> getUserStats(String userId);
  Future<List<Map<String, dynamic>>> getPendingValidations();
  Future<void> validateSubmission(String submissionId, int validationScore, String validationNotes);
}

@Injectable(as: ChallengesRemoteDataSource)
class ChallengesRemoteDataSourceImpl implements ChallengesRemoteDataSource {
  final ApiClient apiClient;

  ChallengesRemoteDataSourceImpl(this.apiClient) {
    print('✅ [CHALLENGES REMOTE] Constructor - Real Challenge API datasource initialized');
  }

  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING TOPICS AS CATEGORIES ===');
      print('🎯 [CHALLENGES] Using content service: /api/content/topics');
      
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
  Future<List<ChallengeModel>> getAllChallenges() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING ALL CHALLENGES ===');
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data Type: ${response.data.runtimeType}');
      
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
          
          final adaptedChallenge = _adaptChallengeFromAPI(rawChallenge, i);
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
      print('❌ [CHALLENGES] Error fetching all challenges: $e');
      throw ServerException('Failed to fetch challenges: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getActiveChallenges() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING ACTIVE CHALLENGES ===');
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges/active');
      
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
            final adaptedChallenge = _adaptChallengeFromAPI(rawChallenge, i);
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
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges/$id');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/$id');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      Map<String, dynamic> challengeData = _extractMapFromResponse(response.data);
      
      // Ensure challenge has required ID
      if (!challengeData.containsKey('id')) {
        challengeData['id'] = id;
      }
      
      final adaptedChallenge = _adaptChallengeFromAPI(challengeData, 0);
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
      print('🎯 [CHALLENGES] Endpoint: POST /api/quiz/challenges/join/$challengeId');
      
      final requestData = {
        'userId': userId,
      };
      
      print('🎯 [CHALLENGES] Request Data: $requestData');
      
      final response = await apiClient.postQuiz(
        '/api/quiz/challenges/join/$challengeId',
        data: requestData,
      );
      
      print('✅ [CHALLENGES] Successfully joined challenge: $challengeId');
      print('✅ [CHALLENGES] Response: ${response.data}');
      
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
      print('🎯 [CHALLENGES] Endpoint: POST /api/quiz/challenges/submit-evidence');
      
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
      
      final response = await apiClient.postQuiz(
        '/api/quiz/challenges/submit-evidence',
        data: requestData,
      );
      
      print('✅ [CHALLENGES] Evidence submitted successfully');
      print('✅ [CHALLENGES] Response: ${response.data}');
      
    } catch (e) {
      print('❌ [CHALLENGES] Error submitting evidence: $e');
      throw ServerException('Failed to submit evidence: ${e.toString()}');
    }
  }

  @override
  Future<List<ChallengeModel>> getUserChallenges(String userId) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING USER CHALLENGES ===');
      print('🎯 [CHALLENGES] User ID: $userId');
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges/user-challenges/$userId');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/user-challenges/$userId');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      
      List<dynamic> challengesJson = _extractListFromResponse(response.data, 'challenges');
      print('🔍 [CHALLENGES] Found ${challengesJson.length} user challenges');
      
      final challenges = <ChallengeModel>[];
      
      for (int i = 0; i < challengesJson.length; i++) {
        try {
          final rawChallenge = challengesJson[i];
          if (rawChallenge is Map<String, dynamic>) {
            final adaptedChallenge = _adaptChallengeFromAPI(rawChallenge, i);
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

  @override
  Future<UserChallengeStatsModel> getUserStats(String userId) async {
    try {
      print('🎯 [CHALLENGES] === FETCHING USER STATS ===');
      print('🎯 [CHALLENGES] User ID: $userId');
      // Nota: Este endpoint puede necesitar ser diferente según tu API
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges/user-challenges/$userId');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/user-challenges/$userId');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      print('🎯 [CHALLENGES] Response Data: ${response.data}');
      
      Map<String, dynamic> statsData = _extractMapFromResponse(response.data);
      
      // Adapt stats structure if needed
      final adaptedStats = _adaptUserStatsFromAPI(statsData, userId);
      final stats = UserChallengeStatsModel.fromJson(adaptedStats);
      
      print('✅ [CHALLENGES] User stats fetched successfully');
      return stats;
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching user stats: $e');
      throw ServerException('Failed to fetch user stats: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingValidations() async {
    try {
      print('🎯 [CHALLENGES] === FETCHING PENDING VALIDATIONS ===');
      print('🎯 [CHALLENGES] Endpoint: GET /api/quiz/challenges/pending-validation');
      
      final response = await apiClient.getQuiz('/api/quiz/challenges/pending-validation');
      
      print('🎯 [CHALLENGES] Response Status: ${response.statusCode}');
      
      List<dynamic> validationsJson = _extractListFromResponse(response.data, 'validations');
      print('🔍 [CHALLENGES] Found ${validationsJson.length} pending validations');
      
      return validationsJson.cast<Map<String, dynamic>>();
      
    } catch (e) {
      print('❌ [CHALLENGES] Error fetching pending validations: $e');
      throw ServerException('Failed to fetch pending validations: ${e.toString()}');
    }
  }

  @override
  Future<void> validateSubmission(String submissionId, int validationScore, String validationNotes) async {
    try {
      print('🎯 [CHALLENGES] === VALIDATING SUBMISSION ===');
      print('🎯 [CHALLENGES] Submission ID: $submissionId');
      print('🎯 [CHALLENGES] Endpoint: POST /api/quiz/challenges/validate/$submissionId');
      
      final requestData = {
        'validationScore': validationScore,
        'validationNotes': validationNotes,
      };
      
      print('🎯 [CHALLENGES] Request Data: $requestData');
      
      final response = await apiClient.postQuiz(
        '/api/quiz/challenges/validate/$submissionId',
        data: requestData,
      );
      
      print('✅ [CHALLENGES] Submission validated successfully');
      print('✅ [CHALLENGES] Response: ${response.data}');
      
    } catch (e) {
      print('❌ [CHALLENGES] Error validating submission: $e');
      throw ServerException('Failed to validate submission: ${e.toString()}');
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

  Map<String, dynamic> _adaptChallengeFromAPI(
  Map<String, dynamic> apiChallenge,
  int index,
) {
  print('🔄 [CHALLENGES] Adapting challenge structure from API for index $index');
  print('🔄 [CHALLENGES] Raw API data: $apiChallenge');
  
  // ===== MAPEAR CAMPOS DE TU API REAL =====
  
  // 1. INSTRUCCIONES - Extraer del objeto instructions
  List<String> instructions = [];
  if (apiChallenge['instructions'] != null) {
    final instructionsObj = apiChallenge['instructions'];
    if (instructionsObj is Map<String, dynamic> && instructionsObj['steps'] is List) {
      final steps = instructionsObj['steps'] as List;
      instructions = steps.where((step) => step != null && step.toString().trim().isNotEmpty).map((step) => step.toString()).toList();
    }
  }
  
  // 2. VALIDACIÓN - Extraer del objeto validationCriteria
  List<String> evidenceRequired = [];
  if (apiChallenge['validationCriteria'] != null) {
    final validationObj = apiChallenge['validationCriteria'];
    if (validationObj is Map<String, dynamic> && validationObj['requiredEvidence'] is List) {
      final evidence = validationObj['requiredEvidence'] as List;
      evidenceRequired = evidence.where((ev) => ev != null && ev.toString().trim().isNotEmpty).map((ev) => ev.toString()).toList();
    }
  }
  
  // 3. FECHAS - Convertir strings ISO a DateTime
  DateTime? startDate;
  DateTime? endDate;
  try {
    if (apiChallenge['startDate'] != null) {
      startDate = DateTime.parse(apiChallenge['startDate']);
    }
    if (apiChallenge['endDate'] != null) {
      endDate = DateTime.parse(apiChallenge['endDate']);
    }
  } catch (e) {
    print('⚠️ [CHALLENGES] Error parsing dates: $e');
  }
  
  // 4. RESTRICCIONES DE EDAD
  int? minAge;
  int? maxAge;
  if (apiChallenge['ageRestrictions'] != null) {
    final ageObj = apiChallenge['ageRestrictions'];
    if (ageObj is Map<String, dynamic>) {
      minAge = ageObj['minAge'];
      maxAge = ageObj['maxAge'];
    }
  }
  
  // 5. MAPEAR A ESTRUCTURA ESPERADA
  return {
    // ===== CAMPOS BÁSICOS =====
    'id': apiChallenge['id'] ?? 'challenge_${index + 1}',
    'title': apiChallenge['title'] ?? 'Challenge ${index + 1}',
    'description': apiChallenge['description'] ?? 'Challenge description from API',
    'category': apiChallenge['category'] ?? 'general',
    
    // ===== CAMPOS DESDE TU API =====
    'instructions': instructions, // ✅ AGREGADO
    'difficulty': apiChallenge['difficulty'] ?? 'easy', // ✅ AGREGADO
    'pointsReward': apiChallenge['pointsReward'] ?? 100, // ✅ AGREGADO (mapear a totalPoints)
    'estimatedDurationDays': apiChallenge['estimatedDurationDays'] ?? 7, // ✅ AGREGADO
    'validationType': apiChallenge['validationType'] ?? 'photo', // ✅ AGREGADO
    'requiredEvidence': evidenceRequired, // ✅ AGREGADO (para requirements)
    'maxParticipants': apiChallenge['maxParticipants'] ?? 100, // ✅ AGREGADO
    'currentParticipants': apiChallenge['currentParticipants'] ?? 0, // ✅ AGREGADO
    'minAge': minAge, // ✅ AGREGADO
    'maxAge': maxAge, // ✅ AGREGADO
    
    // ===== CAMPOS MAPEADOS =====
    'imageUrl': apiChallenge['imageUrl'] ?? '',
    'iconCode': _getIconForCategory(apiChallenge['category'] ?? 'general'),
    'type': _mapChallengeType(apiChallenge['challengeType'] ?? 'daily'),
    'totalPoints': apiChallenge['pointsReward'] ?? 100, // Mapear desde pointsReward
    'currentProgress': 0, // Usuario aún no participa
    'targetProgress': _calculateTargetProgress(apiChallenge),
    'status': _mapChallengeStatus('notStarted'), // Usuario no ha empezado
    'startDate': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    'endDate': endDate?.toIso8601String() ?? DateTime.now().add(Duration(days: apiChallenge['estimatedDurationDays'] ?? 7)).toIso8601String(),
    'requirements': _buildRequirements(apiChallenge, evidenceRequired),
    'rewards': _buildRewards(apiChallenge),
    'isParticipating': false, // Usuario no participa inicialmente
    'completedAt': null,
    'createdAt': apiChallenge['createdAt'] ?? DateTime.now().toIso8601String(),
  };
}


  Map<String, dynamic> _adaptUserStatsFromAPI(
    Map<String, dynamic> apiStats,
    String userId,
  ) {
    return {
      'totalChallengesCompleted': apiStats['completed'] ?? apiStats['totalCompleted'] ?? 0,
      'currentActiveChallenges': apiStats['active'] ?? apiStats['currentActive'] ?? 0,
      'totalPointsEarned': apiStats['points'] ?? apiStats['totalPoints'] ?? 0,
      'currentStreak': apiStats['streak'] ?? apiStats['currentStreak'] ?? 0,
      'bestStreak': apiStats['bestStreak'] ?? apiStats['maxStreak'] ?? 0,
      'currentRank': apiStats['rank'] ?? 'Eco Principiante',
      'rankPosition': apiStats['position'] ?? apiStats['rankPosition'] ?? 1000,
      'achievedBadges': apiStats['badges'] ?? apiStats['achievedBadges'] ?? [],
      'categoryProgress': apiStats['categoryProgress'] ?? {},
      'lastActivityDate': apiStats['lastActivity'] ?? DateTime.now().toIso8601String(),
    };
  }

  String _mapChallengeType(dynamic type) {
    if (type == null) return 'daily';
    final typeStr = type.toString().toLowerCase();
    
    switch (typeStr) {
      case 'weekly':
      case 'semanal':
        return 'weekly';
      case 'monthly':
      case 'mensual':
        return 'monthly';
      case 'special':
      case 'especial':
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

 List<String> _buildRequirements(Map<String, dynamic> apiChallenge, List<String> evidenceRequired) {
  final requirements = <String>[];
  
  // Agregar instrucciones como requisitos
  if (apiChallenge['instructions'] != null) {
    final instructionsObj = apiChallenge['instructions'];
    if (instructionsObj is Map<String, dynamic> && instructionsObj['steps'] is List) {
      final steps = instructionsObj['steps'] as List;
      for (final step in steps) {
        if (step != null && step.toString().trim().isNotEmpty) {
          requirements.add('• ${step.toString()}');
        }
      }
    }
  }
  
  // Agregar evidencia requerida
  for (final evidence in evidenceRequired) {
    if (evidence.trim().isNotEmpty) {
      requirements.add('• Evidencia: $evidence');
    }
  }
  
  // Agregar requisitos de validación
  final validationType = apiChallenge['validationType'] ?? 'photo';
  requirements.add('• Tipo de validación: $validationType');
  
  // Agregar restricciones de edad si existen
  if (apiChallenge['ageRestrictions'] != null) {
    final ageObj = apiChallenge['ageRestrictions'];
    if (ageObj is Map<String, dynamic>) {
      final minAge = ageObj['minAge'];
      final maxAge = ageObj['maxAge'];
      if (minAge != null && maxAge != null) {
        requirements.add('• Edad requerida: $minAge - $maxAge años');
      }
    }
  }
  
  // Si no hay requisitos, agregar defaults
  if (requirements.isEmpty) {
    requirements.addAll([
      '• Seguir las instrucciones del desafío',
      '• Tomar fotografías de evidencia',
      '• Esperar validación del equipo'
    ]);
  }
  
  return requirements;
}

List<String> _buildRewards(Map<String, dynamic> apiChallenge) {
  final rewards = <String>[];
  
  // Puntos principales
  final points = apiChallenge['pointsReward'] ?? 100;
  rewards.add('$points puntos EcoXuma');
  
  // Duración para calcular bonus
  final duration = apiChallenge['estimatedDurationDays'] ?? 7;
  if (duration <= 1) {
    rewards.add('Badge "Acción Rápida"');
  } else if (duration >= 7) {
    rewards.add('Badge "Constancia Verde"');
  }
  
  // Recompensas basadas en categoría
  final category = apiChallenge['category']?.toString().toLowerCase() ?? '';
  switch (category) {
    case 'reciclaje':
      rewards.add('Badge "Reciclador Pro"');
      rewards.add('Contribución al reciclaje comunitario');
      break;
    case 'energia':
      rewards.add('Badge "Ahorrador de Energía"');
      rewards.add('Impacto en reducción de CO2');
      break;
    case 'agua':
      rewards.add('Badge "Guardián del Agua"');
      rewards.add('Litros de agua ahorrados');
      break;
    case 'compostaje':
      rewards.add('Badge "Maestro Composta"');
      rewards.add('Kg de residuos orgánicos aprovechados');
      break;
    default:
      rewards.add('Badge de logro');
      rewards.add('Contribución al medio ambiente');
  }
  
  return rewards;
}

  String _mapChallengeStatus(dynamic status) {
    if (status == null) return 'notStarted';
    final statusStr = status.toString().toLowerCase();
    
    switch (statusStr) {
      case 'active':
      case 'activo':
      case 'in_progress':
        return 'active';
      case 'completed':
      case 'completado':
      case 'finished':
        return 'completed';
      case 'expired':
      case 'expirado':
        return 'expired';
      default:
        return 'notStarted';
    }
  }

  List<String> _extractRequirements(Map<String, dynamic> apiChallenge) {
    if (apiChallenge.containsKey('requirements') && apiChallenge['requirements'] is List) {
      return List<String>.from(apiChallenge['requirements']);
    }
    
    // Default requirements based on category
    final category = apiChallenge['category'] ?? 'general';
    switch (category.toLowerCase()) {
      case 'reciclaje':
        return ['Materiales reciclables', 'Contenedor apropiado', 'Foto de confirmación'];
      case 'energia':
        return ['Dispositivos electrónicos', 'Monitor de consumo', 'Evidencia fotográfica'];
      case 'agua':
        return ['Medidor de agua', 'Recipientes', 'Registro fotográfico'];
      default:
        return ['Seguir las instrucciones', 'Tomar fotografías de evidencia', 'Esperar validación'];
    }
  }

  List<String> _extractRewards(Map<String, dynamic> apiChallenge) {
    if (apiChallenge.containsKey('rewards') && apiChallenge['rewards'] is List) {
      return List<String>.from(apiChallenge['rewards']);
    }
    
    final points = apiChallenge['points'] ?? apiChallenge['totalPoints'] ?? 100;
    return ['$points puntos EcoXuma', 'Badge de logro', 'Contribución al medio ambiente'];
  }
int _calculateTargetProgress(Map<String, dynamic> apiChallenge) {
  // Si hay un target específico, usarlo
  if (apiChallenge['targetProgress'] != null) {
    return apiChallenge['targetProgress'];
  }
  
  // Si no, calcular basado en la categoría
  final category = apiChallenge['category']?.toString().toLowerCase() ?? '';
  switch (category) {
    case 'reciclaje':
      return 10; // 10 items reciclados
    case 'energia':
      return 5; // 5 acciones de ahorro
    case 'agua':
      return 7; // 7 días de ahorro
    case 'compostaje':
      return 3; // 3 veces compostar
    default:
      return 5; // Default
  }
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

  // 🆕 MÉTODOS HELPER PARA EXTRAER CAMPOS ADICIONALES
  
  List<String> _extractInstructions(Map<String, dynamic> apiChallenge) {
    if (apiChallenge.containsKey('instructions')) {
      final instructions = apiChallenge['instructions'];
      if (instructions is Map<String, dynamic> && instructions.containsKey('steps')) {
        final steps = instructions['steps'];
        if (steps is List) {
          return steps.map((step) => step?.toString() ?? '').where((step) => step.isNotEmpty).toList();
        }
      } else if (instructions is List) {
        return instructions.map((step) => step?.toString() ?? '').where((step) => step.isNotEmpty).toList();
      }
    }
    
    // Fallback a requirements si no hay instructions
    return _extractRequirements(apiChallenge);
  }
  
  Map<String, dynamic> _extractValidationCriteria(Map<String, dynamic> apiChallenge) {
    if (apiChallenge.containsKey('validationCriteria')) {
      final criteria = apiChallenge['validationCriteria'];
      if (criteria is Map<String, dynamic>) {
        return {
          'requiredEvidence': _extractRequiredEvidence(criteria),
          'minPhotos': criteria['minPhotos'] ?? 1,
          'maxPhotos': criteria['maxPhotos'] ?? 5,
        };
      }
    }
    
    return {
      'requiredEvidence': ['Foto de evidencia'],
      'minPhotos': 1,
      'maxPhotos': 5,
    };
  }
  
  List<String> _extractRequiredEvidence(Map<String, dynamic> criteria) {
    if (criteria.containsKey('requiredEvidence')) {
      final evidence = criteria['requiredEvidence'];
      if (evidence is List) {
        return evidence.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      }
    }
    return ['Foto de evidencia'];
  }
  
  Map<String, dynamic> _extractAgeRestrictions(Map<String, dynamic> apiChallenge) {
    if (apiChallenge.containsKey('ageRestrictions')) {
      final restrictions = apiChallenge['ageRestrictions'];
      if (restrictions is Map<String, dynamic>) {
        return {
          'minAge': restrictions['minAge'] ?? 8,
          'maxAge': restrictions['maxAge'] ?? 18,
        };
      }
    }
    
    return {
      'minAge': 8,
      'maxAge': 18,
    };
  }
}