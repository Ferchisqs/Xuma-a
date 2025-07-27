// lib/features/trivia/presentation/cubit/quiz_session_cubit_fixed.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/quiz_session_entity.dart';
import '../../domain/usecases/start_quiz_session_usecase.dart';
import '../../domain/usecases/submit_quiz_answer_usecase.dart';
import '../../domain/usecases/get_quiz_results_usecase.dart';
import '../../domain/usecases/get_quiz_questions_usecase.dart';

// ==================== STATES ====================

abstract class QuizSessionState extends Equatable {
  const QuizSessionState();

  @override
  List<Object?> get props => [];
}

class QuizSessionInitial extends QuizSessionState {}

class QuizSessionLoading extends QuizSessionState {}

class QuizSessionStarted extends QuizSessionState {
  final QuizSessionEntity session;
  final List<TriviaQuestionEntity> questions;
  final int currentQuestionIndex;
  final int timeRemaining;
  final Map<String, String> userAnswers; // questionId -> selectedOptionId
  final bool isAnswerSubmitted;
  final bool showExplanation;

  const QuizSessionStarted({
    required this.session,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemaining,
    required this.userAnswers,
    required this.isAnswerSubmitted,
    this.showExplanation = false,
  });

  TriviaQuestionEntity get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  double get progress => (currentQuestionIndex + 1) / questions.length;
  String? get currentSelectedAnswer => userAnswers[currentQuestion.id];

  @override
  List<Object?> get props => [
    session, questions, currentQuestionIndex, timeRemaining, 
    userAnswers, isAnswerSubmitted, showExplanation
  ];

  QuizSessionStarted copyWith({
    QuizSessionEntity? session,
    List<TriviaQuestionEntity>? questions,
    int? currentQuestionIndex,
    int? timeRemaining,
    Map<String, String>? userAnswers,
    bool? isAnswerSubmitted,
    bool? showExplanation,
  }) {
    return QuizSessionStarted(
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      userAnswers: userAnswers ?? this.userAnswers,
      isAnswerSubmitted: isAnswerSubmitted ?? this.isAnswerSubmitted,
      showExplanation: showExplanation ?? this.showExplanation,
    );
  }
}

class QuizSessionCompleted extends QuizSessionState {
  final Map<String, dynamic> results;

  const QuizSessionCompleted({required this.results});

  @override
  List<Object> get props => [results];
}

class QuizSessionError extends QuizSessionState {
  final String message;

  const QuizSessionError({required this.message});

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ====================

@injectable
class QuizSessionCubit extends Cubit<QuizSessionState> {
  final StartQuizSessionUseCase startQuizSessionUseCase;
  final SubmitQuizAnswerUseCase submitQuizAnswerUseCase;
  final GetQuizResultsUseCase getQuizResultsUseCase;
  final GetQuizQuestionsUseCase getQuizQuestionsUseCase;

  QuizSessionCubit({
    required this.startQuizSessionUseCase,
    required this.submitQuizAnswerUseCase,
    required this.getQuizResultsUseCase,
    required this.getQuizQuestionsUseCase,
  }) : super(QuizSessionInitial()) {
    print('✅ [QUIZ_SESSION] Cubit initialized with all use cases');
  }

  // ==================== INICIAR QUIZ ====================

