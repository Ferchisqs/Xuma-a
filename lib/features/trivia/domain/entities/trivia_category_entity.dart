import 'package:equatable/equatable.dart';

enum TriviaDifficulty {
  easy,
  medium,
  hard
}

class TriviaCategoryEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int iconCode;
  final int questionsCount;
  final int completedTrivias;
  final TriviaDifficulty difficulty;
  final int pointsPerQuestion;
  final int timePerQuestion; // segundos
  final DateTime createdAt;

  const TriviaCategoryEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.iconCode,
    required this.questionsCount,
    required this.completedTrivias,
    required this.difficulty,
    required this.pointsPerQuestion,
    required this.timePerQuestion,
    required this.createdAt,
  });

  double get progressPercentage {
    if (questionsCount == 0) return 0.0;
    return completedTrivias / questionsCount;
  }

  bool get isCompleted => completedTrivias >= questionsCount;

  @override
  List<Object> get props => [
    id, title, description, imageUrl, iconCode,
    questionsCount, completedTrivias, difficulty,
    pointsPerQuestion, timePerQuestion, createdAt,
  ];
}