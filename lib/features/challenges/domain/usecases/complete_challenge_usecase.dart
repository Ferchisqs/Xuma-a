import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/challenges_repository.dart';

class CompleteChallengeParams extends Equatable {
  final String challengeId;
  final String userId;

  const CompleteChallengeParams({
    required this.challengeId,
    required this.userId,
  });

  @override
  List<Object> get props => [challengeId, userId];
}

@injectable
class CompleteChallengeUseCase implements UseCase<void, CompleteChallengeParams> {
  final ChallengesRepository repository;

  CompleteChallengeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteChallengeParams params) {
    // Marcar como completado estableciendo progreso al máximo
    return repository.updateProgress(params.challengeId, params.userId, 999);
  }
}