  Future<void> startQuiz({
    required String quizId,
    required String userId,
  }) async {
    emit(QuizSessionLoading());

    try {
      print('🎯 [QUIZ_SESSION] === STARTING QUIZ SESSION ===');
      print('🎯 [QUIZ_SESSION] Quiz ID: $quizId');
      print('🎯 [QUIZ_SESSION] User ID: $userId');

      // 🔧 PASO 1: Obtener preguntas del quiz (igual que en web)
      print('🎯 [QUIZ_SESSION] Step 1: Fetching quiz questions...');
      final questionsResult = await getQuizQuestionsUseCase(
        GetQuizQuestionsParams(quizId: quizId),
      );

      await questionsResult.fold(
        (failure) async {
          print('❌ [QUIZ_SESSION] Error getting questions: ${failure.message}');
          emit(QuizSessionError(message: 'Error cargando preguntas: ${failure.message}'));
        },
        (questions) async {
          if (questions.isEmpty) {
            print('❌ [QUIZ_SESSION] No questions found for quiz: $quizId');
            emit(const QuizSessionError(message: 'No hay preguntas disponibles para este quiz'));
            return;
          }

          print('✅ [QUIZ_SESSION] Questions loaded: ${questions.length}');
          print('🔍 [QUIZ_SESSION] First question: "${questions.first.question}"');
          print('🔍 [QUIZ_SESSION] First question options: ${questions.first.options.length}');

          // 🔧 PASO 2: Intentar iniciar sesión de quiz (opcional)
          print('🎯 [QUIZ_SESSION] Step 2: Attempting to start quiz session...');
          try {
            final sessionResult = await startQuizSessionUseCase(
              StartQuizSessionParams(quizId: quizId, userId: userId),
            );

            sessionResult.fold(
              (failure) {
                print('⚠️ [QUIZ_SESSION] Session start failed (using offline mode): ${failure.message}');
                // Crear sesión local como fallback
                final localSession = _createLocalSession(quizId, userId);
                _startQuizWithData(localSession, questions);
              },
              (session) {
                print('✅ [QUIZ_SESSION] Server session started: ${session.sessionId}');
                _startQuizWithData(session, questions);
              },
            );
          } catch (e) {
            print('⚠️ [QUIZ_SESSION] Session creation error (using offline mode): $e');
            // Fallback a sesión local
            final localSession = _createLocalSession(quizId, userId);
            _startQuizWithData(localSession, questions);
          }
        },
      );
    } catch (e) {
      print('❌ [QUIZ_SESSION] Unexpected error starting quiz: $e');
      emit(QuizSessionError(message: 'Error inesperado: $e'));
    }
  }

  // 🔧 MÉTODO HELPER: Crear sesión local como fallback
  QuizSessionEntity _createLocalSession(String quizId, String userId) {
    final sessionId = 'local_session_${DateTime.now().millisecondsSinceEpoch}';
    print('🔧 [QUIZ_SESSION] Creating local session: $sessionId');
    
    return QuizSessionEntity(
      sessionId: sessionId,
      quizId: quizId,
      userId: userId,
      status: 'active',
      startedAt: DateTime.now(),
      questionsTotal: 0, // Will be updated when we have questions
      questionsAnswered: 0,
      questionsCorrect: 0,
      pointsEarned: 0,
      percentageScore: '0',
      passed: false,
      timeTakenSeconds: 0,
    );
  }

  // 🔧 MÉTODO HELPER: Iniciar quiz con datos
  void _startQuizWithData(QuizSessionEntity session, List<TriviaQuestionEntity> questions) {
    print('🔧 [QUIZ_SESSION] Starting quiz with ${questions.length} questions');
    
    emit(QuizSessionStarted(
      session: session,
      questions: questions,
      currentQuestionIndex: 0,
      timeRemaining: questions.first.timeLimit,
      userAnswers: {},
      isAnswerSubmitted: false,
      showExplanation: false,
    ));

    print('✅ [QUIZ_SESSION] Quiz session started successfully');
    print('✅ [QUIZ_SESSION] First question: "${questions.first.question}"');
    print('✅ [QUIZ_SESSION] Time limit: ${questions.first.timeLimit} seconds');
  }

  // ==================== SELECCIONAR RESPUESTA ====================

