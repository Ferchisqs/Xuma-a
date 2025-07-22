// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizSessionModel _$QuizSessionModelFromJson(Map<String, dynamic> json) =>
    QuizSessionModel(
      sessionId: json['sessionId'] as String,
      quizId: json['quizId'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      questionsTotal: (json['questionsTotal'] as num).toInt(),
      questionsAnswered: (json['questionsAnswered'] as num).toInt(),
      questionsCorrect: (json['questionsCorrect'] as num).toInt(),
      pointsEarned: (json['pointsEarned'] as num).toInt(),
      percentageScore: json['percentageScore'] as String,
      passed: json['passed'] as bool,
      timeTakenSeconds: (json['timeTakenSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$QuizSessionModelToJson(QuizSessionModel instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'quizId': instance.quizId,
      'userId': instance.userId,
      'status': instance.status,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'questionsTotal': instance.questionsTotal,
      'questionsAnswered': instance.questionsAnswered,
      'questionsCorrect': instance.questionsCorrect,
      'pointsEarned': instance.pointsEarned,
      'percentageScore': instance.percentageScore,
      'passed': instance.passed,
      'timeTakenSeconds': instance.timeTakenSeconds,
    };
