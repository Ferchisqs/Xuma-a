import 'package:equatable/equatable.dart';

class UserChallengeStatsEntity extends Equatable {
  final int totalChallengesCompleted;
  final int currentActiveChallenges;
  final int totalPointsEarned;
  final int currentStreak;
  final int bestStreak;
  final String currentRank;
  final int rankPosition;
  final List<String> achievedBadges;
  final Map<String, int> categoryProgress;
  final DateTime lastActivityDate;

  const UserChallengeStatsEntity({
    required this.totalChallengesCompleted,
    required this.currentActiveChallenges,
    required this.totalPointsEarned,
    required this.currentStreak,
    required this.bestStreak,
    required this.currentRank,
    required this.rankPosition,
    required this.achievedBadges,
    required this.categoryProgress,
    required this.lastActivityDate,
  });

  @override
  List<Object> get props => [
    totalChallengesCompleted, currentActiveChallenges, totalPointsEarned,
    currentStreak, bestStreak, currentRank, rankPosition,
    achievedBadges, categoryProgress, lastActivityDate,
  ];
}