  void selectAnswer(String selectedOptionId) {
    final currentState = state;
    if (currentState is! QuizSessionStarted || currentState.isAnswerSubmitted) {
      print('⚠️ [QUIZ_SESSION] Cannot select answer - invalid state or already answered');
      return;
    }

    print('🎯 [QUIZ_SESSION] === ANSWER SELECTED ===');
    print('🎯 [QUIZ_SESSION] Question: ${currentState.currentQuestion.id}');
    print('🎯 [QUIZ_SESSION] Selected option ID: $selectedOptionId');

    // 🔧 VALIDAR QUE LA OPCIÓN SEA VÁLIDA
    final question = currentState.currentQuestion;
    final optionIndex = _extractOptionIndex(selectedOptionId);
    
    if (optionIndex < 0 || optionIndex >= question.options.length) {
      print('❌ [QUIZ_SESSION] Invalid option index: $optionIndex');
      return;
    }

    print('🔍 [QUIZ_SESSION] Option index: $optionIndex');
    print('🔍 [QUIZ_SESSION] Option text: "${question.options[optionIndex]}"');
    print('🔍 [QUIZ_SESSION] Correct answer index: ${question.correctAnswerIndex}');
    print('🔍 [QUIZ_SESSION] Is correct: ${optionIndex == question.correctAnswerIndex}');

    final updatedAnswers = Map<String, String>.from(currentState.userAnswers);
    updatedAnswers[currentState.currentQuestion.id] = selectedOptionId;

    emit(currentState.copyWith(
      userAnswers: updatedAnswers,
      isAnswerSubmitted: true,
      showExplanation: true, // Mostrar explicación después de responder
    ));

    print('✅ [QUIZ_SESSION] Answer recorded and explanation shown');
  }

  // 🔧 HELPER: Extraer índice de opción del optionId
  int _extractOptionIndex(String optionId) {
    // Formato esperado: "{questionId}_option_{index}"
    final parts = optionId.split('_option_');
    if (parts.length == 2) {
      return int.tryParse(parts[1]) ?? -1;
    }
    // Fallback: intentar parsear directamente
    return int.tryParse(optionId) ?? -1;
  }

  // ==================== ENVIAR RESPUESTA ====================

  Future<void> submitAnswer({
    required int timeTakenSeconds,
    required int answerConfidence,
  }) async {
    final currentState = state;
    if (currentState is! QuizSessionStarted || !currentState.isAnswerSubmitted) {
      print('⚠️ [QUIZ_SESSION] Cannot submit answer - invalid state');
      return;
    }

    try {
      final selectedOptionId = currentState.currentSelectedAnswer;
      if (selectedOptionId == null) {
        print('⚠️ [QUIZ_SESSION] No answer selected to submit');
        return;
      }

      print('🎯 [QUIZ_SESSION] === SUBMITTING ANSWER ===');
      print('🎯 [QUIZ_SESSION] Question: ${currentState.currentQuestion.id}');
      print('🎯 [QUIZ_SESSION] Selected option: $selectedOptionId');
      print('🎯 [QUIZ_SESSION] Time taken: ${timeTakenSeconds}s');
      print('🎯 [QUIZ_SESSION] Confidence: $answerConfidence');

      // 🔧 INTENTAR ENVIAR AL SERVIDOR (OPCIONAL)
      try {
        final result = await submitQuizAnswerUseCase(
          SubmitQuizAnswerParams(
            sessionId: currentState.session.sessionId,
            questionId: currentState.currentQuestion.id,
            userId: currentState.session.userId,
            selectedOptionId: selectedOptionId,
            timeTakenSeconds: timeTakenSeconds,
            answerConfidence: answerConfidence,
          ),
        );

        result.fold(
          (failure) {
            print('⚠️ [QUIZ_SESSION] Server submit failed (continuing offline): ${failure.message}');
            // Continuar sin enviar al servidor
            _proceedToNextQuestion();
          },
          (_) {
            print('✅ [QUIZ_SESSION] Answer submitted to server successfully');
            _proceedToNextQuestion();
          },
        );
      } catch (e) {
        print('⚠️ [QUIZ_SESSION] Submit error (continuing offline): $e');
        // Continuar sin enviar al servidor
        _proceedToNextQuestion();
      }
    } catch (e) {
      print('❌ [QUIZ_SESSION] Error submitting answer: $e');
      emit(QuizSessionError(message: 'Error enviando respuesta: $e'));
    }
  }

