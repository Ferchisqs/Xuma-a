// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsModel _$NewsModelFromJson(Map<String, dynamic> json) => NewsModel(
      articleIdJson: json['article_id'] as String,
      titleJson: json['title'] as String,
      linkJson: json['link'] as String?,
      keywordsJson: (json['keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      creatorJson:
          (json['creator'] as List<dynamic>?)?.map((e) => e as String).toList(),
      videoUrlJson: json['video_url'] as String?,
      descriptionJson: json['description'] as String?,
      contentJson: json['content'] as String?,
      pubDateJson: json['pubDate'] as String?,
      imageUrlJson: json['image_url'] as String?,
      sourceIdJson: json['source_id'] as String?,
      sourcePriorityJson: (json['source_priority'] as num).toInt(),
      sourceNameJson: json['source_name'] as String?,
      sourceUrlJson: json['source_url'] as String?,
      sourceIconJson: json['source_icon'] as String?,
      languageJson: json['language'] as String,
      countryJson:
          (json['country'] as List<dynamic>).map((e) => e as String).toList(),
      categoryJson:
          (json['category'] as List<dynamic>).map((e) => e as String).toList(),
      aiTagJson: json['ai_tag'] as String?,
      sentimentJson: json['sentiment'] as String?,
      sentimentStatsJson: json['sentiment_stats'] as String?,
      aiRegionJson: json['ai_region'] as String?,
      aiOrgJson: json['ai_org'] as String?,
      duplicateJson: json['duplicate'] as bool,
    );

Map<String, dynamic> _$NewsModelToJson(NewsModel instance) => <String, dynamic>{
      'article_id': instance.articleIdJson,
      'title': instance.titleJson,
      'link': instance.linkJson,
      'keywords': instance.keywordsJson,
      'creator': instance.creatorJson,
      'video_url': instance.videoUrlJson,
      'description': instance.descriptionJson,
      'content': instance.contentJson,
      'pubDate': instance.pubDateJson,
      'image_url': instance.imageUrlJson,
      'source_id': instance.sourceIdJson,
      'source_priority': instance.sourcePriorityJson,
      'source_name': instance.sourceNameJson,
      'source_url': instance.sourceUrlJson,
      'source_icon': instance.sourceIconJson,
      'language': instance.languageJson,
      'country': instance.countryJson,
      'category': instance.categoryJson,
      'ai_tag': instance.aiTagJson,
      'sentiment': instance.sentimentJson,
      'sentiment_stats': instance.sentimentStatsJson,
      'ai_region': instance.aiRegionJson,
      'ai_org': instance.aiOrgJson,
      'duplicate': instance.duplicateJson,
    };

NewsResponseModel _$NewsResponseModelFromJson(Map<String, dynamic> json) =>
    NewsResponseModel(
      status: json['status'] as String,
      totalResults: (json['totalResults'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => NewsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPage: json['nextPage'] as String?,
    );

Map<String, dynamic> _$NewsResponseModelToJson(NewsResponseModel instance) =>
    <String, dynamic>{
      'status': instance.status,
      'totalResults': instance.totalResults,
      'results': instance.results,
      'nextPage': instance.nextPage,
    };
