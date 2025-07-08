import '../../../../core/utils/either.dart';
import '../../../../core/errors/failures.dart';
import '../entities/challenge_entity.dart';
import '../entities/user_challenge_stats_entity.dart';
import '../entities/challenge_progress_entity.dart';

abstract class ChallengesRepository {
  Future<Either<Failure, List<ChallengeEntity>>> getChallenges({
    ChallengeType? type,
    String? category,
  });
  Future<Either<Failure, ChallengeEntity>> getChallengeById(String id);
  Future<Either<Failure, UserChallengeStatsEntity>> getUserStats(String userId);
  Future<Either<Failure, void>> joinChallenge(String challengeId, String userId);
  Future<Either<Failure, void>> updateProgress(String challengeId, String userId, int progress);
  Future<Either<Failure, ChallengeProgressEntity>> getChallengeProgress(String challengeId, String userId);
  Future<Either<Failure, List<ChallengeEntity>>> getActiveChallenges(String userId);
  Future<Either<Failure, List<ChallengeEntity>>> getCompletedChallenges(String userId);
}