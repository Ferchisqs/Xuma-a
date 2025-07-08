import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/companion_entity.dart';

part 'companion_model.g.dart';

@JsonSerializable()
class CompanionModel extends CompanionEntity {
  const CompanionModel({
    required String id,
    required CompanionType type,
    required CompanionStage stage,
    required String name,
    required String description,
    required int level,
    required int experience,
    required int happiness,
    required int hunger,
    required int energy,
    required bool isOwned,
    required bool isSelected,
    DateTime? purchasedAt,
    DateTime? lastFeedTime,
    DateTime? lastLoveTime,
    required CompanionMood currentMood,
    required int purchasePrice,
    required int evolutionPrice,
    required List<String> unlockedAnimations,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: type,
          stage: stage,
          name: name,
          description: description,
          level: level,
          experience: experience,
          happiness: happiness,
          hunger: hunger,
          energy: energy,
          isOwned: isOwned,
          isSelected: isSelected,
          purchasedAt: purchasedAt,
          lastFeedTime: lastFeedTime,
          lastLoveTime: lastLoveTime,
          currentMood: currentMood,
          purchasePrice: purchasePrice,
          evolutionPrice: evolutionPrice,
          unlockedAnimations: unlockedAnimations,
          createdAt: createdAt,
        );

  factory CompanionModel.fromJson(Map<String, dynamic> json) =>
      _$CompanionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionModelToJson(this);

  factory CompanionModel.fromEntity(CompanionEntity entity) {
    return CompanionModel(
      id: entity.id,
      type: entity.type,
      stage: entity.stage,
      name: entity.name,
      description: entity.description,
      level: entity.level,
      experience: entity.experience,
      happiness: entity.happiness,
      hunger: entity.hunger,
      energy: entity.energy,
      isOwned: entity.isOwned,
      isSelected: entity.isSelected,
      purchasedAt: entity.purchasedAt,
      lastFeedTime: entity.lastFeedTime,
      lastLoveTime: entity.lastLoveTime,
      currentMood: entity.currentMood,
      purchasePrice: entity.purchasePrice,
      evolutionPrice: entity.evolutionPrice,
      unlockedAnimations: entity.unlockedAnimations,
      createdAt: entity.createdAt,
    );
  }
}