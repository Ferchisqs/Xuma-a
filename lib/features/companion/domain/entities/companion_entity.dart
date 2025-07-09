import 'package:equatable/equatable.dart';

enum CompanionType {
  dexter, // Chihuahua
  elly, // Panda
  paxolotl, // Ajolote
  yami // Jaguar
}

enum CompanionStage {
  baby, // Peque
  young, // Joven
  adult // Adulto
}

enum CompanionMood {
  happy,
  normal,
  hungry,
  sleepy,
  excited,
  sad
}

class CompanionEntity extends Equatable {
  final String id;
  final CompanionType type;
  final CompanionStage stage;
  final String name;
  final String description;
  final int level;
  final int experience;
  final int happiness;
  final int hunger;
  final int energy;
  final bool isOwned;
  final bool isSelected; // Compañero activo
  final DateTime? purchasedAt;
  final DateTime? lastFeedTime;
  final DateTime? lastLoveTime;
  final CompanionMood currentMood;
  final int purchasePrice;
  final int evolutionPrice;
  final List<String> unlockedAnimations;
  final DateTime createdAt;

  const CompanionEntity({
    required this.id,
    required this.type,
    required this.stage,
    required this.name,
    required this.description,
    required this.level,
    required this.experience,
    required this.happiness,
    required this.hunger,
    required this.energy,
    required this.isOwned,
    required this.isSelected,
    this.purchasedAt,
    this.lastFeedTime,
    this.lastLoveTime,
    required this.currentMood,
    required this.purchasePrice,
    required this.evolutionPrice,
    required this.unlockedAnimations,
    required this.createdAt,
  });

  // 🔧 GETTERS ACTUALIZADOS PARA NUEVA ESTRUCTURA
  String get imagePath => 'assets/images/companions/pets/${type.name}_${stage.name}.png';
  
  String get backgroundPath => 'assets/images/companions/backgrounds/${_getBackgroundName()}.png';
  
  String _getBackgroundName() {
    switch (type) {
      case CompanionType.dexter:
        return 'chihuahua_bg';
      case CompanionType.elly:
        return 'panda_bg';
      case CompanionType.paxolotl:
        return 'axolotl_bg';
      case CompanionType.yami:
        return 'jaguar_bg';
    }
  }
  
  String get displayName {
    switch (type) {
      case CompanionType.dexter:
        return 'Dexter';
      case CompanionType.elly:
        return 'Elly';
      case CompanionType.paxolotl:
        return 'Paxolotl';
      case CompanionType.yami:
        return 'Yami';
    }
  }

  String get typeDescription {
    switch (type) {
      case CompanionType.dexter:
        return 'Chihuahua';
      case CompanionType.elly:
        return 'Panda';
      case CompanionType.paxolotl:
        return 'Ajolote';
      case CompanionType.yami:
        return 'Jaguar';
    }
  }

  String get stageDisplayName {
    switch (stage) {
      case CompanionStage.baby:
        return 'Peque';
      case CompanionStage.young:
        return 'Joven';
      case CompanionStage.adult:
        return 'Adulto';
    }
  }

  bool get canEvolve {
    if (stage == CompanionStage.adult) return false;
    return experience >= experienceNeededForNextStage;
  }

  int get experienceNeededForNextStage {
    switch (stage) {
      case CompanionStage.baby:
        return 100;
      case CompanionStage.young:
        return 250;
      case CompanionStage.adult:
        return 0; // Ya está al máximo
    }
  }

  bool get needsFood => hunger < 50;
  bool get needsLove => happiness < 50;
  bool get isHappy => happiness >= 80;

  CompanionStage? get nextStage {
    switch (stage) {
      case CompanionStage.baby:
        return CompanionStage.young;
      case CompanionStage.young:
        return CompanionStage.adult;
      case CompanionStage.adult:
        return null;
    }
  }

  @override
  List<Object?> get props => [
    id, type, stage, name, description, level, experience,
    happiness, hunger, energy, isOwned, isSelected,
    purchasedAt, lastFeedTime, lastLoveTime, currentMood,
    purchasePrice, evolutionPrice, unlockedAnimations, createdAt,
  ];
}