import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class SubmitQuizAnswerParams extends Equatable {
  final String sessionId;
  final String questionId;
  final String userId;
  final String selectedOptionId;
  final int timeTakenSeconds;
  final int answerConfidence;

  const SubmitQuizAnswerParams({
    required this.sessionId,
    required this.questionId,
    required this.userId,
    required this.selectedOptionId,
    required this.timeTakenSeconds,
    required this.answerConfidence,
  });

  @override
  List<Object> get props => [
    sessionId, questionId, userId, selectedOptionId, 
    timeTakenSeconds, answerConfidence
  ];
}

@injectable
class SubmitQuizAnswerUseCase implements UseCase<void, SubmitQuizAnswerParams> {
  final QuizRepository repository;

  SubmitQuizAnswerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitQuizAnswerParams params) {
    return repository.submitQuizAnswer(
      sessionId: params.sessionId,
      questionId: params.questionId,
      userId: params.userId,
      selectedOptionId: params.selectedOptionId,
      timeTakenSeconds: params.timeTakenSeconds,
      answerConfidence: params.answerConfidence,
    );
  }
}