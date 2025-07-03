// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eco_tip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EcoTipModel _$EcoTipModelFromJson(Map<String, dynamic> json) => EcoTipModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      iconNameJson: json['icon_name'] as String,
      createdAtString: json['created_at'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$EcoTipModelToJson(EcoTipModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'difficulty': instance.difficulty,
      'tags': instance.tags,
      'created_at': instance.createdAtString,
      'icon_name': instance.iconNameJson,
    };
