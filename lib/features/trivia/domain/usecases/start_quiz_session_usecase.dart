// lib/features/trivia/domain/usecases/start_quiz_session_usecase.dart
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/quiz_session_entity.dart';
import '../repositories/quiz_repository.dart';

class StartQuizSessionParams extends Equatable {
  final String quizId;
  final String userId;

  const StartQuizSessionParams({
    required this.quizId,
    required this.userId,
  });

  @override
  List<Object> get props => [quizId, userId];
}

@injectable
class StartQuizSessionUseCase implements UseCase<QuizSessionEntity, StartQuizSessionParams> {
  final QuizRepository repository;

  StartQuizSessionUseCase(this.repository);

  @override
  Future<Either<Failure, QuizSessionEntity>> call(StartQuizSessionParams params) {
    return repository.startQuizSession(
      quizId: params.quizId,
      userId: params.userId,
    );
  }
}

