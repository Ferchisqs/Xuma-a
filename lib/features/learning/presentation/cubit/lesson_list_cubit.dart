import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/usecases/get_lessons_by_category_usecase.dart';
import '../../domain/usecases/search_lessons_usecase.dart';

// States
abstract class LessonListState extends Equatable {
  const LessonListState();

  @override
  List<Object> get props => [];
}

class LessonListInitial extends LessonListState {}

class LessonListLoading extends LessonListState {}

class LessonListLoaded extends LessonListState {
  final CategoryEntity category;
  final List<LessonEntity> allLessons;
  final List<LessonEntity> filteredLessons;
  final String searchQuery;

  const LessonListLoaded({
    required this.category,
    required this.allLessons,
    required this.filteredLessons,
    required this.searchQuery,
  });

  @override
  List<Object> get props => [category, allLessons, filteredLessons, searchQuery];
}

class LessonListError extends LessonListState {
  final String message;

  const LessonListError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class LessonListCubit extends Cubit<LessonListState> {
  final GetLessonsByCategoryUseCase getLessonsByCategoryUseCase;
  final SearchLessonsUseCase searchLessonsUseCase;

  LessonListCubit({
    required this.getLessonsByCategoryUseCase,
    required this.searchLessonsUseCase,
  }) : super(LessonListInitial());

  Future<void> loadLessons(CategoryEntity category) async {
    emit(LessonListLoading());

    final result = await getLessonsByCategoryUseCase(
      GetLessonsByCategoryParams(categoryId: category.id),
    );

    result.fold(
      (failure) => emit(LessonListError(message: failure.message)),
      (lessons) => emit(LessonListLoaded(
        category: category,
        allLessons: lessons,
        filteredLessons: lessons,
        searchQuery: '',
      )),
    );
  }

  Future<void> searchLessons(String query) async {
    final currentState = state;
    if (currentState is! LessonListLoaded) return;

    if (query.trim().isEmpty) {
      emit(LessonListLoaded(
        category: currentState.category,
        allLessons: currentState.allLessons,
        filteredLessons: currentState.allLessons,
        searchQuery: '',
      ));
      return;
    }

    final result = await searchLessonsUseCase(
      SearchLessonsParams(
        query: query,
        categoryId: currentState.category.id,
      ),
    );

    result.fold(
      (failure) {
        // En caso de error, filtrar localmente
        final filteredLessons = currentState.allLessons
            .where((lesson) =>
                lesson.title.toLowerCase().contains(query.toLowerCase()) ||
                lesson.description.toLowerCase().contains(query.toLowerCase()))
            .toList();

        emit(LessonListLoaded(
          category: currentState.category,
          allLessons: currentState.allLessons,
          filteredLessons: filteredLessons,
          searchQuery: query,
        ));
      },
      (lessons) => emit(LessonListLoaded(
        category: currentState.category,
        allLessons: currentState.allLessons,
        filteredLessons: lessons,
        searchQuery: query,
      )),
    );
  }

  void clearSearch() {
    final currentState = state;
    if (currentState is LessonListLoaded) {
      emit(LessonListLoaded(
        category: currentState.category,
        allLessons: currentState.allLessons,
        filteredLessons: currentState.allLessons,
        searchQuery: '',
      ));
    }
  }
}
