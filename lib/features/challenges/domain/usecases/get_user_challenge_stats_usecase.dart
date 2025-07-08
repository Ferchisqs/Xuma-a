import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_challenge_stats_entity.dart';
import '../repositories/challenges_repository.dart';

class GetUserChallengeStatsParams extends Equatable {
  final String userId;

  const GetUserChallengeStatsParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetUserChallengeStatsUseCase implements UseCase<UserChallengeStatsEntity, GetUserChallengeStatsParams> {
  final ChallengesRepository repository;

  GetUserChallengeStatsUseCase(this.repository);

  @override
  Future<Either<Failure, UserChallengeStatsEntity>> call(GetUserChallengeStatsParams params) {
    return repository.getUserStats(params.userId);
  }
}