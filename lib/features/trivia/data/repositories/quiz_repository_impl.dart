// lib/features/trivia/data/datasources/quiz_remote_datasource.dart - CORREGIDO PARA USAR TOPICS
import 'package:injectable/injectable.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_category_entity.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_question_entity.dart';
import '../../../../core/network/api_client.dart';
import '../models/trivia_question_model.dart';
import '../models/quiz_session_model.dart';
// 🆕 IMPORT PARA USAR TOPICS DEL MÓDULO LEARNING
import '../../../learning/data/models/topic_model.dart';

abstract class QuizRemoteDataSource {
  // 🆕 USAR TOPICS EN LUGAR DE CATEGORÍAS PROPIAS
  Future<List<TopicModel>> getTopics();
  
  // Obtener quizzes por tema (usando topicId real)
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId);
  
  // Obtener quiz específico por ID
  Future<Map<String, dynamic>> getQuizById(String quizId);
  
  // Iniciar sesión de quiz
  Future<QuizSessionModel> startQuizSession({
    required String quizId,
    required String userId,
  });
  
  // Enviar respuesta a una pregunta
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  });
  
  // Obtener resultados de sesión
  Future<Map<String, dynamic>> getQuizResults({
    required String sessionId,
    required String userId,
  });
  
  // Obtener preguntas de un quiz
  Future<List<TriviaQuestionModel>> getQuizQuestions(String quizId);
  
  // Obtener progreso del usuario
  Future<Map<String, dynamic>> getUserProgress(String userId);
}

