// lib/features/trivia/data/datasources/quiz_remote_datasource.dart - ARCHIVO COMPLETO
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/trivia_question_model.dart';
import '../models/quiz_session_model.dart';
import '../../../learning/data/models/topic_model.dart';

abstract class QuizRemoteDataSource {
  // 1. Obtener topics (este endpoint ya funciona)
  Future<List<TopicModel>> getTopics();
  
  // 2. Obtener quizzes por topic usando /api/quiz/by-topic/{topicId}
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId);
  
  // 3. Obtener quiz específico por ID usando /api/quiz/{id}
  Future<Map<String, dynamic>> getQuizById(String quizId);
  
  // 4. Obtener preguntas de un quiz usando /api/quiz/questions/quiz/{quizId}
  Future<List<TriviaQuestionModel>> getQuizQuestions(String quizId);
  
  // 5. Obtener pregunta específica por ID usando /api/quiz/questions/{questionId}
  Future<Map<String, dynamic>> getQuestionById(String questionId);
  
  // 6. Iniciar sesión de quiz usando /api/quiz/start
  Future<QuizSessionModel> startQuizSession({
    required String quizId,
    required String userId,
  });
  
  // 7. Enviar respuesta usando /api/quiz/submit-answer
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String userId,
    required String selectedOptionId,
    required int timeTakenSeconds,
    required int answerConfidence,
  });
  
  // 8. Obtener resultados usando /api/quiz/results/{sessionId}
  Future<Map<String, dynamic>> getQuizResults({
    required String sessionId,
    required String userId,
  });
  
  // 9. Obtener progreso del usuario usando /api/quiz/user-progress/{userId}
  Future<Map<String, dynamic>> getUserProgress(String userId);
}

