import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/eco_tip_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/usecases/get_daily_tip_usecase.dart';
import '../../domain/usecases/get_user_stats_usecase.dart';

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final EcoTipEntity dailyTip;
  final UserStatsEntity userStats;
  final bool isFromCache;

  const HomeLoaded({
    required this.dailyTip,
    required this.userStats,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [dailyTip, userStats, isFromCache];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeRefreshing extends HomeLoaded {
  const HomeRefreshing({
    required EcoTipEntity dailyTip,
    required UserStatsEntity userStats,
    bool isFromCache = false,
  }) : super(dailyTip: dailyTip, userStats: userStats, isFromCache: isFromCache);
}

// Cubit
@injectable
class HomeCubit extends Cubit<HomeState> {
  final GetDailyTipUseCase _getDailyTipUseCase;
  final GetUserStatsUseCase _getUserStatsUseCase;

  HomeCubit({
    required GetDailyTipUseCase getDailyTipUseCase,
    required GetUserStatsUseCase getUserStatsUseCase,
  })  : _getDailyTipUseCase = getDailyTipUseCase,
        _getUserStatsUseCase = getUserStatsUseCase,
        super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    
    final tipResult = await _getDailyTipUseCase.call();
    final statsResult = await _getUserStatsUseCase.call();
    
    tipResult.fold(
      (failure) => emit(HomeError(failure.message)),
      (tip) {
        statsResult.fold(
          (failure) => emit(HomeError(failure.message)),
          (stats) => emit(HomeLoaded(dailyTip: tip, userStats: stats)),
        );
      },
    );
  }

  Future<void> refreshHomeData() async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(HomeRefreshing(
        dailyTip: currentState.dailyTip,
        userStats: currentState.userStats,
      ));
      
      await loadHomeData();
    } else {
      await loadHomeData();
    }
  }
}