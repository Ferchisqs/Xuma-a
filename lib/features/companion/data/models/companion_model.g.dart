// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanionModel _$CompanionModelFromJson(Map<String, dynamic> json) =>
    CompanionModel(
      id: json['id'] as String,
      type: $enumDecode(_$CompanionTypeEnumMap, json['type']),
      stage: $enumDecode(_$CompanionStageEnumMap, json['stage']),
      name: json['name'] as String,
      description: json['description'] as String,
      level: (json['level'] as num).toInt(),
      experience: (json['experience'] as num).toInt(),
      happiness: (json['happiness'] as num).toInt(),
      hunger: (json['hunger'] as num).toInt(),
      energy: (json['energy'] as num).toInt(),
      isOwned: json['isOwned'] as bool,
      isSelected: json['isSelected'] as bool,
      purchasedAt: json['purchasedAt'] == null
          ? null
          : DateTime.parse(json['purchasedAt'] as String),
      lastFeedTime: json['lastFeedTime'] == null
          ? null
          : DateTime.parse(json['lastFeedTime'] as String),
      lastLoveTime: json['lastLoveTime'] == null
          ? null
          : DateTime.parse(json['lastLoveTime'] as String),
      currentMood: $enumDecode(_$CompanionMoodEnumMap, json['currentMood']),
      purchasePrice: (json['purchasePrice'] as num).toInt(),
      evolutionPrice: (json['evolutionPrice'] as num).toInt(),
      unlockedAnimations: (json['unlockedAnimations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CompanionModelToJson(CompanionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$CompanionTypeEnumMap[instance.type]!,
      'stage': _$CompanionStageEnumMap[instance.stage]!,
      'name': instance.name,
      'description': instance.description,
      'level': instance.level,
      'experience': instance.experience,
      'happiness': instance.happiness,
      'hunger': instance.hunger,
      'energy': instance.energy,
      'isOwned': instance.isOwned,
      'isSelected': instance.isSelected,
      'purchasedAt': instance.purchasedAt?.toIso8601String(),
      'lastFeedTime': instance.lastFeedTime?.toIso8601String(),
      'lastLoveTime': instance.lastLoveTime?.toIso8601String(),
      'currentMood': _$CompanionMoodEnumMap[instance.currentMood]!,
      'purchasePrice': instance.purchasePrice,
      'evolutionPrice': instance.evolutionPrice,
      'unlockedAnimations': instance.unlockedAnimations,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$CompanionTypeEnumMap = {
  CompanionType.dexter: 'dexter',
  CompanionType.elly: 'elly',
  CompanionType.paxolotl: 'paxolotl',
  CompanionType.yami: 'yami',
};

const _$CompanionStageEnumMap = {
  CompanionStage.baby: 'baby',
  CompanionStage.young: 'young',
  CompanionStage.adult: 'adult',
};

const _$CompanionMoodEnumMap = {
  CompanionMood.happy: 'happy',
  CompanionMood.normal: 'normal',
  CompanionMood.hungry: 'hungry',
  CompanionMood.sleepy: 'sleepy',
  CompanionMood.excited: 'excited',
  CompanionMood.sad: 'sad',
};
