import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/companion_stats_entity.dart';

part 'companion_stats_model.g.dart';

@JsonSerializable()
class CompanionStatsModel extends CompanionStatsEntity {
  const CompanionStatsModel({
    required String userId,
    required int totalCompanions,
    required int ownedCompanions,
    required int totalPoints,
    required int spentPoints,
    required String activeCompanionId,
    required int totalFeedCount,
    required int totalLoveCount,
    required int totalEvolutions,
    required DateTime lastActivity,
  }) : super(
          userId: userId,
          totalCompanions: totalCompanions,
          ownedCompanions: ownedCompanions,
          totalPoints: totalPoints,
          spentPoints: spentPoints,
          activeCompanionId: activeCompanionId,
          totalFeedCount: totalFeedCount,
          totalLoveCount: totalLoveCount,
          totalEvolutions: totalEvolutions,
          lastActivity: lastActivity,
        );

  factory CompanionStatsModel.fromJson(Map<String, dynamic> json) =>
      _$CompanionStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionStatsModelToJson(this);

  factory CompanionStatsModel.fromEntity(CompanionStatsEntity entity) {
    return CompanionStatsModel(
      userId: entity.userId,
      totalCompanions: entity.totalCompanions,
      ownedCompanions: entity.ownedCompanions,
      totalPoints: entity.totalPoints,
      spentPoints: entity.spentPoints,
      activeCompanionId: entity.activeCompanionId,
      totalFeedCount: entity.totalFeedCount,
      totalLoveCount: entity.totalLoveCount,
      totalEvolutions: entity.totalEvolutions,
      lastActivity: entity.lastActivity,
    );
  }
}