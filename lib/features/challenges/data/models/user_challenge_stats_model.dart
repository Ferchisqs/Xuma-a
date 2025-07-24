// lib/features/challenges/data/models/user_challenge_stats_model.dart - CORREGIDO
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_challenge_stats_entity.dart';

part 'user_challenge_stats_model.g.dart';

@JsonSerializable()
class UserChallengeStatsModel extends UserChallengeStatsEntity {
  const UserChallengeStatsModel({
    required int totalChallengesCompleted,
    required int currentActiveChallenges,
    required int totalPointsEarned,
    required int currentStreak,
    required int bestStreak,
    required String currentRank,
    required int rankPosition,
    required List<String> achievedBadges,
    required Map<String, int> categoryProgress,
    DateTime? lastActivityDate, // 🔧 OPCIONAL
  }) : super(
    totalChallengesCompleted: totalChallengesCompleted,
    currentActiveChallenges: currentActiveChallenges,
    totalPointsEarned: totalPointsEarned,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    currentRank: currentRank,
    rankPosition: rankPosition,
    achievedBadges: achievedBadges,
    categoryProgress: categoryProgress,
    lastActivityDate: lastActivityDate,
  );

  factory UserChallengeStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UserChallengeStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserChallengeStatsModelToJson(this);

  // 🆕 FACTORY PARA CREAR DESDE ENTIDAD
  factory UserChallengeStatsModel.fromEntity(UserChallengeStatsEntity entity) {
    return UserChallengeStatsModel(
      totalChallengesCompleted: entity.totalChallengesCompleted,
      currentActiveChallenges: entity.currentActiveChallenges,
      totalPointsEarned: entity.totalPointsEarned,
      currentStreak: entity.currentStreak,
      bestStreak: entity.bestStreak,
      currentRank: entity.currentRank,
      rankPosition: entity.rankPosition,
      achievedBadges: entity.achievedBadges,
      categoryProgress: entity.categoryProgress,
      lastActivityDate: entity.lastActivityDate,
    );
  }

  // 🆕 MÉTODO PARA MANEJAR DATOS DE API CON ESTRUCTURA VARIABLE
  factory UserChallengeStatsModel.fromApiResponse(Map<String, dynamic> apiData) {
    // Manejo robusto de datos de API que pueden tener diferentes estructuras
    return UserChallengeStatsModel(
      totalChallengesCompleted: _extractInt(apiData, ['totalChallengesCompleted', 'completed', 'totalCompleted']),
      currentActiveChallenges: _extractInt(apiData, ['currentActiveChallenges', 'active', 'currentActive']),
      totalPointsEarned: _extractInt(apiData, ['totalPointsEarned', 'points', 'totalPoints']),
      currentStreak: _extractInt(apiData, ['currentStreak', 'streak']),
      bestStreak: _extractInt(apiData, ['bestStreak', 'maxStreak', 'longestStreak']),
      currentRank: _extractString(apiData, ['currentRank', 'rank'], 'Eco Principiante'),
      rankPosition: _extractInt(apiData, ['rankPosition', 'position', 'ranking']),
      achievedBadges: _extractStringList(apiData, ['achievedBadges', 'badges']),
      categoryProgress: _extractIntMap(apiData, ['categoryProgress', 'progress']),
      lastActivityDate: _extractDateTime(apiData, ['lastActivityDate', 'lastActivity', 'lastActive']),
    );
  }

  // ==================== MÉTODOS HELPER PARA EXTRACCIÓN DE DATOS ====================

  static int _extractInt(Map<String, dynamic> data, List<String> keys, [int defaultValue = 0]) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is double) return value.round();
      }
    }
    return defaultValue;
  }

  static String _extractString(Map<String, dynamic> data, List<String> keys, [String defaultValue = '']) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return defaultValue;
  }

  static List<String> _extractStringList(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is List) {
          return value.map((e) => e.toString()).toList();
        }
      }
    }
    return [];
  }

  static Map<String, int> _extractIntMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is Map<String, dynamic>) {
          final result = <String, int>{};
          value.forEach((k, v) {
            if (v is int) {
              result[k] = v;
            } else if (v is String) {
              result[k] = int.tryParse(v) ?? 0;
            } else if (v is double) {
              result[k] = v.round();
            }
          });
          return result;
        }
      }
    }
    return {};
  }

  static DateTime? _extractDateTime(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is String && value.isNotEmpty) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            // Si no se puede parsear, intentar otros formatos comunes
            try {
              return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
            } catch (e) {
              continue;
            }
          }
        } else if (value is int) {
          try {
            return DateTime.fromMillisecondsSinceEpoch(value);
          } catch (e) {
            continue;
          }
        }
      }
    }
    return null;
  }
}