@Injectable(as: QuizRemoteDataSource)
class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final ApiClient apiClient;

  QuizRemoteDataSourceImpl(this.apiClient);

  // ==================== 1. TOPICS (YA FUNCIONA) ====================
  @override
  Future<List<TopicModel>> getTopics() async {
    try {
      print('🎯 [QUIZ API] === STEP 1: FETCHING TOPICS ===');
      print('🎯 [QUIZ API] Endpoint: /api/content/topics');
      
      final response = await apiClient.getContent('/api/content/topics');
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      
      List<dynamic> topicsJson = _extractListFromResponse(response.data, 'topics');
      print('🔍 [QUIZ API] Found ${topicsJson.length} topics in response');
      
      if (topicsJson.isEmpty) {
        throw ServerException('No topics found in API response');
      }
      
      final topics = <TopicModel>[];
      
      for (int i = 0; i < topicsJson.length; i++) {
        try {
          final rawTopic = topicsJson[i];
          if (rawTopic is! Map<String, dynamic>) {
            print('⚠️ [QUIZ API] Topic $i is not a Map: ${rawTopic.runtimeType}');
            continue;
          }
          
          final topic = TopicModel.fromJson(rawTopic);
          topics.add(topic);
          print('✅ [QUIZ API] Parsed topic ${i + 1}: "${topic.title}" (ID: ${topic.id})');
          
        } catch (e) {
          print('❌ [QUIZ API] Failed to parse topic $i: $e');
          continue;
        }
      }
      
      if (topics.isEmpty) {
        throw ServerException('No valid topics could be parsed from API response');
      }
      
      print('🎉 [QUIZ API] STEP 1 COMPLETED: ${topics.length} topics');
      return topics;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching topics: $e');
      throw ServerException('Failed to fetch topics from API: ${e.toString()}');
    }
  }

  // ==================== 2. QUIZZES BY TOPIC ====================
  @override
  Future<List<Map<String, dynamic>>> getQuizzesByTopic(String topicId) async {
    try {
      print('🎯 [QUIZ API] === STEP 2: FETCHING QUIZZES BY TOPIC ===');
      print('🎯 [QUIZ API] Topic ID: $topicId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/by-topic/$topicId');
      
      // Usar el endpoint correcto del PDF
      final response = await apiClient.getQuiz('/api/quiz/by-topic/$topicId');
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data Type: ${response.data.runtimeType}');
      
      List<dynamic> quizzesJson = _extractListFromResponse(response.data, 'quizzes');
      print('🔍 [QUIZ API] Found ${quizzesJson.length} quizzes in response');
      
      if (quizzesJson.isEmpty) {
        throw ServerException('No quizzes found for topic: $topicId');
      }
      
      final quizzes = <Map<String, dynamic>>[];
      
      for (int i = 0; i < quizzesJson.length; i++) {
        try {
          final rawQuiz = quizzesJson[i];
          if (rawQuiz is Map<String, dynamic>) {
            quizzes.add(rawQuiz);
            final title = rawQuiz['title'] ?? rawQuiz['name'] ?? 'Quiz ${i + 1}';
            final id = rawQuiz['id'] ?? 'quiz_${topicId}_$i';
            print('✅ [QUIZ API] Processed quiz ${i + 1}: "$title" (ID: $id)');
          } else {
            print('⚠️ [QUIZ API] Quiz $i is not a Map: ${rawQuiz.runtimeType}');
          }
        } catch (e) {
          print('❌ [QUIZ API] Failed to process quiz $i: $e');
          continue;
        }
      }
      
      if (quizzes.isEmpty) {
        throw ServerException('No valid quizzes could be processed for topic: $topicId');
      }
      
      print('🎉 [QUIZ API] STEP 2 COMPLETED: ${quizzes.length} quizzes for topic $topicId');
      return quizzes;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching quizzes by topic: $e');
      throw ServerException('Failed to fetch quizzes for topic $topicId: ${e.toString()}');
    }
  }

  // ==================== 3. QUIZ BY ID ====================
  @override
  Future<Map<String, dynamic>> getQuizById(String quizId) async {
    try {
      print('🎯 [QUIZ API] === STEP 3: FETCHING QUIZ BY ID ===');
      print('🎯 [QUIZ API] Quiz ID: $quizId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/$quizId');
      
      // Usar el endpoint correcto del PDF
      final response = await apiClient.getQuiz('/api/quiz/$quizId');
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data Type: ${response.data.runtimeType}');
      
      Map<String, dynamic> quizData = _extractMapFromResponse(response.data);
      
      // Ensure quiz has required ID
      if (!quizData.containsKey('id')) {
        quizData['id'] = quizId;
      }
      
      final title = quizData['title'] ?? quizData['name'] ?? 'Quiz';
      print('✅ [QUIZ API] STEP 3 COMPLETED: Quiz "$title" (ID: $quizId)');
      return quizData;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching quiz by ID: $e');
      throw ServerException('Failed to fetch quiz $quizId: ${e.toString()}');
    }
  }

  // ==================== 4. QUIZ QUESTIONS ====================
  @override
  Future<List<TriviaQuestionModel>> getQuizQuestions(String quizId) async {
    try {
      print('🎯 [QUIZ API] === STEP 4: FETCHING QUIZ QUESTIONS ===');
      print('🎯 [QUIZ API] Quiz ID: $quizId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/questions/quiz/$quizId');
      
      // Usar el endpoint correcto del PDF
      final response = await apiClient.getQuiz('/api/quiz/questions/quiz/$quizId');
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data Type: ${response.data.runtimeType}');
      
      List<dynamic> questionsJson = _extractListFromResponse(response.data, 'questions');
      print('🔍 [QUIZ API] Found ${questionsJson.length} questions in response');
      
      if (questionsJson.isEmpty) {
        throw ServerException('No questions found for quiz: $quizId');
      }
      
      final questions = <TriviaQuestionModel>[];
      
      for (int i = 0; i < questionsJson.length; i++) {
        try {
          final questionJson = questionsJson[i];
          if (questionJson is! Map<String, dynamic>) {
            print('⚠️ [QUIZ API] Question $i is not a Map: ${questionJson.runtimeType}');
            continue;
          }
          
          final adaptedQuestion = _adaptQuestionStructure(questionJson, quizId, i);
          final question = TriviaQuestionModel.fromJson(adaptedQuestion);
          questions.add(question);
          
          print('✅ [QUIZ API] Processed question ${i + 1}: "${question.question}"');
          
        } catch (e) {
          print('❌ [QUIZ API] Failed to parse question $i: $e');
          print('❌ [QUIZ API] Question data: ${questionsJson[i]}');
          continue;
        }
      }
      
      if (questions.isEmpty) {
        throw ServerException('No valid questions could be parsed for quiz: $quizId');
      }
      
      print('🎉 [QUIZ API] STEP 4 COMPLETED: ${questions.length} questions for quiz $quizId');
      return questions;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching quiz questions: $e');
      throw ServerException('Failed to fetch questions for quiz $quizId: ${e.toString()}');
    }
  }

  // ==================== 5. QUESTION BY ID ====================
  @override
  Future<Map<String, dynamic>> getQuestionById(String questionId) async {
    try {
      print('🎯 [QUIZ API] === FETCHING QUESTION BY ID ===');
      print('🎯 [QUIZ API] Question ID: $questionId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/questions/$questionId');
      
      final response = await apiClient.getQuiz('/api/quiz/questions/$questionId');
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      
      Map<String, dynamic> questionData = _extractMapFromResponse(response.data);
      
      if (!questionData.containsKey('id')) {
        questionData['id'] = questionId;
      }
      
      print('✅ [QUIZ API] Question by ID fetched successfully');
      return questionData;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching question by ID: $e');
      throw ServerException('Failed to fetch question $questionId: ${e.toString()}');
    }
  }

  // ==================== 6. START QUIZ SESSION ====================
  @override
  Future<QuizSessionModel> startQuizSession({
    required String quizId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ API] === STARTING QUIZ SESSION ===');
      print('🎯 [QUIZ API] Quiz ID: $quizId, User ID: $userId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/start');
      
      final response = await apiClient.postQuiz(
        '/api/quiz/start',
        data: {
          'quizId': quizId,
          'userId': userId,
        },
      );
      
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data: ${response.data}');
      
      Map<String, dynamic> sessionData = _extractMapFromResponse(response.data);
      
      final session = QuizSessionModel.fromJson(sessionData);
      print('✅ [QUIZ API] Quiz session started: ${session.sessionId}');
      return session;
      
    } catch (e) {
      print('❌ [QUIZ API] Error starting quiz session: $e');
      throw ServerException('Failed to start quiz session: ${e.toString()}');
    }
  }

  // ==================== 7. SUBMIT ANSWER ====================
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
      print('🎯 [QUIZ API] === SUBMITTING ANSWER ===');
      print('🎯 [QUIZ API] Session: $sessionId, Question: $questionId');
      print('🎯 [QUIZ API] Selected Option: $selectedOptionId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/submit-answer');
      
      await apiClient.postQuiz(
        '/api/quiz/submit-answer',
        data: {
          'sessionId': sessionId,
          'questionId': questionId,
          'userId': userId,
          'selectedOptionId': selectedOptionId,
          'timeTakenSeconds': timeTakenSeconds,
          'answerConfidence': answerConfidence,
        },
      );
      
      print('✅ [QUIZ API] Answer submitted successfully');
      
    } catch (e) {
      print('❌ [QUIZ API] Error submitting answer: $e');
      throw ServerException('Failed to submit answer: ${e.toString()}');
    }
  }

  // ==================== 8. GET QUIZ RESULTS ====================
  @override
  Future<Map<String, dynamic>> getQuizResults({
    required String sessionId,
    required String userId,
  }) async {
    try {
      print('🎯 [QUIZ API] === FETCHING QUIZ RESULTS ===');
      print('🎯 [QUIZ API] Session ID: $sessionId, User ID: $userId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/results/$sessionId');
      
      final response = await apiClient.getQuiz(
        '/api/quiz/results/$sessionId',
        queryParameters: {
          'userId': userId,
        },
      );
      
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data: ${response.data}');
      
      Map<String, dynamic> resultsData = _extractMapFromResponse(response.data);
      
      print('✅ [QUIZ API] Quiz results fetched successfully');
      return resultsData;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching quiz results: $e');
      throw ServerException('Failed to fetch quiz results: ${e.toString()}');
    }
  }

  // ==================== 9. GET USER PROGRESS ====================
  @override
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      print('🎯 [QUIZ API] === FETCHING USER PROGRESS ===');
      print('🎯 [QUIZ API] User ID: $userId');
      print('🎯 [QUIZ API] Endpoint: /api/quiz/user-progress/$userId');
      
      final response = await apiClient.getQuiz('/api/quiz/user-progress/$userId');
      
      print('🎯 [QUIZ API] Response Status: ${response.statusCode}');
      print('🎯 [QUIZ API] Response Data: ${response.data}');
      
      Map<String, dynamic> progressData = _extractMapFromResponse(response.data);
      
      print('✅ [QUIZ API] User progress fetched successfully');
      return progressData;
      
    } catch (e) {
      print('❌ [QUIZ API] Error fetching user progress: $e');
      throw ServerException('Failed to fetch user progress: ${e.toString()}');
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

  Map<String, dynamic> _adaptQuestionStructure(
    Map<String, dynamic> serverQuestion,
    String quizId,
    int index,
  ) {
    print('🔄 [QUIZ API] Adapting question structure for index $index');
    
    // If already has correct structure, return as-is
    if (serverQuestion.containsKey('options') && 
        serverQuestion.containsKey('correctAnswerIndex')) {
      print('✅ [QUIZ API] Question already has correct structure');
      return serverQuestion;
    }
    
    // Extract question text
    final questionText = serverQuestion['questionText'] ?? 
                        serverQuestion['question'] ?? 
                        'Question ${index + 1}';
    
    // Extract options and find correct answer
    List<String> optionTexts = [];
    int correctAnswerIndex = 0;
    
    if (serverQuestion.containsKey('options') && serverQuestion['options'] is List) {
      final options = serverQuestion['options'] as List;
      
      for (int i = 0; i < options.length; i++) {
        if (options[i] is Map<String, dynamic>) {
          final option = options[i] as Map<String, dynamic>;
          final optionText = option['optionText']?.toString() ?? 
                           option['text']?.toString() ?? 'Option ${i + 1}';
          optionTexts.add(optionText);
          
          if (option['isCorrect'] == true) {
            correctAnswerIndex = i;
          }
        } else {
          optionTexts.add(options[i].toString());
        }
      }
    } else {
      throw ServerException('Question options not found or invalid format');
    }
    
    if (optionTexts.isEmpty) {
      throw ServerException('No valid options found for question');
    }
    
    // Map difficulty
    String difficulty = 'easy';
    if (serverQuestion.containsKey('difficultyWeight')) {
      final weight = double.tryParse(serverQuestion['difficultyWeight']?.toString() ?? '1') ?? 1.0;
      if (weight <= 1.0) {
        difficulty = 'easy';
      } else if (weight <= 2.0) {
        difficulty = 'medium';
      } else {
        difficulty = 'hard';
      }
    }
    
    final adaptedQuestion = {
      'id': serverQuestion['id'] ?? '${quizId}_question_${index + 1}',
      'categoryId': quizId,
      'question': questionText,
      'options': optionTexts,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': serverQuestion['explanation'] ?? 'Explanation for this answer.',
      'type': 'multipleChoice',
      'difficulty': difficulty,
      'points': serverQuestion['pointsValue'] ?? 10,
      'timeLimit': serverQuestion['timeLimitSeconds'] ?? 30,
      'imageUrl': serverQuestion['imageUrl'],
      'createdAt': serverQuestion['createdAt'] ?? DateTime.now().toIso8601String(),
    };
    
    print('✅ [QUIZ API] Question structure adapted successfully');
    return adaptedQuestion;
  }
}