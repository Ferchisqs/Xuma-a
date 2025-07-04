// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      iconCode: (json['iconCode'] as num).toInt(),
      lessonsCount: (json['lessonsCount'] as num).toInt(),
      completedLessons: (json['completedLessons'] as num).toInt(),
      estimatedTime: json['estimatedTime'] as String,
      difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'iconCode': instance.iconCode,
      'lessonsCount': instance.lessonsCount,
      'completedLessons': instance.completedLessons,
      'estimatedTime': instance.estimatedTime,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
};
