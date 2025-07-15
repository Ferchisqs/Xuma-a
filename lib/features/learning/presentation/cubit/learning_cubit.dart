// lib/features/learning/presentation/cubit/learning_cubit.dart - MODIFICADO PARA TOPICS
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/usecases/get_topics_usecase.dart';

// States - CAMBIADO PARA TOPICS
abstract class LearningState extends Equatable {
  const LearningState();

  @override
  List<Object> get props => [];
}

class LearningInitial extends LearningState {}

class LearningLoading extends LearningState {}

class LearningLoaded extends LearningState {
  final List<TopicEntity> topics; // CAMBIADO DE categories A topics

  const LearningLoaded({required this.topics});

  @override
  List<Object> get props => [topics];
}

class LearningError extends LearningState {
  final String message;

  const LearningError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit - MODIFICADO PARA USAR TOPICS
@injectable
class LearningCubit extends Cubit<LearningState> {
  final GetTopicsUseCase getTopicsUseCase; // CAMBIADO

  LearningCubit({
    required this.getTopicsUseCase, // CAMBIADO
  }) : super(LearningInitial());

  Future<void> loadCategories() async {
    emit(LearningLoading());

    final result = await getTopicsUseCase(NoParams()); // CAMBIADO

    result.fold(
      (failure) => emit(LearningError(message: failure.message)),
      (topics) => emit(LearningLoaded(topics: topics)), // CAMBIADO
    );
  }

  void refreshCategories() => loadCategories();
}