import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_progress_entity.dart';
import '../repositories/learning_repository.dart';

class UpdateLessonProgressParams extends Equatable {
  final LessonProgressEntity progress;

  const UpdateLessonProgressParams({required this.progress});

  @override
  List<Object> get props => [progress];
}

@injectable
class UpdateLessonProgressUseCase implements UseCase<void, UpdateLessonProgressParams> {
  final LearningRepository repository;

  UpdateLessonProgressUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLessonProgressParams params) {
    return repository.updateLessonProgress(params.progress);
  }
}