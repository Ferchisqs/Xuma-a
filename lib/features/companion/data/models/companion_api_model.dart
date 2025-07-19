// lib/features/companion/data/models/companion_api_model.dart
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/companion_entity.dart';

part 'companion_api_model.g.dart';

@JsonSerializable()
class CompanionApiModel {
  final String id;
  final String name;
  @JsonKey(name: 'species_type')
  final String speciesType;
  @JsonKey(name: 'adopted_at')
  final String? adoptedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // 🆕 Campos adicionales que pueden venir de la API
  final String? stage;
  final int? level;
  final int? experience;
  final bool? featured;
  @JsonKey(name: 'selected_stage')
  final String? selectedStage;
  final int? price;
  final bool? available;

  const CompanionApiModel({
    required this.id,
    required this.name,
    required this.speciesType,
    this.adoptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.stage,
    this.level,
    this.experience,
    this.featured,
    this.selectedStage,
    this.price,
    this.available,
  });

  factory CompanionApiModel.fromJson(Map<String, dynamic> json) =>
      _$CompanionApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompanionApiModelToJson(this);

  // 🔧 MAPEO DE API A ENTIDAD LOCAL
  CompanionEntity toEntity() {
    final companionType = _mapSpeciesTypeToCompanionType(speciesType);
    final companionStage = _mapStageToCompanionStage(stage ?? selectedStage ?? 'baby');
    
    return CompanionEntity(
      id: _generateLocalId(companionType, companionStage),
      type: companionType,
      stage: companionStage,
      name: _mapSpeciesTypeToDisplayName(speciesType),
      description: _generateDescription(companionType, companionStage),
      level: level ?? 1,
      experience: experience ?? 0,
      happiness: 100, // Valores por defecto para campos no en API
      hunger: 100,
      energy: 100,
      isOwned: adoptedAt != null,
      isSelected: featured ?? false,
      purchasedAt: adoptedAt != null ? DateTime.parse(adoptedAt!) : null,
      currentMood: CompanionMood.happy,
      purchasePrice: price ?? _getDefaultPrice(companionType, companionStage),
      evolutionPrice: _getEvolutionPrice(companionStage),
      unlockedAnimations: _getDefaultAnimations(),
      createdAt: DateTime.parse(createdAt),
    );
  }

  // 🔧 MAPEO DE ESPECIES DE API A TIPOS LOCALES
  CompanionType _mapSpeciesTypeToCompanionType(String speciesType) {
    switch (speciesType.toLowerCase()) {
      case 'dog':
      case 'chihuahua':
        return CompanionType.dexter;
      case 'panda':
        return CompanionType.elly;
      case 'axolotl':
      case 'ajolote':
        return CompanionType.paxolotl;
      case 'jaguar':
        return CompanionType.yami;
      default:
        debugPrint('⚠️ Especie desconocida: $speciesType, usando Dexter por defecto');
        return CompanionType.dexter;
    }
  }

