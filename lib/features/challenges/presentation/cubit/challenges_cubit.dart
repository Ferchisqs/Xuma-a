import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/user_challenge_stats_entity.dart';
import '../../domain/usecases/get_challenges_usecase.dart';
import '../../domain/usecases/get_user_progress_usecase.dart';

// States CORREGIDOS - Agregar estado que faltaba
abstract class ChallengesState extends Equatable {
  const ChallengesState();

  @override
  List<Object?> get props => [];
}

class ChallengesInitial extends ChallengesState {}

class ChallengesLoading extends ChallengesState {}

class ChallengesLoaded extends ChallengesState {
  final List<ChallengeEntity> allChallenges;
  final List<ChallengeEntity> activeChallenges;
  final UserChallengeStatsEntity userStats;
  final ChallengeType? currentFilter;

  const ChallengesLoaded({
    required this.allChallenges,
    required this.activeChallenges,
    required this.userStats,
    this.currentFilter,
  });

  List<ChallengeEntity> get filteredChallenges {
    if (currentFilter == null) return allChallenges;
    return allChallenges.where((c) => c.type == currentFilter).toList();
  }

  List<ChallengeEntity> get dailyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.daily).toList();
  
  List<ChallengeEntity> get weeklyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.weekly).toList();
  
  List<ChallengeEntity> get monthlyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.monthly).toList();

  @override
  List<Object?> get props => [allChallenges, activeChallenges, userStats, currentFilter];
}

class ChallengesError extends ChallengesState {
  final String message;

  const ChallengesError({required this.message});

  @override
  List<Object> get props => [message];
}

// 🔧 AGREGAR ESTADO QUE FALTABA
class ChallengesRefreshing extends ChallengesLoaded {
  const ChallengesRefreshing({
    required List<ChallengeEntity> allChallenges,
    required List<ChallengeEntity> activeChallenges,
    required UserChallengeStatsEntity userStats,
    ChallengeType? currentFilter,
  }) : super(
    allChallenges: allChallenges,
    activeChallenges: activeChallenges,
    userStats: userStats,
    currentFilter: currentFilter,
  );
}

// Cubit CORREGIDO
@injectable
class ChallengesCubit extends Cubit<ChallengesState> {
  final GetChallengesUseCase getChallengesUseCase;
  final GetUserProgressUseCase getUserProgressUseCase;

  static const String _defaultUserId = 'user_123';

  ChallengesCubit({
    required this.getChallengesUseCase,
    required this.getUserProgressUseCase,
  }) : super(ChallengesInitial());

  Future<void> loadChallenges({ChallengeType? type}) async {
    emit(ChallengesLoading());

    try {
      // Cargar desafíos
      final challengesResult = await getChallengesUseCase(
        GetChallengesParams(type: type),
      );

      // Cargar estadísticas del usuario
      final statsResult = await getUserProgressUseCase(
        const GetUserProgressParams(userId: _defaultUserId),
      );

      // Combinar resultados
      final challenges = challengesResult.fold(
        (failure) => <ChallengeEntity>[],
        (challenges) => challenges,
      );

      final stats = statsResult.fold(
        (failure) => null,
        (stats) => stats,
      );

      // Filtrar desafíos activos
      final activeChallenges = challenges.where((c) => c.isParticipating && c.isActive).toList();

      if (stats != null) {
        emit(ChallengesLoaded(
          allChallenges: challenges,
          activeChallenges: activeChallenges,
          userStats: stats,
          currentFilter: type,
        ));
      } else {
        emit(const ChallengesError(message: 'Error cargando estadísticas'));
      }
    } catch (e) {
      emit(ChallengesError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  // 🔧 CORREGIR MÉTODO REFRESH
  Future<void> refreshChallenges() async {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      emit(ChallengesRefreshing(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        currentFilter: currentState.currentFilter,
      ));
      
      await loadChallenges(type: currentState.currentFilter);
    } else {
      await loadChallenges();
    }
  }

  void filterByType(ChallengeType? type) {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      emit(ChallengesLoaded(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        currentFilter: type,
      ));
    }
  }

  void clearFilter() {
    filterByType(null);
  }
}