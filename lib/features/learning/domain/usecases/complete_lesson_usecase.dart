import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/learning_repository.dart';

class CompleteLessonParams extends Equatable {
  final String lessonId;
  final String userId;

  const CompleteLessonParams({
    required this.lessonId,
    required this.userId,
  });

  @override
  List<Object> get props => [lessonId, userId];
}

@injectable
class CompleteLessonUseCase implements UseCase<void, CompleteLessonParams> {
  final LearningRepository repository;

  CompleteLessonUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteLessonParams params) {
    return repository.completeLesson(params.lessonId, params.userId);
  }
}