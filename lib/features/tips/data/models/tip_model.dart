// lib/features/tips/data/models/tip_model.dart
import '../../domain/entities/tip_entity.dart';

class TipModel extends TipEntity {
  const TipModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required String icon,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          title: title,
          description: description,
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
      description: json['description'] ?? '',
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
      'content': description,
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
      description: entity.description,
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
    if (description.trim().startsWith(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return description;
    }
    
    // Si no, agregamos el icono al inicio
    return '$icon $description';
  }

  // Helper para verificar si es un tip de Xico
  bool get isXicoTip => category.toLowerCase() == 'xico' || 
                       description.toLowerCase().contains('xico');

  @override
  String toString() {
    return 'TipModel(id: $id, title: $title, category: $category, isActive: $isActive)';
  }
}