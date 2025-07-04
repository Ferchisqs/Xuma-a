// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonProgressModel _$LessonProgressModelFromJson(Map<String, dynamic> json) =>
    LessonProgressModel(
      userId: json['userId'] as String,
      lessonId: json['lessonId'] as String,
      categoryId: json['categoryId'] as String,
      progress: (json['progress'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      timeSpent: (json['timeSpent'] as num).toInt(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LessonProgressModelToJson(
        LessonProgressModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'lessonId': instance.lessonId,
      'categoryId': instance.categoryId,
      'progress': instance.progress,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'timeSpent': instance.timeSpent,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
