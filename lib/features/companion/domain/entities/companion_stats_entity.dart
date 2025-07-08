import 'package:equatable/equatable.dart';

class CompanionStatsEntity extends Equatable {
  final String userId;
  final int totalCompanions;
  final int ownedCompanions;
  final int totalPoints;
  final int spentPoints;
  final String activeCompanionId;
  final int totalFeedCount;
  final int totalLoveCount;
  final int totalEvolutions;
  final DateTime lastActivity;

  const CompanionStatsEntity({
    required this.userId,
    required this.totalCompanions,
    required this.ownedCompanions,
    required this.totalPoints,
    required this.spentPoints,
    required this.activeCompanionId,
    required this.totalFeedCount,
    required this.totalLoveCount,
    required this.totalEvolutions,
    required this.lastActivity,
  });

  int get availablePoints => totalPoints - spentPoints;

  @override
  List<Object> get props => [
    userId, totalCompanions, ownedCompanions, totalPoints,
    spentPoints, activeCompanionId, totalFeedCount,
    totalLoveCount, totalEvolutions, lastActivity,
  ];
}