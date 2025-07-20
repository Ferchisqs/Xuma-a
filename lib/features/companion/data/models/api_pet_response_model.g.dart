// GENERATED CODE - DO NOT MODIFY BY HAND
// lib/features/companion/data/models/api_pet_response_model.g.dart

part of 'api_pet_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiPetResponseModel _$ApiPetResponseModelFromJson(Map<String, dynamic> json) =>
    ApiPetResponseModel(
      petId: json['pet_id'] as String,
      name: json['name'] as String,
      scientificName: json['scientific_name'] as String,
      description: json['description'] as String,
      speciesType: json['species_type'] as String,
      habitat: json['habitat'] as String,
      rarity: json['rarity'] as String,
      avatarUrl: json['avatar_url'] as String?,
      model3dUrl: json['model_3d_url'] as String?,
      quizPointsCost: (json['quiz_points_cost'] as num).toInt(),
      evolutionChain: (json['evolution_chain'] as List<dynamic>)
          .map((e) => EvolutionStageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      baseStats: BaseStatsModel.fromJson(json['base_stats'] as Map<String, dynamic>),
      unlockRequirements: UnlockRequirementsModel.fromJson(
          json['unlock_requirements'] as Map<String, dynamic>),
      isMexicanNative: json['is_mexican_native'] as bool,
    );

Map<String, dynamic> _$ApiPetResponseModelToJson(ApiPetResponseModel instance) =>
    <String, dynamic>{
      'pet_id': instance.petId,
      'name': instance.name,
      'scientific_name': instance.scientificName,
      'description': instance.description,
      'species_type': instance.speciesType,
      'habitat': instance.habitat,
      'rarity': instance.rarity,
      'avatar_url': instance.avatarUrl,
      'model_3d_url': instance.model3dUrl,
      'quiz_points_cost': instance.quizPointsCost,
      'evolution_chain': instance.evolutionChain,
      'base_stats': instance.baseStats,
      'unlock_requirements': instance.unlockRequirements,
      'is_mexican_native': instance.isMexicanNative,
    };

EvolutionStageModel _$EvolutionStageModelFromJson(Map<String, dynamic> json) =>
    EvolutionStageModel(
      name: json['name'] as String,
      stage: (json['stage'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$EvolutionStageModelToJson(EvolutionStageModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'stage': instance.stage,
      'image_url': instance.imageUrl,
    };

BaseStatsModel _$BaseStatsModelFromJson(Map<String, dynamic> json) =>
    BaseStatsModel(
      health: (json['health'] as num).toInt(),
      happiness: (json['happiness'] as num).toInt(),
      intelligence: (json['intelligence'] as num).toInt(),
      availableInStore: json['available_in_store'] as bool,
      environmentalPreference: json['environmental_preference'] as String,
    );

Map<String, dynamic> _$BaseStatsModelToJson(BaseStatsModel instance) =>
    <String, dynamic>{
      'health': instance.health,
      'happiness': instance.happiness,
      'intelligence': instance.intelligence,
      'available_in_store': instance.availableInStore,
      'environmental_preference': instance.environmentalPreference,
    };

UnlockRequirementsModel _$UnlockRequirementsModelFromJson(
        Map<String, dynamic> json) =>
    UnlockRequirementsModel(
      minQuizLevel: (json['min_quiz_level'] as num).toInt(),
      minChallengePoints: (json['min_challenge_points'] as num).toInt(),
    );

Map<String, dynamic> _$UnlockRequirementsModelToJson(
        UnlockRequirementsModel instance) =>
    <String, dynamic>{
      'min_quiz_level': instance.minQuizLevel,
      'min_challenge_points': instance.minChallengePoints,
    };