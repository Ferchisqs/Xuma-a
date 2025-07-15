// lib/features/tips/data/models/tip_model.dart
import '../../domain/entities/tip_entity.dart';

class TipModel extends TipEntity {
  const TipModel({
    required String id,
    required String title,
    required String content,
    required String category,
    required String icon,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          title: title,
          content: content,
          category: category,
          icon: icon,
          isActive: isActive,
          createdAt: createdAt,
          updatedAt: updatedAt,
          metadata: metadata,
        );

  // Factory constructor para crear desde JSON de la API
  factory TipModel.fromJson(Map<String, dynamic> json) {
    return TipModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      icon: json['icon'] ?? '💡',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Factory para crear desde entidad
  factory TipModel.fromEntity(TipEntity entity) {
    return TipModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      category: entity.category,
      icon: entity.icon,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      metadata: entity.metadata,
    );
  }

  // Helper para obtener tip formateado para mostrar
  String get formattedContent {
    // Si el contenido ya tiene emoji al inicio, lo devolvemos tal como está
    if (content.trim().startsWith(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return content;
    }
    
    // Si no, agregamos el icono al inicio
    return '$icon $content';
  }

  // Helper para verificar si es un tip de Xico
  bool get isXicoTip => category.toLowerCase() == 'xico' || 
                       content.toLowerCase().contains('xico');

  @override
  String toString() {
    return 'TipModel(id: $id, title: $title, category: $category, isActive: $isActive)';
  }
}