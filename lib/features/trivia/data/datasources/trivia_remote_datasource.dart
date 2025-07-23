// lib/features/trivia/data/datasources/trivia_remote_datasource.dart - ACTUALIZADO PARA USAR TOPICS
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_category_entity.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_question_entity.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trivia_category_model.dart';
import '../models/trivia_question_model.dart';
import '../../../learning/data/models/topic_model.dart'; // 🆕 IMPORT TOPIC MODEL

abstract class TriviaRemoteDataSource {
  // 🔧 MÉTODO ACTUALIZADO - ahora usa topics en lugar de categorías específicas
  Future<List<TriviaCategoryModel>> getCategories();
  Future<List<TriviaQuestionModel>> getQuestionsByCategory(String categoryId);
  
  // 🆕 NUEVOS MÉTODOS PARA QUIZ ENDPOINTS
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId);
  Future<Map<String, dynamic>> getQuizById(String quizId);
}

@Injectable(as: TriviaRemoteDataSource)
class TriviaRemoteDataSourceImpl implements TriviaRemoteDataSource {
  final ApiClient apiClient;

  TriviaRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TriviaCategoryModel>> getCategories() async {
    try {
      print('🎯 [TRIVIA] === FETCHING TOPICS AS TRIVIA CATEGORIES ===');
      print('🎯 [TRIVIA] Using same endpoint as Learning: /api/content/topics');
      
      // 🔧 USAR EL MISMO ENDPOINT QUE LEARNING
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🎯 [TRIVIA] Response Status: ${response.statusCode}');
      
      List<dynamic> topicsJson = _extractTopicsFromResponse(response.data);
      
      print('🔍 [TRIVIA] Found ${topicsJson.length} topics to convert to trivia categories');
      
      if (topicsJson.isEmpty) {
        print('⚠️ [TRIVIA] No topics found, using mock categories');
        return _createMockCategories();
      }
      
      final triviaCategories = <TriviaCategoryModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [TRIVIA] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topicJson = rawTopic as Map<String, dynamic>;
          
          // 🔧 PRIMERO CREAR TOPIC MODEL, LUEGO CONVERTIR A TRIVIA CATEGORY
          final topicModel = TopicModel.fromJson(topicJson);
          final triviaCategory = _convertTopicToTriviaCategory(topicModel);
          
          triviaCategories.add(triviaCategory);
          
          print('✅ [TRIVIA] Successfully converted topic ${i + 1}: "${triviaCategory.title}"');
          
        } catch (e, stackTrace) {
          print('❌ [TRIVIA] Failed to convert topic $i: $e');
          
          try {
            final fallbackCategory = _createFallbackCategory(i, topicsJson[i]);
            triviaCategories.add(fallbackCategory);
            print('🆘 [TRIVIA] Created fallback category for index $i');
          } catch (fallbackError) {
            print('❌ [TRIVIA] Even fallback failed for topic $i: $fallbackError');
          }
        }
      }
      
      print('🎉 [TRIVIA] Successfully converted: ${triviaCategories.length}/${topicsJson.length} topics to trivia categories');
      
      if (triviaCategories.isEmpty) {
        return _createMockCategories();
      }
      
