import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/learning_repository.dart';

class GetLessonsByCategoryParams extends Equatable {
  final String categoryId;

  const GetLessonsByCategoryParams({required this.categoryId});

  @override
  List<Object> get props => [categoryId];
}

@injectable
class GetLessonsByCategoryUseCase implements UseCase<List<LessonEntity>, GetLessonsByCategoryParams> {
  final LearningRepository repository;

  GetLessonsByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<LessonEntity>>> call(GetLessonsByCategoryParams params) {
    return repository.getLessonsByCategory(params.categoryId);
  }
}