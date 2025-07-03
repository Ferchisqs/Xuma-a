// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStatsModel _$UserStatsModelFromJson(Map<String, dynamic> json) =>
    UserStatsModel(
      totalPointsJson: (json['total_points'] as num).toInt(),
      completedActivitiesJson: (json['completed_activities'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
      currentLevelJson: json['current_level'] as String,
      recycledItemsJson: (json['recycled_items'] as num).toInt(),
      carbonSavedJson: (json['carbon_saved'] as num).toDouble(),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserStatsModelToJson(UserStatsModel instance) =>
    <String, dynamic>{
      'streak': instance.streak,
      'achievements': instance.achievements,
      'total_points': instance.totalPointsJson,
      'completed_activities': instance.completedActivitiesJson,
      'current_level': instance.currentLevelJson,
      'recycled_items': instance.recycledItemsJson,
      'carbon_saved': instance.carbonSavedJson,
    };
