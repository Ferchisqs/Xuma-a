// lib/features/trivia/presentation/cubit/trivia_cubit.dart - ACTUALIZADO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/usecases/get_trivia_categories_usecase.dart';
import '../../domain/usecases/get_quizzes_by_topic_usecase.dart';

// ==================== STATES ACTUALIZADOS ====================

abstract class TriviaState extends Equatable {
  const TriviaState();

  @override
  List<Object?> get props => [];
}

class TriviaInitial extends TriviaState {}

class TriviaLoading extends TriviaState {}

class TriviaLoaded extends TriviaState {
  final List<TriviaCategoryEntity> categories;

  const TriviaLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

// 🆕 NUEVO STATE PARA QUIZZES POR TOPIC
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

class TriviaError extends TriviaState {
  final String message;

  const TriviaError({required this.message});

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ACTUALIZADO ====================

@injectable
class TriviaCubit extends Cubit<TriviaState> {
  final GetTriviaCategoriesUseCase getTriviaCategoriesUseCase;
  final GetQuizzesByTopicUseCase getQuizzesByTopicUseCase; // 🆕 NUEVO USE CASE

  TriviaCubit({
    required this.getTriviaCategoriesUseCase,
    required this.getQuizzesByTopicUseCase, // 🆕 INYECCIÓN
  }) : super(TriviaInitial()) {
    print('✅ [TRIVIA CUBIT] Constructor - Now using topics endpoint');
  }

  // ==================== CARGAR CATEGORÍAS (DESDE TOPICS) ====================

  Future<void> loadCategories() async {
    print('🎯 [TRIVIA CUBIT] Loading categories from topics endpoint...');
    emit(TriviaLoading());

    final result = await getTriviaCategoriesUseCase.call();

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] Failed to load categories: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (categories) {
        print('✅ [TRIVIA CUBIT] Loaded ${categories.length} trivia categories from topics');
        emit(TriviaLoaded(categories: categories));
      },
    );
  }

  // 🆕 CARGAR QUIZZES POR TOPIC

  Future<void> loadQuizzesByTopic(String topicId) async {
    print('🎯 [TRIVIA CUBIT] Loading quizzes for topic: $topicId');
    emit(TriviaQuizzesLoading());

    final result = await getQuizzesByTopicUseCase(
      GetQuizzesByTopicParams(topicId: topicId),
    );

    result.fold(
      (failure) {
        print('❌ [TRIVIA CUBIT] Failed to load quizzes for topic: ${failure.message}');
        emit(TriviaError(message: failure.message));
      },
      (quizzes) {
        print('✅ [TRIVIA CUBIT] Loaded ${quizzes.length} quizzes for topic: $topicId');
        emit(TriviaQuizzesLoaded(
          topicId: topicId,
          quizzes: quizzes,
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

  // 🆕 OBTENER CATEGORY POR ID (HELPER)
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
}