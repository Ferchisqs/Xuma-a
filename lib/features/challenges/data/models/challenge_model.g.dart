// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChallengeModel _$ChallengeModelFromJson(Map<String, dynamic> json) =>
    ChallengeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      iconCode: (json['iconCode'] as num).toInt(),
      type: $enumDecode(_$ChallengeTypeEnumMap, json['type']),
      difficulty: $enumDecode(_$ChallengeDifficultyEnumMap, json['difficulty']),
      totalPoints: (json['totalPoints'] as num).toInt(),
      currentProgress: (json['currentProgress'] as num).toInt(),
      targetProgress: (json['targetProgress'] as num).toInt(),
      status: $enumDecode(_$ChallengeStatusEnumMap, json['status']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      requirements: (json['requirements'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rewards:
          (json['rewards'] as List<dynamic>).map((e) => e as String).toList(),
      isParticipating: json['isParticipating'] as bool,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChallengeModelToJson(ChallengeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'imageUrl': instance.imageUrl,
      'iconCode': instance.iconCode,
      'type': _$ChallengeTypeEnumMap[instance.type]!,
      'difficulty': _$ChallengeDifficultyEnumMap[instance.difficulty]!,
      'totalPoints': instance.totalPoints,
      'currentProgress': instance.currentProgress,
      'targetProgress': instance.targetProgress,
      'status': _$ChallengeStatusEnumMap[instance.status]!,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'requirements': instance.requirements,
      'rewards': instance.rewards,
      'isParticipating': instance.isParticipating,
      'completedAt': instance.completedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ChallengeTypeEnumMap = {
  ChallengeType.daily: 'daily',
  ChallengeType.weekly: 'weekly',
  ChallengeType.monthly: 'monthly',
  ChallengeType.special: 'special',
};

const _$ChallengeDifficultyEnumMap = {
  ChallengeDifficulty.easy: 'easy',
  ChallengeDifficulty.medium: 'medium',
  ChallengeDifficulty.hard: 'hard',
};

const _$ChallengeStatusEnumMap = {
  ChallengeStatus.notStarted: 'notStarted',
  ChallengeStatus.active: 'active',
  ChallengeStatus.completed: 'completed',
  ChallengeStatus.expired: 'expired',
};
