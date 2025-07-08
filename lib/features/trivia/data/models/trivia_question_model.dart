import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trivia_question_entity.dart';
import '../../domain/entities/trivia_category_entity.dart'; // 🔧 AGREGAR ESTE IMPORT

part 'trivia_question_model.g.dart';

@JsonSerializable()
class TriviaQuestionModel extends TriviaQuestionEntity {
  const TriviaQuestionModel({
    required String id,
    required String categoryId,
    required String question,
    required List<String> options,
    required int correctAnswerIndex,
    required String explanation,
    required QuestionType type,
    required TriviaDifficulty difficulty, // 🔧 Ahora debería reconocer el enum
    required int points,
    required int timeLimit,
    String? imageUrl,
    required DateTime createdAt,
  }) : super(
    id: id,
    categoryId: categoryId,
    question: question,
    options: options,
    correctAnswerIndex: correctAnswerIndex,
    explanation: explanation,
    type: type,
    difficulty: difficulty,
    points: points,
    timeLimit: timeLimit,
    imageUrl: imageUrl,
    createdAt: createdAt,
  );

  factory TriviaQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$TriviaQuestionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TriviaQuestionModelToJson(this);

  factory TriviaQuestionModel.fromEntity(TriviaQuestionEntity entity) {
    return TriviaQuestionModel(
      id: entity.id,
      categoryId: entity.categoryId,
      question: entity.question,
      options: entity.options,
      correctAnswerIndex: entity.correctAnswerIndex,
      explanation: entity.explanation,
      type: entity.type,
      difficulty: entity.difficulty,
      points: entity.points,
      timeLimit: entity.timeLimit,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
    );
  }
}