@Injectable(as: QuizRemoteDataSource)
class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final ApiClient apiClient;

  QuizRemoteDataSourceImpl(this.apiClient);

  // 🆕 IMPLEMENTAR OBTENCIÓN DE TOPICS (MISMO ENDPOINT QUE LEARNING)
  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🎯 [QUIZ] Fetching topics from content API');
      
      // 🔧 USAR EL MISMO ENDPOINT QUE LEARNING
      final response = await apiClient.getContent('/api/content/topics');
      
      print('🎯 [QUIZ] Response Status: ${response.statusCode}');
      
      List<dynamic> topicsJson = _extractTopicsFromResponse(response.data);
      
      print('🔍 [QUIZ] Found ${topicsJson.length} raw topics to process');
      
      if (topicsJson.isEmpty) {
        print('⚠️ [QUIZ] No topics found in response, creating mock data');
        return _createMockTopics();
      }
      
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [QUIZ] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topicJson = rawTopic as Map<String, dynamic>;
          final topic = TopicModel.fromJson(topicJson);
          topics.add(topic);
          
          print('✅ [QUIZ] Successfully parsed topic ${i + 1}: "${topic.title}"');
          
        } catch (e, stackTrace) {
          print('❌ [QUIZ] Failed to parse topic $i: $e');
          
          try {
            final fallbackTopic = _createFallbackTopic(i, topicsJson[i]);
            topics.add(fallbackTopic);
            print('🆘 [QUIZ] Created fallback topic for index $i');
          } catch (fallbackError) {
            print('❌ [QUIZ] Even fallback failed for topic $i: $fallbackError');
          }
        }
      }
      
      print('🎉 [QUIZ] Successfully processed: ${topics.length}/${topicsJson.length} topics');
      
      if (topics.isEmpty) {
        return _createMockTopics();
      }
      
      return topics;
      
    } catch (e, stackTrace) {
      print('❌ [QUIZ] === CRITICAL ERROR FETCHING TOPICS ===');
      print('❌ [QUIZ] Error: $e');
      return _createMockTopics();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [QUIZ] Fetching quizzes for topic: $topicId');
      
      // 🔧 USAR EL ENDPOINT CORRECTO DE QUIZ API
      final response = await apiClient.get('/by-topic/$topicId');
      
      List<dynamic> quizzesJson;
      
      if (response.data is List) {
        quizzesJson = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        quizzesJson = response.data['data'];
      } else if (response.data is Map && response.data['quizzes'] is List) {
        quizzesJson = response.data['quizzes'];
      } else {
        print('⚠️ [QUIZ] Unexpected response format for quizzes by topic: ${response.data.runtimeType}');
        return _createMockQuizzesForTopic(topicId);
      }
      
      final quizzes = <Map<String, dynamic>>[];
      
      for (int i = 0; i < quizzesJson.length; i++) {
        try {
          final rawQuiz = quizzesJson[i];
          if (rawQuiz is Map<String, dynamic>) {
            quizzes.add(rawQuiz);
            print('✅ [QUIZ] Successfully processed quiz ${i + 1}: ${rawQuiz['title'] ?? rawQuiz['name'] ?? 'Unknown'}');
          }
        } catch (e) {
          print('❌ [QUIZ] Failed to process quiz $i: $e');
        }
      }
      
      print('🎉 [QUIZ] Successfully processed: ${quizzes.length}/${quizzesJson.length} quizzes for topic $topicId');
      
      if (quizzes.isEmpty) {
        return _createMockQuizzesForTopic(topicId);
      }
      
      return quizzes;
      
    } catch (e) {
      print('❌ [QUIZ] Error fetching quizzes by topic: $e');
      // Fallback a mock data
      return _createMockQuizzesForTopic(topicId);
    }
  }

  @override
  Future<Map<String, dynamic>> getQuizById(String quizId) async {
    try {
      print('🎯 [QUIZ] Fetching quiz: $quizId');
      
      // 🔧 USAR EL ENDPOINT CORRECTO
      final response = await apiClient.get('/$quizId');
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
        return response.data['data'];
      }
      
      print('⚠️ [QUIZ] Unexpected response format for quiz by ID');
      return _createMockQuiz(quizId);
      
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz by ID: $e');
      return _createMockQuiz(quizId);
    }
  }

  @override
  Future<QuizSessionModel> startQuizSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ] Starting quiz session: $quizId for user: $userId');
      
      final response = await apiClient.post(
        '/start',
        data: {
          'quizId': quizId,
          'userId': userId,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        return QuizSessionModel.fromJson(response.data);
      } else if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
        return QuizSessionModel.fromJson(response.data['data']);
      }
      
      print('⚠️ [QUIZ] Unexpected response format for quiz session, creating mock session');
      return _createMockSession(quizId, userId);
      
    } catch (e) {
      print('❌ [QUIZ] Error starting quiz session: $e');
      // Crear sesión mock para desarrollo
      return _createMockSession(quizId, userId);
    }
  }

  @override
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  }) async {
    try {
      print('🎯 [QUIZ] Submitting answer for session: $sessionId');
      
      await apiClient.post(
        '/submit-answer',
        data: {
          'sessionId': sessionId,
          'questionId': questionId,
          'userId': userId,
          'selectedOptionId': selectedOptionId,
          'timeTakenSeconds': timeTakenSeconds,
          'answerConfidence': answerConfidence,
        },
      );
      
      print('✅ [QUIZ] Answer submitted successfully');
    } catch (e) {
      print('❌ [QUIZ] Error submitting answer: $e');
      // En desarrollo, no lanzar excepción para permitir continuar
      print('⚠️ [QUIZ] Continuing in development mode...');
    }
  }

  @override
  Future<Map<String, dynamic>> getQuizResults({
    required String sessionId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ] Fetching quiz results for session: $sessionId');
      
      final response = await apiClient.get(
        '/results/$sessionId',
        queryParameters: {
          'userId': userId,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
        return response.data['data'];
      }
      
      print('⚠️ [QUIZ] Unexpected response format for quiz results, creating mock results');
      return _createMockResults(sessionId, userId);
      
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz results: $e');
      return _createMockResults(sessionId, userId);
    }
  }

  @override
  Future<List<TriviaQuestionModel>> getQuizQuestions(String quizId) async {
    try {
      print('🎯 [QUIZ] Fetching questions for quiz: $quizId');
      
      final response = await apiClient.get('/questions/quiz/$quizId');
      
      List<dynamic> questionsJson;
      
      if (response.data is List) {
        questionsJson = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        questionsJson = response.data['data'];
      } else if (response.data is Map && response.data['questions'] is List) {
        questionsJson = response.data['questions'];
      } else {
        print('⚠️ [QUIZ] Unexpected response format for quiz questions');
        return _createMockQuestions(quizId);
      }
      
      final questions = <TriviaQuestionModel>[];
      
      for (int i = 0; i < questionsJson.length; i++) {
        try {
          final questionJson = questionsJson[i];
          if (questionJson is Map<String, dynamic>) {
            final question = TriviaQuestionModel.fromJson(questionJson);
            questions.add(question);
            print('✅ [QUIZ] Successfully parsed question ${i + 1}');
          }
        } catch (e) {
          print('❌ [QUIZ] Failed to parse question $i: $e');
        }
      }
      
      if (questions.isEmpty) {
        return _createMockQuestions(quizId);
      }
      
      return questions;
      
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz questions: $e');
      return _createMockQuestions(quizId);
    }
  }

  @override
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      print('🎯 [QUIZ] Fetching user progress: $userId');
      
      final response = await apiClient.get('/user-progress/$userId');
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      return _createMockUserProgress(userId);
    } catch (e) {
      print('❌ [QUIZ] Error fetching user progress: $e');
      return _createMockUserProgress(userId);
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

  // ==================== MOCK DATA METHODS ====================

  List<TopicModel> _createMockTopics() {
    return [
      TopicModel(
        id: 'topic_recic_001',
        title: 'Introducción al Reciclaje',
        description: 'Aprende los conceptos básicos del reciclaje y su importancia para el medio ambiente.',
        category: 'reciclaje',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TopicModel(
        id: 'topic_agua_001',
        title: 'Cuidado del Agua',
        description: 'Descubre cómo conservar este recurso vital para nuestro planeta.',
        category: 'agua',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TopicModel(
        id: 'topic_energia_001',
        title: 'Energía Sostenible',
        description: 'Conoce las fuentes de energía renovable y cómo usarlas.',
        category: 'energia',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  TopicModel _createFallbackTopic(int index, dynamic rawData) {
    final id = rawData is Map ? (rawData['id']?.toString() ?? 'fallback_topic_$index') : 'fallback_topic_$index';
    final name = rawData is Map ? (rawData['name']?.toString() ?? 'Tema de Trivia $index') : 'Tema de Trivia $index';
    
    return TopicModel(
      id: id,
      title: name,
      description: 'Tema para trivias sobre medio ambiente y sostenibilidad.',
      category: 'educacion',
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: index + 1)),
      updatedAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _createMockQuizzesForTopic(String topicId) {
    return [
      {
        'id': 'quiz_${topicId}_basic',
        'title': 'Quiz Básico',
        'description': 'Preguntas fundamentales sobre el tema',
        'questions': 10,
        'duration': 5,
        'difficulty': 'easy',
        'points': 50,
      },
      {
        'id': 'quiz_${topicId}_advanced',
        'title': 'Quiz Avanzado',
        'description': 'Desafía tus conocimientos',
        'questions': 15,
        'duration': 8,
        'difficulty': 'medium',
        'points': 100,
      },
    ];
  }

  Map<String, dynamic> _createMockQuiz(String quizId) {
    return {
      'id': quizId,
      'title': 'Quiz de Prueba',
      'description': 'Quiz de desarrollo',
      'questions': 5,
      'duration': 3,
      'difficulty': 'easy',
      'points': 25,
    };
  }

  QuizSessionModel _createMockSession(String quizId, String userId) {
    return QuizSessionModel(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      quizId: quizId,
      userId: userId,
      status: 'active',
      startedAt: DateTime.now(),
      questionsTotal: 5,
      questionsAnswered: 0,
      questionsCorrect: 0,
      pointsEarned: 0,
      percentageScore: '0%',
      passed: false,
      timeTakenSeconds: 0,
    );
  }

  Map<String, dynamic> _createMockResults(String sessionId, String userId) {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'score': 85,
      'points': 75,
      'correctAnswers': 4,
      'totalQuestions': 5,
      'accuracy': 80,
      'duration': 180,
      'passed': true,
    };
  }

  List<TriviaQuestionModel> _createMockQuestions(String quizId) {
    return [
      TriviaQuestionModel(
        id: 'q1_$quizId',
        categoryId: quizId,
        question: '¿Cuál es la mejor práctica para el cuidado del medio ambiente?',
        options: [
          'Reciclar correctamente',
          'Desperdiciar recursos',
          'Contaminar el agua',
          'Talar árboles',
        ],
        correctAnswerIndex: 0,
        explanation: 'Reciclar correctamente es una de las acciones más importantes para cuidar nuestro planeta.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 10,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
      TriviaQuestionModel(
        id: 'q2_$quizId',
        categoryId: quizId,
        question: '¿Qué significa las 3 R del reciclaje?',
        options: [
          'Reducir, Reutilizar, Reciclar',
          'Romper, Reparar, Renovar',
          'Recoger, Revisar, Repetir',
          'Regar, Respirar, Relajar',
        ],
        correctAnswerIndex: 0,
        explanation: 'Las 3 R son: Reducir el consumo, Reutilizar productos y Reciclar materiales.',
        type: QuestionType.multipleChoice,
        difficulty: TriviaDifficulty.easy,
        points: 10,
        timeLimit: 30,
        createdAt: DateTime.now(),
      ),
    ];
  }

  Map<String, dynamic> _createMockUserProgress(String userId) {
    return {
      'userId': userId,
      'totalQuizzes': 5,
      'completedQuizzes': 3,
      'totalPoints': 150,
      'averageScore': 78.5,
      'achievements': ['First Quiz', 'Score 80+'],
    };
  }
}