      return triviaCategories;
      
    } catch (e, stackTrace) {
      print('❌ [TRIVIA] === CRITICAL ERROR FETCHING TOPICS AS CATEGORIES ===');
      print('❌ [TRIVIA] Error: $e');
      return _createMockCategories();
    }
  }

  @override
  Future<List<TriviaQuestionModel>> getQuestionsByCategory(String categoryId) async {
    try {
      print('🎯 [TRIVIA] Getting questions for category: $categoryId');
      
      // 🔧 POR AHORA USAR DATOS MOCK, LUEGO CONECTAREMOS CON QUIZ ENDPOINTS
      // TODO: Conectar con get quiz questions cuando esté listo
      
      return _createMockQuestionsForCategory(categoryId);
      
    } catch (e) {
      print('❌ [TRIVIA] Error getting questions for category $categoryId: $e');
      return _createMockQuestionsForCategory(categoryId);
    }
  }

  // 🆕 NUEVOS MÉTODOS PARA QUIZ ENDPOINTS
  
  @override
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [TRIVIA] === FETCHING QUIZZES BY TOPIC ===');
      print('🎯 [TRIVIA] Topic ID: $topicId');
      
      // 🔧 USAR ENDPOINT ESPECÍFICO DE QUIZ
      final response = await apiClient.getQuiz('/by-topic/$topicId');
      
      print('🎯 [TRIVIA] Response Status: ${response.statusCode}');
      
      if (response.data is List) {
        final quizzes = List<Map<String, dynamic>>.from(response.data);
        print('✅ [TRIVIA] Found ${quizzes.length} quizzes for topic: $topicId');
        return quizzes;
      } else if (response.data is Map && response.data['data'] is List) {
        final quizzes = List<Map<String, dynamic>>.from(response.data['data']);
        print('✅ [TRIVIA] Found ${quizzes.length} quizzes for topic: $topicId');
        return quizzes;
      }
      
      throw ServerException('Invalid response format for quizzes by topic');
    } catch (e) {
      print('❌ [TRIVIA] Error fetching quizzes by topic: $e');
      throw ServerException('Error fetching quizzes by topic: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getQuizById(String quizId) async {
    try {
      print('🎯 [TRIVIA] === FETCHING QUIZ BY ID ===');
      print('🎯 [TRIVIA] Quiz ID: $quizId');
      
      final response = await apiClient.getQuiz('/$quizId');
      
      print('🎯 [TRIVIA] Response Status: ${response.statusCode}');
      
      if (response.data is Map<String, dynamic>) {
        print('✅ [TRIVIA] Successfully fetched quiz: $quizId');
        return response.data;
      }
      
      throw ServerException('Invalid response format for quiz by ID');
    } catch (e) {
      print('❌ [TRIVIA] Error fetching quiz by ID: $e');
      throw ServerException('Error fetching quiz by ID: ${e.toString()}');
    }
  }

  // ==================== MÉTODOS HELPER ====================

  List<dynamic> _extractTopicsFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      for (final key in ['data', 'topics', 'results', 'items']) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key] as List<dynamic>;
        }
      }
      return [responseData];
    }
    
    return [];
  }

  // 🔧 MÉTODO CLAVE: CONVERTIR TOPIC A TRIVIA CATEGORY
  TriviaCategoryModel _convertTopicToTriviaCategory(TopicModel topic) {
    print('🔄 [TRIVIA] Converting topic to trivia category: ${topic.title}');
    
    // 🎯 MAPEAR CATEGORÍAS A DIFICULTADES Y CARACTERÍSTICAS DE TRIVIA
    final triviaData = _mapTopicCategoryToTriviaData(topic.category);
    
    return TriviaCategoryModel(
      id: topic.id, // 🔧 MANTENER EL MISMO ID QUE EL TOPIC
      title: topic.title,
      description: topic.description,
      imageUrl: topic.imageUrl ?? '',
      iconCode: _getIconForCategory(topic.category),
      questionsCount: triviaData['questionsCount'],
      completedTrivias: 0, // Siempre empezar en 0
      difficulty: triviaData['difficulty'],
      pointsPerQuestion: triviaData['pointsPerQuestion'],
      timePerQuestion: triviaData['timePerQuestion'],
      createdAt: topic.createdAt,
    );
  }

  Map<String, dynamic> _mapTopicCategoryToTriviaData(String category) {
    final categoryLower = category.toLowerCase();
    
    // 🎯 MAPEAR CADA CATEGORÍA A SUS CARACTERÍSTICAS DE TRIVIA
    switch (categoryLower) {
      case 'reciclaje':
      case 'recycling':
        return {
          'questionsCount': 15,
          'difficulty': TriviaDifficulty.easy,
          'pointsPerQuestion': 5,
          'timePerQuestion': 30,
        };
      case 'agua':
      case 'water':
        return {
          'questionsCount': 12,
          'difficulty': TriviaDifficulty.medium,
          'pointsPerQuestion': 7,
          'timePerQuestion': 25,
        };
      case 'energia':
      case 'energy':
        return {
          'questionsCount': 10,
          'difficulty': TriviaDifficulty.medium,
          'pointsPerQuestion': 8,
          'timePerQuestion': 20,
        };
      case 'clima':
      case 'climate':
        return {
          'questionsCount': 12,
          'difficulty': TriviaDifficulty.hard,
          'pointsPerQuestion': 10,
          'timePerQuestion': 35,
        };
      case 'conservacion':
      case 'conservation':
        return {
          'questionsCount': 8,
          'difficulty': TriviaDifficulty.medium,
          'pointsPerQuestion': 6,
          'timePerQuestion': 25,
        };
      default:
        return {
          'questionsCount': 10,
          'difficulty': TriviaDifficulty.easy,
          'pointsPerQuestion': 5,
          'timePerQuestion': 30,
        };
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
      case 'clima':
      case 'climate':
        return 0xe1b0; // Icons.co2
      case 'conservacion':
      case 'conservation':
        return 0xe1d8; // Icons.auto_fix_high
      default:
        return 0xe1b1; // Icons.compost
    }
  }

  TriviaCategoryModel _createFallbackCategory(int index, dynamic rawData) {
    final id = rawData is Map ? (rawData['id']?.toString() ?? 'fallback_trivia_$index') : 'fallback_trivia_$index';
    final name = rawData is Map ? (rawData['name']?.toString() ?? 'Trivia $index') : 'Trivia $index';
    
    return TriviaCategoryModel(
      id: id,
      title: name,
      description: 'Trivia sobre medio ambiente y sostenibilidad.',
      imageUrl: '',
      iconCode: 0xe1b1,
      questionsCount: 10,
      completedTrivias: 0,
      difficulty: TriviaDifficulty.easy,
      pointsPerQuestion: 5,
      timePerQuestion: 30,
      createdAt: DateTime.now().subtract(Duration(days: index + 1)),
    );
  }

  // 🔧 MOCK DATA ACTUALIZADO
  List<TriviaCategoryModel> _createMockCategories() {
    return [
      TriviaCategoryModel(
        id: 'mock_trivia_reciclaje',
        title: 'Reciclaje Básico',
        description: 'Aprende sobre reciclaje y clasificación de residuos',
        imageUrl: '',
        iconCode: 0xe567,
        questionsCount: 15,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.easy,
        pointsPerQuestion: 5,
        timePerQuestion: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TriviaCategoryModel(
        id: 'mock_trivia_agua',
        title: 'Cuidado del Agua',
        description: 'Conservación y uso responsable del agua',
        imageUrl: '',
        iconCode: 0xe798,
        questionsCount: 12,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.medium,
        pointsPerQuestion: 7,
        timePerQuestion: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TriviaCategoryModel(
        id: 'mock_trivia_energia',
        title: 'Energía Sostenible',
        description: 'Aprende sobre energías renovables',
        imageUrl: '',
        iconCode: 0xe1ac,
        questionsCount: 10,
        completedTrivias: 0,
        difficulty: TriviaDifficulty.medium,
        pointsPerQuestion: 8,
        timePerQuestion: 20,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<TriviaQuestionModel> _createMockQuestionsForCategory(String categoryId) {
    // 🔧 GENERAR PREGUNTAS MOCK BASADAS EN EL CATEGORY ID
    return [
      TriviaQuestionModel(
        id: '${categoryId}_question_1',
        categoryId: categoryId,
        question: '¿Cuál es una práctica importante para el cuidado del medio ambiente?',
        options: [
          'Reciclar correctamente',
          'Desperdiciar recursos',
          'Contaminar el agua',
          'Talar árboles'
        ],
        correctAnswerIndex: 0,
        explanation: 'Reciclar correctamente es fundamental para reducir el impacto ambiental.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 5,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionModel(
        id: '${categoryId}_question_2',
        categoryId: categoryId,
        question: '¿Qué beneficio tiene el uso de energías renovables?',
        options: [
          'Aumentan la contaminación',
          'Reducen las emisiones de CO2',
          'Son más caras siempre',
          'No funcionan'
        ],
        correctAnswerIndex: 1,
        explanation: 'Las energías renovables ayudan a reducir las emisiones de gases de efecto invernadero.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.medium,
        points: 7,
        timeLimit: 25,
        createdAt: DateTime.now(),
      ),
    ];
  }
}