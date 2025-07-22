// lib/features/trivia/data/models/quiz_session_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/quiz_session_entity.dart';

part 'quiz_session_model.g.dart';

@JsonSerializable()
class QuizSessionModel extends QuizSessionEntity {
  const QuizSessionModel({
    required String sessionId,
    required String quizId,
    required String userId,
    required String status,
    required DateTime startedAt,
    DateTime? completedAt,
    required int questionsTotal,
    required int questionsAnswered,
    required int questionsCorrect,
    required int pointsEarned,
    required String percentageScore,
    required bool passed,
    required int timeTakenSeconds,
  }) : super(
    sessionId: sessionId,
    quizId: quizId,
    userId: userId,
    status: status,
    startedAt: startedAt,
    completedAt: completedAt,
    questionsTotal: questionsTotal,
    questionsAnswered: questionsAnswered,
    questionsCorrect: questionsCorrect,
    pointsEarned: pointsEarned,
    percentageScore: percentageScore,
    passed: passed,
    timeTakenSeconds: timeTakenSeconds,
  );

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) =>
      _$QuizSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizSessionModelToJson(this);

  factory QuizSessionModel.fromEntity(QuizSessionEntity entity) {
    return QuizSessionModel(
      sessionId: entity.sessionId,
      quizId: entity.quizId,
      userId: entity.userId,
      status: entity.status,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      questionsTotal: entity.questionsTotal,
      questionsAnswered: entity.questionsAnswered,
      questionsCorrect: entity.questionsCorrect,
      pointsEarned: entity.pointsEarned,
      percentageScore: entity.percentageScore,
      passed: entity.passed,
      timeTakenSeconds: entity.timeTakenSeconds,
    );
  }
}