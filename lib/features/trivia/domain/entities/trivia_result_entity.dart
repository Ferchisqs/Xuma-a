import 'package:equatable/equatable.dart';

class TriviaResultEntity extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final List<String> questionIds;
  final List<int> userAnswers;
  final List<bool> correctAnswers;
  final int totalQuestions;
  final int correctCount;
  final int totalPoints;
  final int earnedPoints;
  final Duration totalTime;
  final DateTime completedAt;

  const TriviaResultEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.questionIds,
    required this.userAnswers,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.correctCount,
    required this.totalPoints,
    required this.earnedPoints,
    required this.totalTime,
    required this.completedAt,
  });

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return correctCount / totalQuestions;
  }

  double get accuracyPercentage => accuracy * 100;

  String get grade {
    if (accuracyPercentage >= 90) return 'Excelente';
    if (accuracyPercentage >= 80) return 'Muy Bueno';
    if (accuracyPercentage >= 70) return 'Bueno';
    if (accuracyPercentage >= 60) return 'Regular';
    return 'Necesita Mejorar';
  }

  bool get isPassed => accuracyPercentage >= 60;

  @override
  List<Object> get props => [
    id, userId, categoryId, questionIds, userAnswers,
    correctAnswers, totalQuestions, correctCount,
    totalPoints, earnedPoints, totalTime, completedAt,
  ];
}