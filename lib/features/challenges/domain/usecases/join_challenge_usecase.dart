import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/challenges_repository.dart';

class StartChallengeParams extends Equatable {
  final String challengeId;
  final String userId;

  const StartChallengeParams({
    required this.challengeId,
    required this.userId,
  });

  @override
  List<Object> get props => [challengeId, userId];
}

@injectable
class StartChallengeUseCase implements UseCase<void, StartChallengeParams> {
  final ChallengesRepository repository;

  StartChallengeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(StartChallengeParams params) {
    return repository.joinChallenge(params.challengeId, params.userId);
  }
}