import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/trivia_result_entity.dart';
import '../repositories/trivia_repository.dart';

class GetUserTriviaHistoryParams extends Equatable {
  final String userId;

  const GetUserTriviaHistoryParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetUserTriviaHistoryUseCase implements UseCase<List<TriviaResultEntity>, GetUserTriviaHistoryParams> {
  final TriviaRepository repository;

  GetUserTriviaHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<TriviaResultEntity>>> call(GetUserTriviaHistoryParams params) {
    return repository.getUserTriviaHistory(params.userId);
  }
}