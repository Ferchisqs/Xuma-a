// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanionApiModel _$CompanionApiModelFromJson(Map<String, dynamic> json) =>
    CompanionApiModel(
      id: json['id'] as String,
      name: json['name'] as String,
      speciesType: json['species_type'] as String,
      adoptedAt: json['adopted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      stage: json['stage'] as String?,
      level: (json['level'] as num?)?.toInt(),
      experience: (json['experience'] as num?)?.toInt(),
      featured: json['featured'] as bool?,
      selectedStage: json['selected_stage'] as String?,
      price: (json['price'] as num?)?.toInt(),
      available: json['available'] as bool?,
    );

Map<String, dynamic> _$CompanionApiModelToJson(CompanionApiModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'species_type': instance.speciesType,
      'adopted_at': instance.adoptedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'stage': instance.stage,
      'level': instance.level,
      'experience': instance.experience,
      'featured': instance.featured,
      'selected_stage': instance.selectedStage,
      'price': instance.price,
      'available': instance.available,
    };

AdoptPetRequest _$AdoptPetRequestFromJson(Map<String, dynamic> json) =>
    AdoptPetRequest(
      petId: json['pet_id'] as String,
      speciesType: json['species_type'] as String,
      stage: json['stage'] as String?,
    );

Map<String, dynamic> _$AdoptPetRequestToJson(AdoptPetRequest instance) =>
    <String, dynamic>{
      'pet_id': instance.petId,
      'species_type': instance.speciesType,
      'stage': instance.stage,
    };

EvolvePetRequest _$EvolvePetRequestFromJson(Map<String, dynamic> json) =>
    EvolvePetRequest(
      petId: json['pet_id'] as String,
      targetStage: json['target_stage'] as String?,
    );

Map<String, dynamic> _$EvolvePetRequestToJson(EvolvePetRequest instance) =>
    <String, dynamic>{
      'pet_id': instance.petId,
      'target_stage': instance.targetStage,
    };

FeaturePetRequest _$FeaturePetRequestFromJson(Map<String, dynamic> json) =>
    FeaturePetRequest(
      petId: json['pet_id'] as String,
    );

Map<String, dynamic> _$FeaturePetRequestToJson(FeaturePetRequest instance) =>
    <String, dynamic>{
      'pet_id': instance.petId,
    };

SelectStageRequest _$SelectStageRequestFromJson(Map<String, dynamic> json) =>
    SelectStageRequest(
      selectedStage: json['selected_stage'] as String,
    );

Map<String, dynamic> _$SelectStageRequestToJson(SelectStageRequest instance) =>
    <String, dynamic>{
      'selected_stage': instance.selectedStage,
    };
