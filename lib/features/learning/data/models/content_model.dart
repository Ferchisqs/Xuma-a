// lib/features/learning/data/models/content_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/content_entity.dart';

part 'content_model.g.dart';

@JsonSerializable()
class ContentModel extends ContentEntity {
  const ContentModel({
    required String id,
    required String title,
    required String description,
    required String content,
    String? imageUrl,
    required String category,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          description: description,
          content: content,
          imageUrl: imageUrl,
          category: category,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentModelToJson(this);

  factory ContentModel.fromEntity(ContentEntity entity) {
    return ContentModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      content: entity.content,
      imageUrl: entity.imageUrl,
      category: entity.category,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}