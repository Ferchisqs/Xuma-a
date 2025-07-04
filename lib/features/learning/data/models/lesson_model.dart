import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/lesson_entity.dart';

part 'lesson_model.g.dart';

@JsonSerializable()
class LessonModel extends LessonEntity {
  const LessonModel({
    required String id,
    required String categoryId,
    required String title,
    required String description,
    required String content,
    String? imageUrl,
    String? videoUrl,
    required int duration,
    required int order,
    required bool isCompleted,
    required int points,
    required LessonType type,
    required DateTime createdAt,
  }) : super(
          id: id,
          categoryId: categoryId,
          title: title,
          description: description,
          content: content,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          duration: duration,
          order: order,
          isCompleted: isCompleted,
          points: points,
          type: type,
          createdAt: createdAt,
        );

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonModelToJson(this);

  factory LessonModel.fromEntity(LessonEntity entity) {
    return LessonModel(
      id: entity.id,
      categoryId: entity.categoryId,
      title: entity.title,
      description: entity.description,
      content: entity.content,
      imageUrl: entity.imageUrl,
      videoUrl: entity.videoUrl,
      duration: entity.duration,
      order: entity.order,
      isCompleted: entity.isCompleted,
      points: entity.points,
      type: entity.type,
      createdAt: entity.createdAt,
    );
  }
}