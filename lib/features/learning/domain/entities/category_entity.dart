// lib/features/learning/domain/entities/category_entity.dart
import 'package:equatable/equatable.dart';

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced
}

class CategoryEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int iconCode;
  final int lessonsCount;
  final int completedLessons;
  final String estimatedTime;
  final DifficultyLevel difficulty;
  final DateTime createdAt;

  const CategoryEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.iconCode,
    required this.lessonsCount,
    required this.completedLessons,
    required this.estimatedTime,
    required this.difficulty,
    required this.createdAt,
  });

  double get progressPercentage {
    if (lessonsCount == 0) return 0.0;
    return completedLessons / lessonsCount;
  }

  bool get isCompleted => completedLessons >= lessonsCount;

  @override
  List<Object> get props => [
        id,
        title,
        description,
        imageUrl,
        iconCode,
        lessonsCount,
        completedLessons,
        estimatedTime,
        difficulty,
        createdAt,
      ];
}