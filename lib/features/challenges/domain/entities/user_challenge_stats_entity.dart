// lib/features/challenges/domain/entities/user_challenge_stats_entity.dart - CORREGIDO
import 'package:equatable/equatable.dart';

class UserChallengeStatsEntity extends Equatable {
  final int totalChallengesCompleted;
  final int currentActiveChallenges;
  final int totalPointsEarned;
  final int currentStreak;
  final int bestStreak;
  final String currentRank;
  final int rankPosition;
  final List<String> achievedBadges;
  final Map<String, int> categoryProgress;
  final DateTime? lastActivityDate; // 🔧 CAMBIADO A OPCIONAL

  const UserChallengeStatsEntity({
    required this.totalChallengesCompleted,
    required this.currentActiveChallenges,
    required this.totalPointsEarned,
    required this.currentStreak,
    required this.bestStreak,
    required this.currentRank,
    required this.rankPosition,
    required this.achievedBadges,
    required this.categoryProgress,
    this.lastActivityDate, // 🔧 OPCIONAL
  });

  @override
  List<Object?> get props => [
    totalChallengesCompleted, 
    currentActiveChallenges, 
    totalPointsEarned,
    currentStreak, 
    bestStreak, 
    currentRank, 
    rankPosition,
    achievedBadges, 
    categoryProgress, 
    lastActivityDate,
  ];

  // 🆕 MÉTODOS HELPER
  
  /// Verifica si el usuario tiene actividad reciente
  bool get hasRecentActivity {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate!);
    return difference.inDays <= 7; // Activo en los últimos 7 días
  }

  /// Calcula el nivel del usuario basado en puntos
  String get userLevel {
    if (totalPointsEarned >= 5000) return 'Maestro Eco';
    if (totalPointsEarned >= 2000) return 'Héroe Ambiental';
    if (totalPointsEarned >= 1000) return 'Guardián Verde';
    if (totalPointsEarned >= 500) return 'Protector Eco';
    return 'Eco Principiante';
  }

  /// Porcentaje de progreso hacia el siguiente nivel
  double get progressToNextLevel {
    final currentLevelThreshold = _getCurrentLevelThreshold();
    final nextLevelThreshold = _getNextLevelThreshold();
    
    if (nextLevelThreshold == currentLevelThreshold) return 1.0;
    
    final progress = (totalPointsEarned - currentLevelThreshold) / 
                    (nextLevelThreshold - currentLevelThreshold);
    
    return progress.clamp(0.0, 1.0);
  }

  /// Puntos necesarios para el siguiente nivel
  int get pointsToNextLevel {
    final nextThreshold = _getNextLevelThreshold();
    return (nextThreshold - totalPointsEarned).clamp(0, nextThreshold);
  }

  /// Categoría más activa del usuario
  String? get mostActiveCategory {
    if (categoryProgress.isEmpty) return null;
    
    var maxCategory = categoryProgress.entries.first;
    for (final entry in categoryProgress.entries) {
      if (entry.value > maxCategory.value) {
        maxCategory = entry;
      }
    }
    
    return maxCategory.key;
  }

  /// Total de challenges en progreso y completados
  int get totalChallengesStarted => totalChallengesCompleted + currentActiveChallenges;

  /// Ratio de completación
  double get completionRate {
    if (totalChallengesStarted == 0) return 0.0;
    return totalChallengesCompleted / totalChallengesStarted;
  }

  // ==================== MÉTODOS PRIVADOS ====================

  int _getCurrentLevelThreshold() {
    if (totalPointsEarned >= 5000) return 5000;
    if (totalPointsEarned >= 2000) return 2000;
    if (totalPointsEarned >= 1000) return 1000;
    if (totalPointsEarned >= 500) return 500;
    return 0;
  }

  int _getNextLevelThreshold() {
    if (totalPointsEarned >= 5000) return 5000; // Ya está en el nivel máximo
    if (totalPointsEarned >= 2000) return 5000;
    if (totalPointsEarned >= 1000) return 2000;
    if (totalPointsEarned >= 500) return 1000;
    return 500;
  }

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Crear estadísticas por defecto para nuevos usuarios
  factory UserChallengeStatsEntity.newUser() {
    return const UserChallengeStatsEntity(
      totalChallengesCompleted: 0,
      currentActiveChallenges: 0,
      totalPointsEarned: 0,
      currentStreak: 0,
      bestStreak: 0,
      currentRank: 'Eco Principiante',
      rankPosition: 1000,
      achievedBadges: [],
      categoryProgress: {},
      lastActivityDate: null,
    );
  }

  /// Crear estadísticas de ejemplo para testing
  factory UserChallengeStatsEntity.sample() {
    return UserChallengeStatsEntity(
      totalChallengesCompleted: 15,
      currentActiveChallenges: 3,
      totalPointsEarned: 1250,
      currentStreak: 7,
      bestStreak: 12,
      currentRank: 'Guardián Verde',
      rankPosition: 150,
      achievedBadges: const ['Reciclador Pro', 'Guardián del Agua', 'Eco Warrior'],
      categoryProgress: const {
        'reciclaje': 8,
        'energia': 5,
        'agua': 3,
        'compostaje': 2,
      },
      lastActivityDate: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  // ==================== COPY WITH ====================

  UserChallengeStatsEntity copyWith({
    int? totalChallengesCompleted,
    int? currentActiveChallenges,
    int? totalPointsEarned,
    int? currentStreak,
    int? bestStreak,
    String? currentRank,
    int? rankPosition,
    List<String>? achievedBadges,
    Map<String, int>? categoryProgress,
    DateTime? lastActivityDate,
  }) {
    return UserChallengeStatsEntity(
      totalChallengesCompleted: totalChallengesCompleted ?? this.totalChallengesCompleted,
      currentActiveChallenges: currentActiveChallenges ?? this.currentActiveChallenges,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      currentRank: currentRank ?? this.currentRank,
      rankPosition: rankPosition ?? this.rankPosition,
      achievedBadges: achievedBadges ?? this.achievedBadges,
      categoryProgress: categoryProgress ?? this.categoryProgress,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }
}