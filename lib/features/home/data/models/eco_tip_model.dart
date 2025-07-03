import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/eco_tip_entity.dart';

part 'eco_tip_model.g.dart';

@JsonSerializable()
class EcoTipModel extends EcoTipEntity {
  @JsonKey(name: 'created_at')
  final String createdAtString;
  
  @JsonKey(name: 'icon_name')
  final String iconNameJson;

  EcoTipModel({
    required String id,
    required String title,
    required String description,
    required String category,
    required this.iconNameJson,
    required this.createdAtString,
    required int difficulty,
    required List<String> tags,
  }) : super(
    id: id,
    title: title,
    description: description,
    category: category,
    iconName: iconNameJson,
    createdAt: DateTime(1970), // valor por defecto
    difficulty: difficulty,
    tags: tags,
  );

  factory EcoTipModel.fromJson(Map<String, dynamic> json) =>
      _$EcoTipModelFromJson(json);

  Map<String, dynamic> toJson() => _$EcoTipModelToJson(this);

  DateTime get parsedCreatedAt {
    try {
      return DateTime.parse(createdAtString);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  DateTime get createdAt => parsedCreatedAt;

  @override
  String get iconName => iconNameJson;
}
