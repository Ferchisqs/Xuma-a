// lib/features/tips/domain/entities/tip_entity.dart
import 'package:equatable/equatable.dart';

class TipEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const TipEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        icon,
        isActive,
        createdAt,
        updatedAt,
        metadata,
      ];

  // Helper getters
  String get formattedContent => '$icon $content';
  
  bool get isEcoTip => category.toLowerCase().contains('eco') || 
                      category.toLowerCase().contains('ambiente');
  
  bool get isXicoTip => category.toLowerCase() == 'xico' || 
                       content.toLowerCase().contains('xico');
}