// lib/features/news/domain/entities/news_entity.dart
import 'package:equatable/equatable.dart';

class NewsEntity extends Equatable {
  final String articleId;
  final String title;
  final String? link;
  final List<String>? keywords;
  final List<String>? creator;
  final String? videoUrl;
  final String? description;
  final String? content;
  final DateTime? pubDate;
  final String? imageUrl;
  final String? sourceId;
  final int sourcePriority;
  final String? sourceName;
  final String? sourceUrl;
  final String? sourceIcon;
  final String language;
  final List<String> country;
  final List<String> category;
  final String? aiTag;
  final String? sentiment;
  final String? sentimentStats;
  final String? aiRegion;
  final String? aiOrg;
  final bool duplicate;

  const NewsEntity({
    required this.articleId,
    required this.title,
    this.link,
    this.keywords,
    this.creator,
    this.videoUrl,
    this.description,
    this.content,
    this.pubDate,
    this.imageUrl,
    this.sourceId,
    required this.sourcePriority,
    this.sourceName,
    this.sourceUrl,
    this.sourceIcon,
    required this.language,
    required this.country,
    required this.category,
    this.aiTag,
    this.sentiment,
    this.sentimentStats,
    this.aiRegion,
    this.aiOrg,
    required this.duplicate,
  });

  @override
  List<Object?> get props => [
    articleId, title, link, keywords, creator, videoUrl,
    description, content, pubDate, imageUrl, sourceId,
    sourcePriority, sourceName, sourceUrl, sourceIcon,
    language, country, category, aiTag, sentiment,
    sentimentStats, aiRegion, aiOrg, duplicate,
  ];

  // Helper getters
  String get displayTitle => title.isNotEmpty ? title : 'Sin título';
  String get displayDescription => description?.isNotEmpty == true ? description! : 'Sin descripción disponible';
  String get displaySource => sourceName?.isNotEmpty == true ? sourceName! : 'Fuente desconocida';
  String get formattedDate {
    if (pubDate == null) return 'Fecha desconocida';
    
    final now = DateTime.now();
    final difference = now.difference(pubDate!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Hace un momento';
    }
  }
  
  bool get hasImage => imageUrl?.isNotEmpty == true;
  bool get hasContent => content?.isNotEmpty == true;
  bool get hasLink => link?.isNotEmpty == true;
}