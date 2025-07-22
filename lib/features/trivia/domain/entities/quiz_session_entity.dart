import 'package:equatable/equatable.dart';

class QuizSessionEntity extends Equatable {
  final String sessionId;
  final String quizId;
  final String userId;
  final String status; // "active", "completed"
  final DateTime startedAt;
  final DateTime? completedAt;
  final int questionsTotal;
  final int questionsAnswered;
  final int questionsCorrect;
  final int pointsEarned;
  final String percentageScore;
  final bool passed;
  final int timeTakenSeconds;

  const QuizSessionEntity({
    required this.sessionId,
    required this.quizId,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.questionsTotal,
    required this.questionsAnswered,
    required this.questionsCorrect,
    required this.pointsEarned,
    required this.percentageScore,
    required this.passed,
    required this.timeTakenSeconds,
  });

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active';
  
  double get accuracyPercentage {
    if (questionsTotal == 0) return 0.0;
    return (questionsCorrect / questionsTotal) * 100;
  }

  @override
  List<Object?> get props => [
    sessionId, quizId, userId, status, startedAt, completedAt,
    questionsTotal, questionsAnswered, questionsCorrect, pointsEarned,
    percentageScore, passed, timeTakenSeconds,
  ];
}