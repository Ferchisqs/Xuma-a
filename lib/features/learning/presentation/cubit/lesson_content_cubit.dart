import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/lesson_progress_entity.dart';
import '../../domain/usecases/get_lesson_content_usecase.dart';
import '../../domain/usecases/update_lesson_progress_usecase.dart';
import '../../domain/usecases/complete_lesson_usecase.dart';

// States
abstract class LessonContentState extends Equatable {
  const LessonContentState();

  @override
  List<Object?> get props => [];
}

class LessonContentInitial extends LessonContentState {}

class LessonContentLoading extends LessonContentState {}

class LessonContentLoaded extends LessonContentState {
  final LessonEntity lesson;
  final LessonProgressEntity? progress;
  final bool isCompleted;

  const LessonContentLoaded({
    required this.lesson,
    this.progress,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [lesson, progress, isCompleted];
}

class LessonContentCompleted extends LessonContentState {
  final LessonEntity lesson;
  final int pointsEarned;

  const LessonContentCompleted({
    required this.lesson,
    required this.pointsEarned,
  });

  @override
  List<Object> get props => [lesson, pointsEarned];
}

class LessonContentError extends LessonContentState {
  final String message;

  const LessonContentError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class LessonContentCubit extends Cubit<LessonContentState> {
  final GetLessonContentUseCase getLessonContentUseCase;
  final UpdateLessonProgressUseCase updateLessonProgressUseCase;
  final CompleteLessonUseCase completeLessonUseCase;

  LessonContentCubit({
    required this.getLessonContentUseCase,
    required this.updateLessonProgressUseCase,
    required this.completeLessonUseCase,
  }) : super(LessonContentInitial());

  Future<void> loadLessonContent(String lessonId, String userId) async {
    emit(LessonContentLoading());

    final result = await getLessonContentUseCase(
      GetLessonContentParams(lessonId: lessonId),
    );

    result.fold(
      (failure) => emit(LessonContentError(message: failure.message)),
      (lesson) => emit(LessonContentLoaded(
        lesson: lesson,
        progress: null,
        isCompleted: lesson.isCompleted,
      )),
    );
  }

  Future<void> updateProgress(double progress, String userId) async {
    final currentState = state;
    if (currentState is! LessonContentLoaded) return;

    final progressEntity = LessonProgressEntity(
      userId: userId,
      lessonId: currentState.lesson.id,
      categoryId: currentState.lesson.categoryId,
      progress: progress,
      isCompleted: progress >= 1.0,
      completedAt: progress >= 1.0 ? DateTime.now() : null,
      timeSpent: 0, // Se podría implementar un timer real
      updatedAt: DateTime.now(),
    );

    final result = await updateLessonProgressUseCase(
      UpdateLessonProgressParams(progress: progressEntity),
    );

    result.fold(
      (failure) {
        // En caso de error, mantener el estado actual
      },
      (_) {
        emit(LessonContentLoaded(
          lesson: currentState.lesson,
          progress: progressEntity,
          isCompleted: progressEntity.isCompleted,
        ));
      },
    );
  }

  Future<void> completeLesson(String userId) async {
    final currentState = state;
    if (currentState is! LessonContentLoaded) return;

    final result = await completeLessonUseCase(
      CompleteLessonParams(
        lessonId: currentState.lesson.id,
        userId: userId,
      ),
    );

    result.fold(
      (failure) => emit(LessonContentError(message: failure.message)),
      (_) => emit(LessonContentCompleted(
        lesson: currentState.lesson,
        pointsEarned: currentState.lesson.points,
      )),
    );
  }

  void resetToContent() {
    final currentState = state;
    if (currentState is LessonContentCompleted) {
      emit(LessonContentLoaded(
        lesson: currentState.lesson,
        progress: null,
        isCompleted: true,
      ));
    }
  }
}