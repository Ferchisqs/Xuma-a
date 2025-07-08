import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/trivia_result_entity.dart';
import '../../domain/usecases/get_trivia_questions_usecase.dart';
import '../../domain/usecases/submit_trivia_result_usecase.dart';

// States
abstract class TriviaGameState extends Equatable {
  const TriviaGameState();

  @override
  List<Object?> get props => [];
}

class TriviaGameInitial extends TriviaGameState {}

class TriviaGameLoading extends TriviaGameState {}

class TriviaGameReady extends TriviaGameState {
  final TriviaCategoryEntity category;
  final List<TriviaQuestionEntity> questions;
  final int currentQuestionIndex;
  final int? selectedAnswer;
  final int timeRemaining;
  final bool isAnswered;

  const TriviaGameReady({
    required this.category,
    required this.questions,
    required this.currentQuestionIndex,
    this.selectedAnswer,
    required this.timeRemaining,
    required this.isAnswered,
  });

  TriviaQuestionEntity get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;
  double get progress => (currentQuestionIndex + 1) / questions.length;

  @override
  List<Object?> get props => [
    category, questions, currentQuestionIndex, selectedAnswer, 
    timeRemaining, isAnswered
  ];
}

class TriviaGameCompleted extends TriviaGameState {
  final TriviaResultEntity result;

  const TriviaGameCompleted({required this.result});

  @override
  List<Object> get props => [result];
}

class TriviaGameError extends TriviaGameState {
  final String message;

  const TriviaGameError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class TriviaGameCubit extends Cubit<TriviaGameState> {
  final GetTriviaQuestionsUseCase getTriviaQuestionsUseCase;
  final SubmitTriviaResultUseCase submitTriviaResultUseCase;

  static const String _defaultUserId = 'user_123';
  
  List<int> _userAnswers = [];
  DateTime? _startTime;

  TriviaGameCubit({
    required this.getTriviaQuestionsUseCase,
    required this.submitTriviaResultUseCase,
  }) : super(TriviaGameInitial());

  Future<void> startTrivia(TriviaCategoryEntity category) async {
    emit(TriviaGameLoading());
    _startTime = DateTime.now();
    _userAnswers.clear();

    final result = await getTriviaQuestionsUseCase(
      GetTriviaQuestionsParams(categoryId: category.id),
    );

    result.fold(
      (failure) => emit(TriviaGameError(message: failure.message)),
      (questions) {
        _userAnswers = List.filled(questions.length, -1);
        emit(TriviaGameReady(
          category: category,
          questions: questions,
          currentQuestionIndex: 0,
          timeRemaining: category.timePerQuestion,
          isAnswered: false,
        ));
      },
    );
  }

  void selectAnswer(int answerIndex) {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    _userAnswers[currentState.currentQuestionIndex] = answerIndex;

    emit(TriviaGameReady(
      category: currentState.category,
      questions: currentState.questions,
      currentQuestionIndex: currentState.currentQuestionIndex,
      selectedAnswer: answerIndex,
      timeRemaining: currentState.timeRemaining,
      isAnswered: true,
    ));
  }

  void nextQuestion() {
    final currentState = state;
    if (currentState is! TriviaGameReady) return;

    if (currentState.isLastQuestion) {
      _completeTrivia();
    } else {
      emit(TriviaGameReady(
        category: currentState.category,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex + 1,
        timeRemaining: currentState.category.timePerQuestion,
        isAnswered: false,
      ));
    }
  }

  void timeUp() {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    // Auto-select -1 (no answer) when time is up
    _userAnswers[currentState.currentQuestionIndex] = -1;

    emit(TriviaGameReady(
      category: currentState.category,
      questions: currentState.questions,
      currentQuestionIndex: currentState.currentQuestionIndex,
      selectedAnswer: -1,
      timeRemaining: 0,
      isAnswered: true,
    ));
  }

  Future<void> _completeTrivia() async {
    final currentState = state;
    if (currentState is! TriviaGameReady) return;

    final totalTime = DateTime.now().difference(_startTime!);
    
    final result = await submitTriviaResultUseCase(
      SubmitTriviaResultParams(
        userId: _defaultUserId,
        categoryId: currentState.category.id,
        questionIds: currentState.questions.map((q) => q.id).toList(),
        userAnswers: _userAnswers,
        totalTime: totalTime,
      ),
    );

    result.fold(
      (failure) => emit(TriviaGameError(message: failure.message)),
      (triviaResult) => emit(TriviaGameCompleted(result: triviaResult)),
    );
  }

  void updateTimer(int timeRemaining) {
    final currentState = state;
    if (currentState is! TriviaGameReady || currentState.isAnswered) return;

    if (timeRemaining <= 0) {
      timeUp();
    } else {
      emit(TriviaGameReady(
        category: currentState.category,
        questions: currentState.questions,
        currentQuestionIndex: currentState.currentQuestionIndex,
        selectedAnswer: currentState.selectedAnswer,
        timeRemaining: timeRemaining,
        isAnswered: currentState.isAnswered,
      ));
    }
  }
}
