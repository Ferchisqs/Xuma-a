// lib/features/learning/data/models/topic_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/topic_entity.dart';

part 'topic_model.g.dart';

@JsonSerializable()
class TopicModel extends TopicEntity {
  const TopicModel({
    required String id,
    required String title,
    required String description,
    String? imageUrl,
    required String category,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          imageUrl: imageUrl,
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory TopicModel.fromJson(Map<String, dynamic> json) =>
      _$TopicModelFromJson(json);

  Map<String, dynamic> toJson() => _$TopicModelToJson(this);

  factory TopicModel.fromEntity(TopicEntity entity) {
    return TopicModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      category: entity.category,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}