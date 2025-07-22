// lib/features/trivia/presentation/cubit/quiz_session_cubit.dart
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

  const QuizSessionStarted({
    required this.session,
    required this.questions,
    required this.currentQuestionIndex,
    required this.timeRemaining,
    required this.userAnswers,
    required this.isAnswerSubmitted,
  });

  TriviaQuestionEntity get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  double get progress => (currentQuestionIndex + 1) / questions.length;
  String? get currentSelectedAnswer => userAnswers[currentQuestion.id];

  @override
  List<Object?> get props => [
    session, questions, currentQuestionIndex, timeRemaining, 
    userAnswers, isAnswerSubmitted
  ];

  QuizSessionStarted copyWith({
    QuizSessionEntity? session,
    List<TriviaQuestionEntity>? questions,
    int? currentQuestionIndex,
    int? timeRemaining,
    Map<String, String>? userAnswers,
    bool? isAnswerSubmitted,
  }) {
    return QuizSessionStarted(
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      userAnswers: userAnswers ?? this.userAnswers,
      isAnswerSubmitted: isAnswerSubmitted ?? this.isAnswerSubmitted,
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
  }) : super(QuizSessionInitial());

  // ==================== INICIAR QUIZ ====================

  Future<void> startQuiz({
    required String quizId,
    required String userId,
  }) async {
    emit(QuizSessionLoading());

    try {
      print('🎯 [QUIZ_SESSION] Starting quiz: $quizId for user: $userId');

      // 1. Iniciar sesión de quiz
      final sessionResult = await startQuizSessionUseCase(
        StartQuizSessionParams(quizId: quizId, userId: userId),
      );

      await sessionResult.fold(
        (failure) async {
          print('❌ [QUIZ_SESSION] Error starting session: ${failure.message}');
          emit(QuizSessionError(message: failure.message));
        },
        (session) async {
          print('✅ [QUIZ_SESSION] Session started: ${session.sessionId}');

          // 2. Obtener preguntas del quiz
          final questionsResult = await getQuizQuestionsUseCase(
            GetQuizQuestionsParams(quizId: quizId),
          );

          questionsResult.fold(
            (failure) {
              print('❌ [QUIZ_SESSION] Error getting questions: ${failure.message}');
              emit(QuizSessionError(message: failure.message));
            },
            (questions) {
              if (questions.isEmpty) {
                emit(const QuizSessionError(message: 'No hay preguntas disponibles'));
                return;
              }

              print('✅ [QUIZ_SESSION] Questions loaded: ${questions.length}');
              
              emit(QuizSessionStarted(
                session: session,
                questions: questions,
                currentQuestionIndex: 0,
                timeRemaining: questions.first.timeLimit,
                userAnswers: {},
                isAnswerSubmitted: false,
              ));
            },
          );
        },
      );
    } catch (e) {
      print('❌ [QUIZ_SESSION] Unexpected error: $e');
      emit(QuizSessionError(message: 'Error inesperado: $e'));
    }
  }

  // ==================== SELECCIONAR RESPUESTA ====================

  void selectAnswer(String selectedOptionId) {
    final currentState = state;
    if (currentState is! QuizSessionStarted || currentState.isAnswerSubmitted) {
      return;
    }

    print('🎯 [QUIZ_SESSION] Answer selected: $selectedOptionId');

    final updatedAnswers = Map<String, String>.from(currentState.userAnswers);
    updatedAnswers[currentState.currentQuestion.id] = selectedOptionId;

    emit(currentState.copyWith(
      userAnswers: updatedAnswers,
      isAnswerSubmitted: true,
    ));
  }

  // ==================== ENVIAR RESPUESTA ====================

  Future<void> submitAnswer({
    required int timeTakenSeconds,
    required int answerConfidence,
  }) async {
    final currentState = state;
    if (currentState is! QuizSessionStarted || !currentState.isAnswerSubmitted) {
      return;
    }

    try {
      final selectedOptionId = currentState.currentSelectedAnswer;
      if (selectedOptionId == null) {
        print('⚠️ [QUIZ_SESSION] No answer selected');
        return;
      }

      print('🎯 [QUIZ_SESSION] Submitting answer for question: ${currentState.currentQuestion.id}');

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
          print('❌ [QUIZ_SESSION] Error submitting answer: ${failure.message}');
          emit(QuizSessionError(message: failure.message));
        },
        (_) {
          print('✅ [QUIZ_SESSION] Answer submitted successfully');
          // Continuar con la siguiente pregunta o completar quiz
          _proceedToNextQuestion();
        },
      );
    } catch (e) {
      print('❌ [QUIZ_SESSION] Error submitting answer: $e');
      emit(QuizSessionError(message: 'Error enviando respuesta: $e'));
    }
  }

  // ==================== SIGUIENTE PREGUNTA ====================

  void _proceedToNextQuestion() {
    final currentState = state;
    if (currentState is! QuizSessionStarted) return;

    if (currentState.isLastQuestion) {
      // Quiz completado, obtener resultados
      _completeQuiz();
    } else {
      // Ir a la siguiente pregunta
      final nextIndex = currentState.currentQuestionIndex + 1;
      final nextQuestion = currentState.questions[nextIndex];

      emit(currentState.copyWith(
        currentQuestionIndex: nextIndex,
        timeRemaining: nextQuestion.timeLimit,
        isAnswerSubmitted: false,
      ));

      print('🎯 [QUIZ_SESSION] Moved to question ${nextIndex + 1}/${currentState.questions.length}');
    }
  }

  // ==================== COMPLETAR QUIZ ====================

  Future<void> _completeQuiz() async {
    final currentState = state;
    if (currentState is! QuizSessionStarted) return;

    try {
      print('🎯 [QUIZ_SESSION] Completing quiz, getting results...');

      final resultsResult = await getQuizResultsUseCase(
        GetQuizResultsParams(
          sessionId: currentState.session.sessionId,
          userId: currentState.session.userId,
        ),
      );

      resultsResult.fold(
        (failure) {
          print('❌ [QUIZ_SESSION] Error getting results: ${failure.message}');
          emit(QuizSessionError(message: failure.message));
        },
        (results) {
          print('✅ [QUIZ_SESSION] Quiz completed successfully');
          emit(QuizSessionCompleted(results: results));
        },
      );
    } catch (e) {
      print('❌ [QUIZ_SESSION] Error completing quiz: $e');
      emit(QuizSessionError(message: 'Error completando quiz: $e'));
    }
  }

  // ==================== TIMER ====================

  void updateTimer(int timeRemaining) {
    final currentState = state;
    if (currentState is! QuizSessionStarted || currentState.isAnswerSubmitted) {
      return;
    }

    if (timeRemaining <= 0) {
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

    print('⏰ [QUIZ_SESSION] Time up for question: ${currentState.currentQuestion.id}');
    
    // Auto-enviar respuesta vacía o la seleccionada
    submitAnswer(
      timeTakenSeconds: currentState.currentQuestion.timeLimit,
      answerConfidence: 1, // Baja confianza por timeout
    );
  }
}