import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/challenges_repository.dart';

class UpdateChallengeProgressParams extends Equatable {
  final String challengeId;
  final String userId;
  final int progress;

  const UpdateChallengeProgressParams({
    required this.challengeId,
    required this.userId,
    required this.progress,
  });

  @override
  List<Object> get props => [challengeId, userId, progress];
}

@injectable
class UpdateChallengeProgressUseCase implements UseCase<void, UpdateChallengeProgressParams> {
  final ChallengesRepository repository;

  UpdateChallengeProgressUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateChallengeProgressParams params) {
    return repository.updateProgress(
      params.challengeId,
      params.userId,
      params.progress,
    );
  }
}