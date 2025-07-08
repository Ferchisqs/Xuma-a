import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/trivia_result_entity.dart';

part 'trivia_result_model.g.dart';

@JsonSerializable()
class TriviaResultModel extends TriviaResultEntity {
  @JsonKey(name: 'totalTime', fromJson: _durationFromMilliseconds, toJson: _durationToMilliseconds)
  final Duration totalTimeJson;

  const TriviaResultModel({
    required String id,
    required String userId,
    required String categoryId,
    required List<String> questionIds,
    required List<int> userAnswers,
    required List<bool> correctAnswers,
    required int totalQuestions,
    required int correctCount,
    required int totalPoints,
    required int earnedPoints,
    required Duration totalTime,
    required DateTime completedAt,
  }) : totalTimeJson = totalTime,
       super(
    id: id,
    userId: userId,
    categoryId: categoryId,
    questionIds: questionIds,
    userAnswers: userAnswers,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    correctCount: correctCount,
    totalPoints: totalPoints,
    earnedPoints: earnedPoints,
    totalTime: totalTime,
    completedAt: completedAt,
  );

  factory TriviaResultModel.fromJson(Map<String, dynamic> json) =>
      _$TriviaResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$TriviaResultModelToJson(this);

  // Helper methods for Duration serialization
  static Duration _durationFromMilliseconds(int milliseconds) =>
      Duration(milliseconds: milliseconds);

  static int _durationToMilliseconds(Duration duration) =>
      duration.inMilliseconds;

  factory TriviaResultModel.fromEntity(TriviaResultEntity entity) {
    return TriviaResultModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      questionIds: entity.questionIds,
      userAnswers: entity.userAnswers,
      correctAnswers: entity.correctAnswers,
      totalQuestions: entity.totalQuestions,
      correctCount: entity.correctCount,
      totalPoints: entity.totalPoints,
      earnedPoints: entity.earnedPoints,
      totalTime: entity.totalTime,
      completedAt: entity.completedAt,
    );
  }
}