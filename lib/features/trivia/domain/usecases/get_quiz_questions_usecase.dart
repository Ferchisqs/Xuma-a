import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_question_entity.dart';
import '../repositories/quiz_repository.dart';

class GetQuizQuestionsParams extends Equatable {
  final String quizId;

  const GetQuizQuestionsParams({required this.quizId});

  @override
  List<Object> get props => [quizId];
}

@injectable
class GetQuizQuestionsUseCase implements UseCase<List<TriviaQuestionEntity>, GetQuizQuestionsParams> {
  final QuizRepository repository;

  GetQuizQuestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TriviaQuestionEntity>>> call(GetQuizQuestionsParams params) {
    return repository.getQuizQuestions(params.quizId);
  }
}