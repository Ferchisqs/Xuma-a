// lib/features/trivia/data/datasources/quiz_remote_datasource.dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trivia_question_model.dart';
import '../models/quiz_session_model.dart';

abstract class QuizRemoteDataSource {
  // Obtener quizzes por tema
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

  @override
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [QUIZ] Fetching quizzes for topic: $topicId');
      
      final response = await apiClient.get('/by-topic/$topicId');
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['data'] is List) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      
      throw ServerException('Invalid response format for quizzes by topic');
    } catch (e) {
      print('❌ [QUIZ] Error fetching quizzes by topic: $e');
      throw ServerException('Error fetching quizzes by topic: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getQuizById(String quizId) async {
    try {
      print('🎯 [QUIZ] Fetching quiz: $quizId');
      
      final response = await apiClient.get('/$quizId');
      
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      
      throw ServerException('Invalid response format for quiz by ID');
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz by ID: $e');
      throw ServerException('Error fetching quiz by ID: ${e.toString()}');
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
      }
      
      throw ServerException('Invalid response format for quiz session');
    } catch (e) {
      print('❌ [QUIZ] Error starting quiz session: $e');
      throw ServerException('Error starting quiz session: ${e.toString()}');
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
      throw ServerException('Error submitting answer: ${e.toString()}');
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
      }
      
      throw ServerException('Invalid response format for quiz results');
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz results: $e');
      throw ServerException('Error fetching quiz results: ${e.toString()}');
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
      } else {
        throw ServerException('Invalid response format for quiz questions');
      }
      
      return questionsJson
          .map((json) => TriviaQuestionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [QUIZ] Error fetching quiz questions: $e');
      throw ServerException('Error fetching quiz questions: ${e.toString()}');
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
      
      throw ServerException('Invalid response format for user progress');
    } catch (e) {
      print('❌ [QUIZ] Error fetching user progress: $e');
      throw ServerException('Error fetching user progress: ${e.toString()}');
    }
  }
}