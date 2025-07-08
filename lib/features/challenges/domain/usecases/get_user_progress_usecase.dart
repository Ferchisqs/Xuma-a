import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_challenge_stats_entity.dart';
import '../repositories/challenges_repository.dart';

class GetUserProgressParams extends Equatable {
  final String userId;

  const GetUserProgressParams({required this.userId});

  @override
  List<Object> get props => [userId];
}

@injectable
class GetUserProgressUseCase implements UseCase<UserChallengeStatsEntity, GetUserProgressParams> {
  final ChallengesRepository repository;

  GetUserProgressUseCase(this.repository);

  @override
  Future<Either<Failure, UserChallengeStatsEntity>> call(GetUserProgressParams params) {
    return repository.getUserStats(params.userId);
  }
}