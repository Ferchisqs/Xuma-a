// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trivia_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TriviaCategoryModel _$TriviaCategoryModelFromJson(Map<String, dynamic> json) =>
    TriviaCategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      iconCode: (json['iconCode'] as num).toInt(),
      questionsCount: (json['questionsCount'] as num).toInt(),
      completedTrivias: (json['completedTrivias'] as num).toInt(),
      difficulty: $enumDecode(_$TriviaDifficultyEnumMap, json['difficulty']),
      pointsPerQuestion: (json['pointsPerQuestion'] as num).toInt(),
      timePerQuestion: (json['timePerQuestion'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TriviaCategoryModelToJson(
        TriviaCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'iconCode': instance.iconCode,
      'questionsCount': instance.questionsCount,
      'completedTrivias': instance.completedTrivias,
      'difficulty': _$TriviaDifficultyEnumMap[instance.difficulty]!,
      'pointsPerQuestion': instance.pointsPerQuestion,
      'timePerQuestion': instance.timePerQuestion,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TriviaDifficultyEnumMap = {
  TriviaDifficulty.easy: 'easy',
  TriviaDifficulty.medium: 'medium',
  TriviaDifficulty.hard: 'hard',
};
