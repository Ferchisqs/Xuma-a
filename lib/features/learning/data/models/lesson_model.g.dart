// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonModel _$LessonModelFromJson(Map<String, dynamic> json) => LessonModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      duration: (json['duration'] as num).toInt(),
      order: (json['order'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
      points: (json['points'] as num).toInt(),
      type: $enumDecode(_$LessonTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LessonModelToJson(LessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
      'videoUrl': instance.videoUrl,
      'duration': instance.duration,
      'order': instance.order,
      'isCompleted': instance.isCompleted,
      'points': instance.points,
      'type': _$LessonTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$LessonTypeEnumMap = {
  LessonType.text: 'text',
  LessonType.video: 'video',
  LessonType.interactive: 'interactive',
  LessonType.quiz: 'quiz',
};
