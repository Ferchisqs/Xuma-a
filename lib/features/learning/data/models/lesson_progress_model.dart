import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/lesson_progress_entity.dart';

part 'lesson_progress_model.g.dart';

@JsonSerializable()
class LessonProgressModel extends LessonProgressEntity {
  const LessonProgressModel({
    required String userId,
    required String lessonId,
    required String categoryId,
    required double progress,
    required bool isCompleted,
    DateTime? completedAt,
    required int timeSpent,
    required DateTime updatedAt,
  }) : super(
          userId: userId,
          lessonId: lessonId,
          categoryId: categoryId,
          progress: progress,
          isCompleted: isCompleted,
          completedAt: completedAt,
          timeSpent: timeSpent,
          updatedAt: updatedAt,
        );

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) =>
      _$LessonProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonProgressModelToJson(this);

  factory LessonProgressModel.fromEntity(LessonProgressEntity entity) {
    return LessonProgressModel(
      userId: entity.userId,
      lessonId: entity.lessonId,
      categoryId: entity.categoryId,
      progress: entity.progress,
      isCompleted: entity.isCompleted,
      completedAt: entity.completedAt,
      timeSpent: entity.timeSpent,
      updatedAt: entity.updatedAt,
    );
  }
}