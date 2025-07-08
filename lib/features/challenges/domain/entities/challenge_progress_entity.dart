import 'package:equatable/equatable.dart';

class ChallengeProgressEntity extends Equatable {
  final String userId;
  final String challengeId;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime lastUpdated;
  final List<String> completedSteps;
  final Map<String, dynamic> metadata;

  const ChallengeProgressEntity({
    required this.userId,
    required this.challengeId,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    this.completedAt,
    required this.startedAt,
    required this.lastUpdated,
    required this.completedSteps,
    required this.metadata,
  });

  double get progressPercentage {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    userId, challengeId, currentProgress, targetProgress,
    isCompleted, completedAt, startedAt, lastUpdated,
    completedSteps, metadata,
  ];
}