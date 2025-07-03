import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_stats_entity.dart';

part 'user_stats_model.g.dart';

@JsonSerializable()
class UserStatsModel extends UserStatsEntity {
  @JsonKey(name: 'total_points')
  final int totalPointsJson;
  
  @JsonKey(name: 'completed_activities')
  final int completedActivitiesJson;
  
  @JsonKey(name: 'current_level')
  final String currentLevelJson;
  
  @JsonKey(name: 'recycled_items')
  final int recycledItemsJson;
  
  @JsonKey(name: 'carbon_saved')
  final double carbonSavedJson;

  const UserStatsModel({
    required this.totalPointsJson,
    required this.completedActivitiesJson,
    required int streak,
    required this.currentLevelJson,
    required this.recycledItemsJson,
    required this.carbonSavedJson,
    required List<String> achievements,
  }) : super(
    totalPoints: totalPointsJson,
    completedActivities: completedActivitiesJson,
    streak: streak,
    currentLevel: currentLevelJson,
    recycledItems: recycledItemsJson,
    carbonSaved: carbonSavedJson,
    achievements: achievements,
  );

  factory UserStatsModel.fromJson(Map<String, dynamic> json) => _$UserStatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsModelToJson(this);
}