  // 🔧 MAPEO DE ETAPAS
  CompanionStage _mapStageToCompanionStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'baby':
      case 'peque':
      case 'pequeño':
        return CompanionStage.baby;
      case 'young':
      case 'joven':
        return CompanionStage.young;
      case 'adult':
      case 'adulto':
        return CompanionStage.adult;
      default:
        debugPrint('⚠️ Etapa desconocida: $stage, usando baby por defecto');
        return CompanionStage.baby;
    }
  }

  // 🔧 GENERAR ID LOCAL CONSISTENTE
  String _generateLocalId(CompanionType type, CompanionStage stage) {
    return '${type.name}_${stage.name}';
  }

  // 🔧 OBTENER NOMBRE DISPLAY
  String _mapSpeciesTypeToDisplayName(String speciesType) {
    switch (speciesType.toLowerCase()) {
      case 'dog':
      case 'chihuahua':
        return 'Dexter';
      case 'panda':
        return 'Elly';
      case 'axolotl':
      case 'ajolote':
        return 'Paxolotl';
      case 'jaguar':
        return 'Yami';
      default:
        return name; // Usar el nombre de la API si no hay mapeo
    }
  }

  // 🔧 GENERAR DESCRIPCIÓN
  String _generateDescription(CompanionType type, CompanionStage stage) {
    final baseName = _mapSpeciesTypeToDisplayName(speciesType);
    
    switch (stage) {
      case CompanionStage.baby:
        return 'Un adorable $baseName bebé lleno de energía';
      case CompanionStage.young:
        return '$baseName ha crecido y es más juguetón';
      case CompanionStage.adult:
        return '$baseName adulto, el compañero perfecto';
    }
  }

  // 🔧 PRECIOS POR DEFECTO
  int _getDefaultPrice(CompanionType type, CompanionStage stage) {
    int basePrice = 0;
    
    // Precio base por tipo
    switch (type) {
      case CompanionType.dexter:
        basePrice = 0; // Gratis como mascota inicial
        break;
      case CompanionType.elly:
        basePrice = 50;
        break;
      case CompanionType.paxolotl:
        basePrice = 100;
        break;
      case CompanionType.yami:
        basePrice = 200;
        break;
    }
    
    // Multiplicador por etapa
    switch (stage) {
      case CompanionStage.baby:
        return basePrice;
      case CompanionStage.young:
        return basePrice + 50;
      case CompanionStage.adult:
        return basePrice + 100;
    }
  }

  // 🔧 PRECIO DE EVOLUCIÓN
  int _getEvolutionPrice(CompanionStage stage) {
    switch (stage) {
      case CompanionStage.baby:
        return 50;
      case CompanionStage.young:
        return 100;
      case CompanionStage.adult:
        return 0; // Ya no puede evolucionar
    }
  }

  // 🔧 ANIMACIONES POR DEFECTO
  List<String> _getDefaultAnimations() {
    return ['idle', 'blink', 'happy', 'eating', 'loving'];
  }
}

// 🔧 MODELO PARA REQUESTS DE ADOPCIÓN
@JsonSerializable()
class AdoptPetRequest {
  @JsonKey(name: 'pet_id')
  final String petId;
  @JsonKey(name: 'species_type')
  final String speciesType;
  final String? stage;

  const AdoptPetRequest({
    required this.petId,
    required this.speciesType,
    this.stage,
  });

  factory AdoptPetRequest.fromJson(Map<String, dynamic> json) =>
      _$AdoptPetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdoptPetRequestToJson(this);
}

// 🔧 MODELO PARA REQUESTS DE EVOLUCIÓN
@JsonSerializable()
class EvolvePetRequest {
  @JsonKey(name: 'pet_id')
  final String petId;
  @JsonKey(name: 'target_stage')
  final String? targetStage;

  const EvolvePetRequest({
    required this.petId,
    this.targetStage,
  });

  factory EvolvePetRequest.fromJson(Map<String, dynamic> json) =>
      _$EvolvePetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EvolvePetRequestToJson(this);
}

// 🔧 MODELO PARA DESTACAR MASCOTA
@JsonSerializable()
class FeaturePetRequest {
  @JsonKey(name: 'pet_id')
  final String petId;

  const FeaturePetRequest({
    required this.petId,
  });

  factory FeaturePetRequest.fromJson(Map<String, dynamic> json) =>
      _$FeaturePetRequestFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturePetRequestToJson(this);
}

// 🔧 MODELO PARA SELECCIONAR ETAPA VISUALIZADA
@JsonSerializable()
class SelectStageRequest {
  @JsonKey(name: 'selected_stage')
  final String selectedStage;

  const SelectStageRequest({
    required this.selectedStage,
  });

  factory SelectStageRequest.fromJson(Map<String, dynamic> json) =>
      _$SelectStageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SelectStageRequestToJson(this);
}