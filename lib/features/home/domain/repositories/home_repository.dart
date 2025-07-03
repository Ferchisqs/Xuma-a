import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/eco_tip_entity.dart';
import '../entities/user_stats_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, EcoTipEntity>> getDailyTip();
  Future<Either<Failure, UserStatsEntity>> getUserStats();
  Future<Either<Failure, bool>> updateUserActivity(String activityType);
}