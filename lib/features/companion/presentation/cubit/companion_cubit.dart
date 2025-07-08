import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_user_companions_usecase.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';

// States
abstract class CompanionState extends Equatable {
  const CompanionState();

  @override
  List<Object?> get props => [];
}

class CompanionInitial extends CompanionState {}

class CompanionLoading extends CompanionState {}

class CompanionLoaded extends CompanionState {
  final List<CompanionEntity> allCompanions;
  final List<CompanionEntity> ownedCompanions;
  final CompanionEntity? activeCompanion;
  final CompanionStatsEntity userStats;

  const CompanionLoaded({
    required this.allCompanions,
    required this.ownedCompanions,
    this.activeCompanion,
    required this.userStats,
  });

  @override
  List<Object?> get props => [allCompanions, ownedCompanions, activeCompanion, userStats];
}

class CompanionError extends CompanionState {
  final String message;

  const CompanionError({required this.message});

  @override
  List<Object> get props => [message];
}

// Cubit
@injectable
class CompanionCubit extends Cubit<CompanionState> {
  final GetUserCompanionsUseCase getUserCompanionsUseCase;
  final GetCompanionShopUseCase getCompanionShopUseCase;

  static const String _defaultUserId = 'user_123';

  CompanionCubit({
    required this.getUserCompanionsUseCase,
    required this.getCompanionShopUseCase,
  }) : super(CompanionInitial());

  Future<void> loadCompanions() async {
    emit(CompanionLoading());

    final shopResult = await getCompanionShopUseCase(
      const GetCompanionShopParams(userId: _defaultUserId),
    );

    shopResult.fold(
      (failure) => emit(CompanionError(message: failure.message)),
      (shopData) {
        final ownedCompanions = shopData.availableCompanions
            .where((c) => c.isOwned)
            .toList();
        
        final activeCompanion = ownedCompanions
            .where((c) => c.isSelected)
            .isNotEmpty 
            ? ownedCompanions.firstWhere((c) => c.isSelected)
            : null;

        emit(CompanionLoaded(
          allCompanions: shopData.availableCompanions,
          ownedCompanions: ownedCompanions,
          activeCompanion: activeCompanion,
          userStats: shopData.userStats,
        ));
      },
    );
  }

  void refreshCompanions() => loadCompanions();
}