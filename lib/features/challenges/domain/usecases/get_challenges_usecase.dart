import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/challenge_entity.dart';
import '../repositories/challenges_repository.dart';

class GetChallengesParams extends Equatable {
  final ChallengeType? type;
  final String? category;

  const GetChallengesParams({
    this.type,
    this.category,
  });

  @override
  List<Object?> get props => [type, category];
}

@injectable
class GetChallengesUseCase implements UseCase<List<ChallengeEntity>, GetChallengesParams> {
  final ChallengesRepository repository;

  GetChallengesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChallengeEntity>>> call(GetChallengesParams params) {
    return repository.getChallenges(
      type: params.type,
      category: params.category,
    );
  }
}