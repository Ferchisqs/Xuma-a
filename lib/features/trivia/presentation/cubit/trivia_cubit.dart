// lib/features/trivia/presentation/cubit/trivia_cubit.dart - FLUJO COMPLETO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/usecases/get_trivia_categories_usecase.dart';
import '../../domain/usecases/get_quizzes_by_topic_usecase.dart';
import '../../domain/usecases/get_quiz_by_id_usecase.dart';
import '../../domain/usecases/get_quiz_questions_usecase.dart';

// ==================== STATES ACTUALIZADOS ====================

abstract class TriviaState extends Equatable {
  const TriviaState();

  @override
  List<Object?> get props => [];
}

class TriviaInitial extends TriviaState {}

class TriviaLoading extends TriviaState {}

// STEP 1: Topics cargados
class TriviaLoaded extends TriviaState {
  final List<TriviaCategoryEntity> categories;

  const TriviaLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

// STEP 2: Quizzes por topic
class TriviaQuizzesLoading extends TriviaState {}

class TriviaQuizzesLoaded extends TriviaState {
  final String topicId;
  final List<Map<String, dynamic>> quizzes;

  const TriviaQuizzesLoaded({
    required this.topicId,
    required this.quizzes,
  });

  @override
  List<Object> get props => [topicId, quizzes];
}

// STEP 3: Quiz específico cargado
class TriviaQuizLoading extends TriviaState {}

class TriviaQuizLoaded extends TriviaState {
  final String quizId;
  final Map<String, dynamic> quiz;

  const TriviaQuizLoaded({
    required this.quizId,
    required this.quiz,
  });

  @override
  List<Object> get props => [quizId, quiz];
}

// STEP 4: Preguntas del quiz cargadas
class TriviaQuestionsLoading extends TriviaState {}

class TriviaQuestionsLoaded extends TriviaState {
  final String quizId;
  final List<dynamic> questions; // Usar dynamic por simplicidad

  const TriviaQuestionsLoaded({
    required this.quizId,
    required this.questions,
  });

  @override
  List<Object> get props => [quizId, questions];
}

class TriviaError extends TriviaState {
  final String message;

  const TriviaError({required this.message});

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT COMPLETO ====================

@injectable
class TriviaCubit extends Cubit<TriviaState> {
  final GetTriviaCategoriesUseCase getTriviaCategoriesUseCase;
  final GetQuizzesByTopicUseCase getQuizzesByTopicUseCase;
  final GetQuizByIdUseCase getQuizByIdUseCase;
  final GetQuizQuestionsUseCase getQuizQuestionsUseCase;

  TriviaCubit({
    required this.getTriviaCategoriesUseCase,
    required this.getQuizzesByTopicUseCase,
    required this.getQuizByIdUseCase,
    required this.getQuizQuestionsUseCase,
  }) : super(TriviaInitial()) {
    print('✅ [TRIVIA CUBIT] Constructor - Full flow implementation');
  }

  // ==================== STEP 1: CARGAR TOPICS (/api/content/topics) ====================

  Future<void> loadCategories() async {
    print('🎯 [TRIVIA CUBIT] STEP 1: Loading categories from topics endpoint...');
    emit(TriviaLoading());

    final result = await getTriviaCategoriesUseCase.call();

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] STEP 1 FAILED: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (categories) {
        print('✅ [TRIVIA CUBIT] STEP 1 COMPLETED: ${categories.length} categories loaded');
        emit(TriviaLoaded(categories: categories));
      },
    );
  }

  // ==================== STEP 2: CARGAR QUIZZES POR TOPIC (/api/quiz/by-topic/{topicId}) ====================

