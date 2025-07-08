// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trivia_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TriviaQuestionModel _$TriviaQuestionModelFromJson(Map<String, dynamic> json) =>
    TriviaQuestionModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswerIndex: (json['correctAnswerIndex'] as num).toInt(),
      explanation: json['explanation'] as String,
      type: $enumDecode(_$QuestionTypeEnumMap, json['type']),
      difficulty: $enumDecode(_$TriviaDifficultyEnumMap, json['difficulty']),
      points: (json['points'] as num).toInt(),
      timeLimit: (json['timeLimit'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TriviaQuestionModelToJson(
        TriviaQuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'question': instance.question,
      'options': instance.options,
      'correctAnswerIndex': instance.correctAnswerIndex,
      'explanation': instance.explanation,
      'type': _$QuestionTypeEnumMap[instance.type]!,
      'difficulty': _$TriviaDifficultyEnumMap[instance.difficulty]!,
      'points': instance.points,
      'timeLimit': instance.timeLimit,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$QuestionTypeEnumMap = {
  QuestionType.multipleChoice: 'multipleChoice',
  QuestionType.trueFalse: 'trueFalse',
};

const _$TriviaDifficultyEnumMap = {
  TriviaDifficulty.easy: 'easy',
  TriviaDifficulty.medium: 'medium',
  TriviaDifficulty.hard: 'hard',
};