  // ==================== SIGUIENTE PREGUNTA ====================

  void _proceedToNextQuestion() {
    final currentState = state;
    if (currentState is! QuizSessionStarted) return;

    print('🎯 [QUIZ_SESSION] === PROCEEDING TO NEXT QUESTION ===');
    print('🎯 [QUIZ_SESSION] Current: ${currentState.currentQuestionIndex + 1}/${currentState.questions.length}');

    if (currentState.isLastQuestion) {
      print('🎯 [QUIZ_SESSION] Last question completed - finishing quiz');
      _completeQuiz();
    } else {
      final nextIndex = currentState.currentQuestionIndex + 1;
      final nextQuestion = currentState.questions[nextIndex];

      print('🎯 [QUIZ_SESSION] Moving to question ${nextIndex + 1}');
      print('🎯 [QUIZ_SESSION] Next question: "${nextQuestion.question}"');

      emit(currentState.copyWith(
        currentQuestionIndex: nextIndex,
        timeRemaining: nextQuestion.timeLimit,
        isAnswerSubmitted: false,
        showExplanation: false,
      ));

      print('✅ [QUIZ_SESSION] Moved to question ${nextIndex + 1}/${currentState.questions.length}');
    }
  }

  // ==================== COMPLETAR QUIZ ====================

  Future<void> _completeQuiz() async {
    final currentState = state;
    if (currentState is! QuizSessionStarted) return;

    try {
      print('🎯 [QUIZ_SESSION] === COMPLETING QUIZ ===');
      
      // 🔧 CALCULAR RESULTADOS LOCALMENTE
      final localResults = _calculateLocalResults(currentState);
      print('🔍 [QUIZ_SESSION] Local results calculated: $localResults');

      // 🔧 INTENTAR OBTENER RESULTADOS DEL SERVIDOR (OPCIONAL)
      try {
        final resultsResult = await getQuizResultsUseCase(
          GetQuizResultsParams(
            sessionId: currentState.session.sessionId,
            userId: currentState.session.userId,
          ),
        );

        resultsResult.fold(
          (failure) {
            print('⚠️ [QUIZ_SESSION] Server results failed (using local): ${failure.message}');
            emit(QuizSessionCompleted(results: localResults));
          },
          (serverResults) {
            print('✅ [QUIZ_SESSION] Server results received');
            // Combinar resultados del servidor con cálculos locales
            final combinedResults = _combineResults(localResults, serverResults);
            emit(QuizSessionCompleted(results: combinedResults));
          },
        );
      } catch (e) {
        print('⚠️ [QUIZ_SESSION] Server results error (using local): $e');
        emit(QuizSessionCompleted(results: localResults));
      }

      print('✅ [QUIZ_SESSION] Quiz completed successfully');
    } catch (e) {
      print('❌ [QUIZ_SESSION] Error completing quiz: $e');
      emit(QuizSessionError(message: 'Error completando quiz: $e'));
    }
  }

