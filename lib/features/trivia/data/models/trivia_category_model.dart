import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trivia_category_entity.dart';

part 'trivia_category_model.g.dart';

@JsonSerializable()
class TriviaCategoryModel extends TriviaCategoryEntity {
  const TriviaCategoryModel({
    required String id,
    required String title,
    required String description,
    required String imageUrl,
    required int iconCode,
    required int questionsCount,
    required int completedTrivias,
    required TriviaDifficulty difficulty,
    required int pointsPerQuestion,
    required int timePerQuestion,
    required DateTime createdAt,
  }) : super(
    id: id,
    title: title,
    description: description,
    imageUrl: imageUrl,
    iconCode: iconCode,
    questionsCount: questionsCount,
    completedTrivias: completedTrivias,
    difficulty: difficulty,
    pointsPerQuestion: pointsPerQuestion,
    timePerQuestion: timePerQuestion,
    createdAt: createdAt,
  );

  factory TriviaCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$TriviaCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TriviaCategoryModelToJson(this);

  factory TriviaCategoryModel.fromEntity(TriviaCategoryEntity entity) {
    return TriviaCategoryModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      iconCode: entity.iconCode,
      questionsCount: entity.questionsCount,
      completedTrivias: entity.completedTrivias,
      difficulty: entity.difficulty,
      pointsPerQuestion: entity.pointsPerQuestion,
      timePerQuestion: entity.timePerQuestion,
      createdAt: entity.createdAt,
    );
  }
}
