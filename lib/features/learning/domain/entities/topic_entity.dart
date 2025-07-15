// lib/features/learning/domain/entities/topic_entity.dart
import 'package:equatable/equatable.dart';

class TopicEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TopicEntity({
    required this.id,
    required this.title,
    required this.description,
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
        imageUrl,
        category,
        isActive,
        createdAt,
        updatedAt,
      ];
}