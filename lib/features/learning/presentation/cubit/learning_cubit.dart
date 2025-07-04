import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';

// States
abstract class LearningState extends Equatable {
  const LearningState();

  @override
  List<Object> get props => [];
}

class LearningInitial extends LearningState {}

class LearningLoading extends LearningState {}

class LearningLoaded extends LearningState {
  final List<CategoryEntity> categories;

  const LearningLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

class LearningError extends LearningState {
  final String message;

  const LearningError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class LearningCubit extends Cubit<LearningState> {
  final GetCategoriesUseCase getCategoriesUseCase;

  LearningCubit({
    required this.getCategoriesUseCase,
  }) : super(LearningInitial());

  Future<void> loadCategories() async {
    emit(LearningLoading());

    final result = await getCategoriesUseCase(NoParams());

    result.fold(
      (failure) => emit(LearningError(message: failure.message)),
      (categories) => emit(LearningLoaded(categories: categories)),
    );
  }

  void refreshCategories() => loadCategories();
}