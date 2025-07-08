import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/challenge_entity.dart';
import '../repositories/challenges_repository.dart';

class GetActiveChallengesParams extends Equatable {
  final String userId;

  const GetActiveChallengesParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetActiveChallengesUseCase implements UseCase<List<ChallengeEntity>, GetActiveChallengesParams> {
  final ChallengesRepository repository;

  GetActiveChallengesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChallengeEntity>>> call(GetActiveChallengesParams params) {
    return repository.getActiveChallenges(params.userId);
  }
}