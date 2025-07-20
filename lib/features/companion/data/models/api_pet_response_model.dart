// lib/features/companion/data/models/api_pet_response_model.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/companion_entity.dart';
import 'companion_model.dart';

part 'api_pet_response_model.g.dart';

/// Modelo para la respuesta de la API de mascotas disponibles
@JsonSerializable()
class ApiPetResponseModel {
  @JsonKey(name: 'pet_id')
  final String petId;
  final String name;
  @JsonKey(name: 'scientific_name')
  final String scientificName;
  final String description;
  @JsonKey(name: 'species_type')
  final String speciesType;
  final String habitat;
  final String rarity;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'model_3d_url')
  final String? model3dUrl;
  @JsonKey(name: 'quiz_points_cost')
  final int quizPointsCost;
  @JsonKey(name: 'evolution_chain')
  final List<EvolutionStageModel> evolutionChain;
  @JsonKey(name: 'base_stats')
  final BaseStatsModel baseStats;
  @JsonKey(name: 'unlock_requirements')
  final UnlockRequirementsModel unlockRequirements;
  @JsonKey(name: 'is_mexican_native')
  final bool isMexicanNative;

  const ApiPetResponseModel({
    required this.petId,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.speciesType,
    required this.habitat,
    required this.rarity,
    this.avatarUrl,
    this.model3dUrl,
    required this.quizPointsCost,
    required this.evolutionChain,
    required this.baseStats,
    required this.unlockRequirements,
    required this.isMexicanNative,
  });

  factory ApiPetResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ApiPetResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApiPetResponseModelToJson(this);

  /// 🔧 MAPEO PRINCIPAL: Convierte cada etapa de evolución a CompanionModel
  List<CompanionModel> toCompanionModels() {
    final companions = <CompanionModel>[];
    
    for (int i = 0; i < evolutionChain.length; i++) {
      final stage = evolutionChain[i];
      final companionStage = _mapStageNumberToCompanionStage(stage.stage);
      final companionType = _mapNameToCompanionType(name);
      
      debugPrint('🔄 [API_MAPPING] Mapeando: $name etapa ${stage.stage} -> ${companionType.name}_${companionStage.name}');
      
      final companion = CompanionModel(
        id: '${companionType.name}_${companionStage.name}',
        type: companionType,
        stage: companionStage,
        name: name,
        description: description,
        level: 1,
        experience: 0,
        happiness: baseStats.happiness,
        hunger: 100,
        energy: 100,
        isOwned: false, // Por defecto no poseído
        isSelected: false,
        purchasedAt: null,
        currentMood: CompanionMood.happy,
        purchasePrice: _calculatePriceForStage(stage.stage),
        evolutionPrice: _calculateEvolutionPrice(companionStage),
        unlockedAnimations: _getAnimationsForStage(companionStage),
        createdAt: DateTime.now(),
      );
      
      companions.add(companion);
    }
    
    return companions;
  }

  /// 🔧 MAPEAR NOMBRE A TIPO DE COMPANION
  CompanionType _mapNameToCompanionType(String name) {
    switch (name.toLowerCase()) {
      case 'dexter':
        return CompanionType.dexter;
      case 'paxoloth':
      case 'paxolotl':
        return CompanionType.paxolotl;
      case 'yami':
        return CompanionType.yami;
      case 'elly':
        return CompanionType.elly;
      default:
        debugPrint('⚠️ [API_MAPPING] Nombre desconocido: $name, usando Dexter por defecto');
        return CompanionType.dexter;
    }
  }

  /// 🔧 MAPEAR NÚMERO DE ETAPA A COMPANION STAGE
  CompanionStage _mapStageNumberToCompanionStage(int stageNumber) {
    switch (stageNumber) {
      case 1:
        return CompanionStage.baby;
      case 2:
        return CompanionStage.young;
      case 3:
      case 4: // Yami tiene 4 etapas, las últimas son adult
        return CompanionStage.adult;
      default:
        return CompanionStage.baby;
    }
  }

  /// 🔧 CALCULAR PRECIO POR ETAPA
  int _calculatePriceForStage(int stageNumber) {
    final basePrice = quizPointsCost;
    
    switch (stageNumber) {
      case 1: // Baby
        return basePrice;
      case 2: // Young
        return (basePrice * 1.5).round();
      case 3: // Adult
        return (basePrice * 2.0).round();
      case 4: // Adult premium (para Yami)
        return (basePrice * 2.5).round();
      default:
        return basePrice;
    }
  }

  /// 🔧 PRECIO DE EVOLUCIÓN
  int _calculateEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 50;
      case CompanionStage.young:
        return 100;
      case CompanionStage.adult:
        return 0; // Ya no puede evolucionar
    }
  }

  /// 🔧 ANIMACIONES POR ETAPA
  List<String> _getAnimationsForStage(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return ['idle', 'blink', 'happy'];
      case CompanionStage.young:
        return ['idle', 'blink', 'happy', 'eating'];
      case CompanionStage.adult:
        return ['idle', 'blink', 'happy', 'eating', 'loving', 'excited'];
    }
  }
}

/// Modelo para etapas de evolución
@JsonSerializable()
class EvolutionStageModel {
  final String name;
  final int stage;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  const EvolutionStageModel({
    required this.name,
    required this.stage,
    this.imageUrl,
  });

  factory EvolutionStageModel.fromJson(Map<String, dynamic> json) =>
      _$EvolutionStageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvolutionStageModelToJson(this);
}

/// Modelo para estadísticas base
@JsonSerializable()
class BaseStatsModel {
  final int health;
  final int happiness;
  final int intelligence;
  @JsonKey(name: 'available_in_store')
  final bool availableInStore;
  @JsonKey(name: 'environmental_preference')
  final String environmentalPreference;

  const BaseStatsModel({
    required this.health,
    required this.happiness,
    required this.intelligence,
    required this.availableInStore,
    required this.environmentalPreference,
  });

  factory BaseStatsModel.fromJson(Map<String, dynamic> json) =>
      _$BaseStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$BaseStatsModelToJson(this);
}

/// Modelo para requisitos de desbloqueo
@JsonSerializable()
class UnlockRequirementsModel {
  @JsonKey(name: 'min_quiz_level')
  final int minQuizLevel;
  @JsonKey(name: 'min_challenge_points')
  final int minChallengePoints;

  const UnlockRequirementsModel({
    required this.minQuizLevel,
    required this.minChallengePoints,
  });

  factory UnlockRequirementsModel.fromJson(Map<String, dynamic> json) =>
      _$UnlockRequirementsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnlockRequirementsModelToJson(this);
}