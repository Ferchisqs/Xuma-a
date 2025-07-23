import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_category_entity.dart';
import '../repositories/trivia_repository.dart';

@injectable
class GetTriviaCategoriesUseCase implements NoParamsUseCase<List<TriviaCategoryEntity>> {
  final TriviaRepository repository;

  GetTriviaCategoriesUseCase(this.repository) {
    print('✅ [GET TRIVIA CATEGORIES USE CASE] Constructor called - Now using topics endpoint');
  }

  @override
  Future<Either<Failure, List<TriviaCategoryEntity>>> call() {
    print('🎯 [GET TRIVIA CATEGORIES USE CASE] Executing - fetching topics as trivia categories');
    return repository.getCategories();
  }
}