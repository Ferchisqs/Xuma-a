// lib/features/news/data/models/news_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/news_entity.dart';

part 'news_model.g.dart';

@JsonSerializable()
class NewsModel extends NewsEntity {
  @JsonKey(name: 'article_id')
  final String articleIdJson;
  
  @JsonKey(name: 'title')
  final String titleJson;
  
  @JsonKey(name: 'link')
  final String? linkJson;
  
  @JsonKey(name: 'keywords')
  final List<String>? keywordsJson;
  
  @JsonKey(name: 'creator')
  final List<String>? creatorJson;
  
  @JsonKey(name: 'video_url')
  final String? videoUrlJson;
  
  @JsonKey(name: 'description')
  final String? descriptionJson;
  
  @JsonKey(name: 'content')
  final String? contentJson;
  
  @JsonKey(name: 'pubDate')
  final String? pubDateJson;
  
  @JsonKey(name: 'image_url')
  final String? imageUrlJson;
  
  @JsonKey(name: 'source_id')
  final String? sourceIdJson;
  
  @JsonKey(name: 'source_priority')
  final int sourcePriorityJson;
  
  @JsonKey(name: 'source_name')
  final String? sourceNameJson;
  
  @JsonKey(name: 'source_url')
  final String? sourceUrlJson;
  
  @JsonKey(name: 'source_icon')
  final String? sourceIconJson;
  
  @JsonKey(name: 'language')
  final String languageJson;
  
  @JsonKey(name: 'country')
  final List<String> countryJson;
  
  @JsonKey(name: 'category')
  final List<String> categoryJson;
  
  @JsonKey(name: 'ai_tag')
  final String? aiTagJson;
  
  @JsonKey(name: 'sentiment')
  final String? sentimentJson;
  
  @JsonKey(name: 'sentiment_stats')
  final String? sentimentStatsJson;
  
  @JsonKey(name: 'ai_region')
  final String? aiRegionJson;
  
  @JsonKey(name: 'ai_org')
  final String? aiOrgJson;
  
  @JsonKey(name: 'duplicate')
  final bool duplicateJson;

  const NewsModel({
    required this.articleIdJson,
    required this.titleJson,
    this.linkJson,
    this.keywordsJson,
    this.creatorJson,
    this.videoUrlJson,
    this.descriptionJson,
    this.contentJson,
    this.pubDateJson,
    this.imageUrlJson,
    this.sourceIdJson,
    required this.sourcePriorityJson,
    this.sourceNameJson,
    this.sourceUrlJson,
    this.sourceIconJson,
    required this.languageJson,
    required this.countryJson,
    required this.categoryJson,
    this.aiTagJson,
    this.sentimentJson,
    this.sentimentStatsJson,
    this.aiRegionJson,
    this.aiOrgJson,
    required this.duplicateJson,
  }) : super(
    articleId: articleIdJson,
    title: titleJson,
    link: linkJson,
    keywords: keywordsJson,
    creator: creatorJson,
    videoUrl: videoUrlJson,
    description: descriptionJson,
    content: contentJson,
    pubDate: null, // Se calculará en getter
    imageUrl: imageUrlJson,
    sourceId: sourceIdJson,
    sourcePriority: sourcePriorityJson,
    sourceName: sourceNameJson,
    sourceUrl: sourceUrlJson,
    sourceIcon: sourceIconJson,
    language: languageJson,
    country: countryJson,
    category: categoryJson,
    aiTag: aiTagJson,
    sentiment: sentimentJson,
    sentimentStats: sentimentStatsJson,
    aiRegion: aiRegionJson,
    aiOrg: aiOrgJson,
    duplicate: duplicateJson,
  );

  factory NewsModel.fromJson(Map<String, dynamic> json) => _$NewsModelFromJson(json);

  Map<String, dynamic> toJson() => _$NewsModelToJson(this);

  @override
  DateTime? get pubDate {
    if (pubDateJson == null) return null;
    try {
      return DateTime.parse(pubDateJson!);
    } catch (e) {
      print('Error parsing date: $pubDateJson');
      return null;
    }
  }
}

// Response wrapper para la API
@JsonSerializable()
class NewsResponseModel {
  final String status;
  final int totalResults;
  final List<NewsModel> results;
  final String? nextPage;
  
  const NewsResponseModel({
    required this.status,
    required this.totalResults,
    required this.results,
    this.nextPage,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) => _$NewsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$NewsResponseModelToJson(this);
}