  // 🔧 CALCULAR RESULTADOS LOCALMENTE
  Map<String, dynamic> _calculateLocalResults(QuizSessionStarted state) {
    int correctAnswers = 0;
    int totalAnswered = 0;
    int totalPoints = 0;

    print('🔧 [QUIZ_SESSION] Calculating local results...');

    for (int i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final userAnswer = state.userAnswers[question.id];
      
      if (userAnswer != null) {
        totalAnswered++;
        final selectedIndex = _extractOptionIndex(userAnswer);
        
        if (selectedIndex == question.correctAnswerIndex) {
          correctAnswers++;
          totalPoints += question.points;
        }
        
        print('🔍 [QUIZ_SESSION] Q${i + 1}: Selected $selectedIndex, Correct ${question.correctAnswerIndex}, Points: ${selectedIndex == question.correctAnswerIndex ? question.points : 0}');
      }
    }

    final accuracy = totalAnswered > 0 ? (correctAnswers / totalAnswered * 100).round() : 0;
    final passed = accuracy >= 60;

    final results = {
      'sessionId': state.session.sessionId,
      'quizId': state.session.quizId,
      'userId': state.session.userId,
      'totalQuestions': state.questions.length,
      'questionsAnswered': totalAnswered,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'points': totalPoints,
      'pointsEarned': totalPoints,
      'passed': passed,
      'completedAt': DateTime.now().toIso8601String(),
      'duration': 0, // TODO: Calcular duración real
    };

    print('✅ [QUIZ_SESSION] Local results: $results');
    return results;
  }

  // 🔧 COMBINAR RESULTADOS DEL SERVIDOR CON LOCALES
  Map<String, dynamic> _combineResults(
    Map<String, dynamic> localResults,
    Map<String, dynamic> serverResults,
  ) {
    // Preferir datos del servidor, usar locales como fallback
    return {
      ...localResults,
      ...serverResults,
      'source': 'combined',
      'localCalculated': true,
      'serverReceived': true,
    };
  }

  // ==================== TIMER ====================

  void updateTimer(int timeRemaining) {
    final currentState = state;
    if (currentState is! QuizSessionStarted || currentState.isAnswerSubmitted) {
      return;
    }

    if (timeRemaining <= 0) {
      print('⏰ [QUIZ_SESSION] Time up!');
      timeUp();
    } else {
      emit(currentState.copyWith(timeRemaining: timeRemaining));
    }
  }

  void timeUp() {
    final currentState = state;
    if (currentState is! QuizSessionStarted || currentState.isAnswerSubmitted) {
      return;
    }

    print('⏰ [QUIZ_SESSION] === TIME UP ===');
    print('⏰ [QUIZ_SESSION] Question: ${currentState.currentQuestion.id}');
    
    // Marcar como tiempo agotado y proceder
    emit(currentState.copyWith(
      isAnswerSubmitted: true,
      showExplanation: true,
      timeRemaining: 0,
    ));

    // Auto-enviar respuesta con tiempo agotado
    submitAnswer(
      timeTakenSeconds: currentState.currentQuestion.timeLimit,
      answerConfidence: 1, // Baja confianza por timeout
    );
  }

  // ==================== MÉTODOS HELPER ====================

  void nextQuestion() {
    _proceedToNextQuestion();
  }

  void resetQuiz() {
    print('🔄 [QUIZ_SESSION] Resetting quiz session');
    emit(QuizSessionInitial());
  }

  // ==================== DEBUG ====================

  void debugCurrentState() {
    final currentState = state;
    print('🔍 [QUIZ_SESSION] === DEBUG CURRENT STATE ===');
    print('🔍 [QUIZ_SESSION] State type: ${currentState.runtimeType}');
    
    if (currentState is QuizSessionStarted) {
      print('🔍 [QUIZ_SESSION] Session ID: ${currentState.session.sessionId}');
      print('🔍 [QUIZ_SESSION] Quiz ID: ${currentState.session.quizId}');
      print('🔍 [QUIZ_SESSION] Current question: ${currentState.currentQuestionIndex + 1}/${currentState.questions.length}');
      print('🔍 [QUIZ_SESSION] Time remaining: ${currentState.timeRemaining}s');
      print('🔍 [QUIZ_SESSION] Answer submitted: ${currentState.isAnswerSubmitted}');
      print('🔍 [QUIZ_SESSION] Show explanation: ${currentState.showExplanation}');
      print('🔍 [QUIZ_SESSION] User answers: ${currentState.userAnswers}');
    }
    
    print('🔍 [QUIZ_SESSION] ==============================');
  }
}