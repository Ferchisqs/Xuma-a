// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_challenge_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserChallengeStatsModel _$UserChallengeStatsModelFromJson(
        Map<String, dynamic> json) =>
    UserChallengeStatsModel(
      totalChallengesCompleted:
          (json['totalChallengesCompleted'] as num).toInt(),
      currentActiveChallenges: (json['currentActiveChallenges'] as num).toInt(),
      totalPointsEarned: (json['totalPointsEarned'] as num).toInt(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      bestStreak: (json['bestStreak'] as num).toInt(),
      currentRank: json['currentRank'] as String,
      rankPosition: (json['rankPosition'] as num).toInt(),
      achievedBadges: (json['achievedBadges'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      categoryProgress: Map<String, int>.from(json['categoryProgress'] as Map),
      lastActivityDate: json['lastActivityDate'] == null
          ? null
          : DateTime.parse(json['lastActivityDate'] as String),
    );

Map<String, dynamic> _$UserChallengeStatsModelToJson(
        UserChallengeStatsModel instance) =>
    <String, dynamic>{
      'totalChallengesCompleted': instance.totalChallengesCompleted,
      'currentActiveChallenges': instance.currentActiveChallenges,
      'totalPointsEarned': instance.totalPointsEarned,
      'currentStreak': instance.currentStreak,
      'bestStreak': instance.bestStreak,
      'currentRank': instance.currentRank,
      'rankPosition': instance.rankPosition,
      'achievedBadges': instance.achievedBadges,
      'categoryProgress': instance.categoryProgress,
      'lastActivityDate': instance.lastActivityDate?.toIso8601String(),
    };
