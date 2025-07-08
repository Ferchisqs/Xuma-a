import 'package:equatable/equatable.dart';
import 'package:xuma_a/features/trivia/domain/entities/trivia_category_entity.dart';

enum QuestionType {
  multipleChoice,
  trueFalse
}

class TriviaQuestionEntity extends Equatable {
  final String id;
  final String categoryId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final QuestionType type;
  final TriviaDifficulty difficulty;
  final int points;
  final int timeLimit; // segundos
  final String? imageUrl;
  final DateTime createdAt;

  const TriviaQuestionEntity({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.type,
    required this.difficulty,
    required this.points,
    required this.timeLimit,
    this.imageUrl,
    required this.createdAt,
  });

  String get correctAnswer => options[correctAnswerIndex];

  bool isCorrectAnswer(int selectedIndex) {
    return selectedIndex == correctAnswerIndex;
  }

  @override
  List<Object?> get props => [
    id, categoryId, question, options, correctAnswerIndex,
    explanation, type, difficulty, points, timeLimit,
    imageUrl, createdAt,
  ];
}