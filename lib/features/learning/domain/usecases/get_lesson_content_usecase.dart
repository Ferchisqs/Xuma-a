import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/learning_repository.dart';

class GetLessonContentParams extends Equatable {
  final String lessonId;

  const GetLessonContentParams({required this.lessonId});

  @override
  List<Object> get props => [lessonId];
}

@injectable
class GetLessonContentUseCase implements UseCase<LessonEntity, GetLessonContentParams> {
  final LearningRepository repository;

  GetLessonContentUseCase(this.repository);

  @override
  Future<Either<Failure, LessonEntity>> call(GetLessonContentParams params) {
    return repository.getLessonContent(params.lessonId);
  }
}
