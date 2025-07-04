import 'package:equatable/equatable.dart';

enum LessonType {
  text,
  video,
  interactive,
  quiz
}

class LessonEntity extends Equatable {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final int duration; // minutos
  final int order;
  final bool isCompleted;
  final int points;
  final LessonType type;
  final DateTime createdAt;

  const LessonEntity({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    required this.duration,
    required this.order,
    required this.isCompleted,
    required this.points,
    required this.type,
    required this.createdAt,
  });

  String get formattedDuration {
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return '${hours}h ${minutes}min';
    }
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        title,
        description,
        content,
        imageUrl,
        videoUrl,
        duration,
        order,
        isCompleted,
        points,
        type,
        createdAt,
      ];
}