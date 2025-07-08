import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/challenge_entity.dart';

part 'challenge_model.g.dart';

@JsonSerializable()
class ChallengeModel extends ChallengeEntity {
  const ChallengeModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required String imageUrl,
    required int iconCode,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required int totalPoints,
    required int currentProgress,
    required int targetProgress,
    required ChallengeStatus status,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> requirements,
    required List<String> rewards,
    required bool isParticipating,
    DateTime? completedAt,
    required DateTime createdAt,
  }) : super(
    id: id,
    title: title,
    description: description,
    category: category,
    imageUrl: imageUrl,
    iconCode: iconCode,
    type: type,
    difficulty: difficulty,
    totalPoints: totalPoints,
    currentProgress: currentProgress,
    targetProgress: targetProgress,
    status: status,
    startDate: startDate,
    endDate: endDate,
    requirements: requirements,
    rewards: rewards,
    isParticipating: isParticipating,
    completedAt: completedAt,
    createdAt: createdAt,
  );

  factory ChallengeModel.fromJson(Map<String, dynamic> json) =>
      _$ChallengeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChallengeModelToJson(this);

  factory ChallengeModel.fromEntity(ChallengeEntity entity) {
    return ChallengeModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      imageUrl: entity.imageUrl,
      iconCode: entity.iconCode,
      type: entity.type,
      difficulty: entity.difficulty,
      totalPoints: entity.totalPoints,
      currentProgress: entity.currentProgress,
      targetProgress: entity.targetProgress,
      status: entity.status,
      startDate: entity.startDate,
      endDate: entity.endDate,
      requirements: entity.requirements,
      rewards: entity.rewards,
      isParticipating: entity.isParticipating,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
    );
  }
}