  Future<void> loadQuizzesByTopic(String topicId) async {
    print('🎯 [TRIVIA CUBIT] STEP 2: Loading quizzes for topic: $topicId');
    emit(TriviaQuizzesLoading());

    final result = await getQuizzesByTopicUseCase(
      GetQuizzesByTopicParams(topicId: topicId),
    );

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] STEP 2 FAILED: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (quizzes) {
        print('✅ [TRIVIA CUBIT] STEP 2 COMPLETED: ${quizzes.length} quizzes for topic $topicId');
        emit(TriviaQuizzesLoaded(
          topicId: topicId,
          quizzes: quizzes,
        ));
      },
    );
  }

  // ==================== STEP 3: CARGAR QUIZ ESPECÍFICO (/api/quiz/{id}) ====================

  Future<void> loadQuizById(String quizId) async {
    print('🎯 [TRIVIA CUBIT] STEP 3: Loading quiz by ID: $quizId');
    emit(TriviaQuizLoading());

    final result = await getQuizByIdUseCase(
      GetQuizByIdParams(quizId: quizId),
    );

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] STEP 3 FAILED: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (quiz) {
        print('✅ [TRIVIA CUBIT] STEP 3 COMPLETED: Quiz $quizId loaded');
        emit(TriviaQuizLoaded(
          quizId: quizId,
          quiz: quiz,
        ));
      },
    );
  }

  // ==================== STEP 4: CARGAR PREGUNTAS DEL QUIZ (/api/quiz/questions/quiz/{quizId}) ====================

  Future<void> loadQuizQuestions(String quizId) async {
    print('🎯 [TRIVIA CUBIT] STEP 4: Loading questions for quiz: $quizId');
    emit(TriviaQuestionsLoading());

    final result = await getQuizQuestionsUseCase(
      GetQuizQuestionsParams(quizId: quizId),
    );

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] STEP 4 FAILED: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (questions) {
        print('✅ [TRIVIA CUBIT] STEP 4 COMPLETED: ${questions.length} questions for quiz $quizId');
        emit(TriviaQuestionsLoaded(
          quizId: quizId,
          questions: questions,
        ));
      },
    );
  }

  // ==================== MÉTODOS HELPER ====================

  void refreshCategories() {
    print('🔄 [TRIVIA CUBIT] Refreshing categories from topics endpoint');
    loadCategories();
  }

  void reset() {
    print('🔄 [TRIVIA CUBIT] Resetting to initial state');
    emit(TriviaInitial());
  }

  TriviaCategoryEntity? getCategoryById(String categoryId) {
    final currentState = state;
    if (currentState is TriviaLoaded) {
      try {
        return currentState.categories.firstWhere((cat) => cat.id == categoryId);
      } catch (e) {
        print('⚠️ [TRIVIA CUBIT] Category not found: $categoryId');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? getQuizById(String quizId) {
    final currentState = state;
    if (currentState is TriviaQuizzesLoaded) {
      try {
        return currentState.quizzes.firstWhere((quiz) => quiz['id'] == quizId);
      } catch (e) {
        print('⚠️ [TRIVIA CUBIT] Quiz not found: $quizId');
        return null;
      }
    }
    return null;
  }

  // ==================== MÉTODOS DE NAVEGACIÓN HELPER ====================

  /// Navegar desde topics a quizzes
  void navigateToQuizzes(String topicId) {
    print('🎯 [TRIVIA CUBIT] Navigating to quizzes for topic: $topicId');
    loadQuizzesByTopic(topicId);
  }

  /// Navegar desde quizzes a quiz específico
  void navigateToQuiz(String quizId) {
    print('🎯 [TRIVIA CUBIT] Navigating to quiz: $quizId');
    loadQuizById(quizId);
  }

  /// Navegar desde quiz a preguntas
  void navigateToQuestions(String quizId) {
    print('🎯 [TRIVIA CUBIT] Navigating to questions for quiz: $quizId');
    loadQuizQuestions(quizId);
  }

  // ==================== MÉTODOS DE DEBUG ====================

  void debugCurrentState() {
    print('🔍 [TRIVIA CUBIT] Current state: ${state.runtimeType}');
    if (state is TriviaLoaded) {
      final loadedState = state as TriviaLoaded;
      print('🔍 [TRIVIA CUBIT] Categories loaded: ${loadedState.categories.length}');
    } else if (state is TriviaQuizzesLoaded) {
      final quizzesState = state as TriviaQuizzesLoaded;
      print('🔍 [TRIVIA CUBIT] Quizzes loaded for topic ${quizzesState.topicId}: ${quizzesState.quizzes.length}');
    } else if (state is TriviaQuizLoaded) {
      final quizState = state as TriviaQuizLoaded;
      print('🔍 [TRIVIA CUBIT] Quiz loaded: ${quizState.quizId}');
    } else if (state is TriviaQuestionsLoaded) {
      final questionsState = state as TriviaQuestionsLoaded;
      print('🔍 [TRIVIA CUBIT] Questions loaded for quiz ${questionsState.quizId}: ${questionsState.questions.length}');
    }
  }

  void printFlowStatus() {
    print('📋 [TRIVIA CUBIT] ========== QUIZ FLOW STATUS ==========');
    print('📋 [TRIVIA CUBIT] 1. Topics (/api/content/topics) - Available');
    print('📋 [TRIVIA CUBIT] 2. Quizzes by Topic (/api/quiz/by-topic/{topicId}) - Available');
    print('📋 [TRIVIA CUBIT] 3. Quiz by ID (/api/quiz/{id}) - Available');
    print('📋 [TRIVIA CUBIT] 4. Quiz Questions (/api/quiz/questions/quiz/{quizId}) - Available');
    print('📋 [TRIVIA CUBIT] Current State: ${state.runtimeType}');
    print('📋 [TRIVIA CUBIT] =======================================');
  }
}