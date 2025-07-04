import 'package:equatable/equatable.dart';

class LessonProgressEntity extends Equatable {
  final String userId;
  final String lessonId;
  final String categoryId;
  final double progress; // 0.0 - 1.0
  final bool isCompleted;
  final DateTime? completedAt;
  final int timeSpent; // segundos
  final DateTime updatedAt;

  const LessonProgressEntity({
    required this.userId,
    required this.lessonId,
    required this.categoryId,
    required this.progress,
    required this.isCompleted,
    this.completedAt,
    required this.timeSpent,
    required this.updatedAt,
  });

  int get progressPercentage => (progress * 100).round();

  String get formattedTimeSpent {
    if (timeSpent < 60) {
      return '${timeSpent}s';
    } else if (timeSpent < 3600) {
      final minutes = timeSpent ~/ 60;
      final seconds = timeSpent % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = timeSpent ~/ 3600;
      final minutes = (timeSpent % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  @override
  List<Object?> get props => [
        userId,
        lessonId,
        categoryId,
        progress,
        isCompleted,
        completedAt,
        timeSpent,
        updatedAt,
      ];
}