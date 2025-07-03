import 'package:equatable/equatable.dart';

class EcoTipEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String iconName;
  final DateTime createdAt;
  final int difficulty; // 1-5
  final List<String> tags;

  const EcoTipEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.createdAt,
    required this.difficulty,
    required this.tags,
  });

  @override
  List<Object> get props => [
    id, title, description, category, iconName, 
    createdAt, difficulty, tags
  ];
}