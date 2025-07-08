// lib/features/trivia/presentation/cubit/trivia_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/trivia_category_entity.dart';
import '../../domain/usecases/get_trivia_categories_usecase.dart';

// States
abstract class TriviaState extends Equatable {
  const TriviaState();

  @override
  List<Object> get props => [];
}

class TriviaInitial extends TriviaState {}

class TriviaLoading extends TriviaState {}

class TriviaLoaded extends TriviaState {
  final List<TriviaCategoryEntity> categories;

  const TriviaLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

class TriviaError extends TriviaState {
  final String message;

  const TriviaError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class TriviaCubit extends Cubit<TriviaState> {
  final GetTriviaCategoriesUseCase getTriviaCategoriesUseCase;

  TriviaCubit({
    required this.getTriviaCategoriesUseCase,
  }) : super(TriviaInitial());

  Future<void> loadCategories() async {
    emit(TriviaLoading());

    // 🔧 CORREGIR: usar call() directamente sin parámetros
    final result = await getTriviaCategoriesUseCase.call();

    result.fold(
      (failure) => emit(TriviaError(message: failure.message)),
      (categories) => emit(TriviaLoaded(categories: categories)),
    );
  }

  void refreshCategories() => loadCategories();
}