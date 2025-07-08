// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanionStatsModel _$CompanionStatsModelFromJson(Map<String, dynamic> json) =>
    CompanionStatsModel(
      userId: json['userId'] as String,
      totalCompanions: (json['totalCompanions'] as num).toInt(),
      ownedCompanions: (json['ownedCompanions'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      spentPoints: (json['spentPoints'] as num).toInt(),
      activeCompanionId: json['activeCompanionId'] as String,
      totalFeedCount: (json['totalFeedCount'] as num).toInt(),
      totalLoveCount: (json['totalLoveCount'] as num).toInt(),
      totalEvolutions: (json['totalEvolutions'] as num).toInt(),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
    );

Map<String, dynamic> _$CompanionStatsModelToJson(
        CompanionStatsModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalCompanions': instance.totalCompanions,
      'ownedCompanions': instance.ownedCompanions,
      'totalPoints': instance.totalPoints,
      'spentPoints': instance.spentPoints,
      'activeCompanionId': instance.activeCompanionId,
      'totalFeedCount': instance.totalFeedCount,
      'totalLoveCount': instance.totalLoveCount,
      'totalEvolutions': instance.totalEvolutions,
      'lastActivity': instance.lastActivity.toIso8601String(),
    };
