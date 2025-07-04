import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lesson_entity.dart';
import '../repositories/learning_repository.dart';

class SearchLessonsParams extends Equatable {
  final String query;
  final String? categoryId;

  const SearchLessonsParams({
    required this.query,
    this.categoryId,
  });

  @override
  List<Object?> get props => [query, categoryId];
}

@injectable
class SearchLessonsUseCase implements UseCase<List<LessonEntity>, SearchLessonsParams> {
  final LearningRepository repository;

  SearchLessonsUseCase(this.repository);

  @override
  Future<Either<Failure, List<LessonEntity>>> call(SearchLessonsParams params) {
    return repository.searchLessons(params.query, params.categoryId);
  }
}