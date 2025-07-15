// lib/features/learning/domain/entities/content_entity.dart
import 'package:equatable/equatable.dart';

class ContentEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String content;
  final String? imageUrl;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    this.imageUrl,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        content,
        imageUrl,
        category,
        isActive,
        createdAt,
        updatedAt,
      ];
}