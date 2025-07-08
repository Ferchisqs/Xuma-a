import 'package:equatable/equatable.dart';

enum ChallengeType {
  daily,
  weekly,
  monthly,
  special
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard
}

enum ChallengeStatus {
  notStarted,
  active,
  completed,
  expired
}

class ChallengeEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int iconCode;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final int totalPoints;
  final int currentProgress;
  final int targetProgress;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> requirements;
  final List<String> rewards;
  final bool isParticipating;
  final DateTime? completedAt;
  final DateTime createdAt;

  const ChallengeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.iconCode,
    required this.type,
    required this.difficulty,
    required this.totalPoints,
    required this.currentProgress,
    required this.targetProgress,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.requirements,
    required this.rewards,
    required this.isParticipating,
    this.completedAt,
    required this.createdAt,
  });

  double get progressPercentage {
    if (targetProgress == 0) return 0.0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isExpired => status == ChallengeStatus.expired;
  bool get isActive => status == ChallengeStatus.active;

  String get formattedTimeRemaining {
    if (isCompleted || isExpired) return '';
    
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.isNegative) return 'Expirado';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} días restantes';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas restantes';
    } else {
      return '${difference.inMinutes} minutos restantes';
    }
  }

  @override
  List<Object?> get props => [
    id, title, description, category, imageUrl, iconCode,
    type, difficulty, totalPoints, currentProgress, targetProgress,
    status, startDate, endDate, requirements, rewards,
    isParticipating, completedAt, createdAt,
  ];
}