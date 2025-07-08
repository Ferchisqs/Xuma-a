// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trivia_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TriviaResultModel _$TriviaResultModelFromJson(Map<String, dynamic> json) =>
    TriviaResultModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      categoryId: json['categoryId'] as String,
      questionIds: (json['questionIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      userAnswers: (json['userAnswers'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      correctAnswers: (json['correctAnswers'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      correctCount: (json['correctCount'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      earnedPoints: (json['earnedPoints'] as num).toInt(),
      totalTime: Duration(microseconds: (json['totalTime'] as num).toInt()),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$TriviaResultModelToJson(TriviaResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'categoryId': instance.categoryId,
      'questionIds': instance.questionIds,
      'userAnswers': instance.userAnswers,
      'correctAnswers': instance.correctAnswers,
      'totalQuestions': instance.totalQuestions,
      'correctCount': instance.correctCount,
      'totalPoints': instance.totalPoints,
      'earnedPoints': instance.earnedPoints,
      'totalTime': instance.totalTime.inMicroseconds,
      'completedAt': instance.completedAt.toIso8601String(),
    };
