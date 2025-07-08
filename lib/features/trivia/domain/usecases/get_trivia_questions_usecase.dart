import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_question_entity.dart';
import '../repositories/trivia_repository.dart';

class GetTriviaQuestionsParams extends Equatable {
  final String categoryId;

  const GetTriviaQuestionsParams({required this.categoryId});

  @override
  List<Object> get props => [categoryId];
}

@injectable
class GetTriviaQuestionsUseCase implements UseCase<List<TriviaQuestionEntity>, GetTriviaQuestionsParams> {
  final TriviaRepository repository;

  GetTriviaQuestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> call(GetTriviaQuestionsParams params) {
    return repository.getQuestionsByCategory(params.categoryId);
  }
}
