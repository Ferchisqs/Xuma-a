import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_challenge_stats_entity.dart';

part 'user_challenge_stats_model.g.dart';

@JsonSerializable()
class UserChallengeStatsModel extends UserChallengeStatsEntity {
  const UserChallengeStatsModel({
    required int totalChallengesCompleted,
    required int currentActiveChallenges,
    required int totalPointsEarned,
    required int currentStreak,
    required int bestStreak,
    required String currentRank,
    required int rankPosition,
    required List<String> achievedBadges,
    required Map<String, int> categoryProgress,
    required DateTime lastActivityDate,
  }) : super(
    totalChallengesCompleted: totalChallengesCompleted,
    currentActiveChallenges: currentActiveChallenges,
    totalPointsEarned: totalPointsEarned,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    currentRank: currentRank,
    rankPosition: rankPosition,
    achievedBadges: achievedBadges,
    categoryProgress: categoryProgress,
    lastActivityDate: lastActivityDate,
  );

  factory UserChallengeStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UserChallengeStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserChallengeStatsModelToJson(this);
}