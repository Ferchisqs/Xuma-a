import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/quiz_repository.dart';

class GetQuizResultsParams extends Equatable {
  final String sessionId;
  final String userId;

  const GetQuizResultsParams({
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object> get props => [sessionId, userId];
}

@injectable
class GetQuizResultsUseCase implements UseCase<Map<String, dynamic>, GetQuizResultsParams> {
  final QuizRepository repository;

  GetQuizResultsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetQuizResultsParams params) {
    return repository.getQuizResults(
      sessionId: params.sessionId,
      userId: params.userId,
    );
  }
}