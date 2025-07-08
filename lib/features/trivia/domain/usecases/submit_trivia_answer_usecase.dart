import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_result_entity.dart';
import '../repositories/trivia_repository.dart';

class SubmitTriviaResultParams extends Equatable {
  final String userId;
  final String categoryId;
  final List<String> questionIds;
  final List<int> userAnswers;
  final Duration totalTime;

  const SubmitTriviaResultParams({
    required this.userId,
    required this.categoryId,
    required this.questionIds,
    required this.userAnswers,
    required this.totalTime,
  });

  @override
  List<Object> get props => [userId, categoryId, questionIds, userAnswers, totalTime];
}

@injectable
class SubmitTriviaResultUseCase implements UseCase<TriviaResultEntity, SubmitTriviaResultParams> {
  final TriviaRepository repository;

  SubmitTriviaResultUseCase(this.repository);

  @override
  Future<Either<Failure, TriviaResultEntity>> call(SubmitTriviaResultParams params) {
    return repository.submitTriviaResult(
      userId: params.userId,
      categoryId: params.categoryId,
      questionIds: params.questionIds,
      userAnswers: params.userAnswers,
      totalTime: params.totalTime,
    );
  }
}
