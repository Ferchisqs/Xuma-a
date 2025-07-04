import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/category_entity.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required String id,
    required String title,
    required String description,
    required String imageUrl,
    required int iconCode,
    required int lessonsCount,
    required int completedLessons,
    required String estimatedTime,
    required DifficultyLevel difficulty,
    required DateTime createdAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          imageUrl: imageUrl,
          iconCode: iconCode,
          lessonsCount: lessonsCount,
          completedLessons: completedLessons,
          estimatedTime: estimatedTime,
          difficulty: difficulty,
          createdAt: createdAt,
        );

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      iconCode: entity.iconCode,
      lessonsCount: entity.lessonsCount,
      completedLessons: entity.completedLessons,
      estimatedTime: entity.estimatedTime,
      difficulty: entity.difficulty,
      createdAt: entity.createdAt,
    );
  }
}
