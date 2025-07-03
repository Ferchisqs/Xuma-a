import 'package:equatable/equatable.dart';

class UserStatsEntity extends Equatable {
  final int totalPoints;
  final int completedActivities;
  final int streak;
  final String currentLevel;
  final int recycledItems;
  final double carbonSaved;
  final List<String> achievements;

  const UserStatsEntity({
    required this.totalPoints,
    required this.completedActivities,
    required this.streak,
    required this.currentLevel,
    required this.recycledItems,
    required this.carbonSaved,
    required this.achievements,
  });

  @override
  List<Object> get props => [
    totalPoints, completedActivities, streak, currentLevel,
    recycledItems, carbonSaved, achievements
  ];
}