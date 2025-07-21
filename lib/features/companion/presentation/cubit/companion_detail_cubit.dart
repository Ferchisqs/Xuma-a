import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/usecases/feed_companion_usecase.dart';
import '../../domain/usecases/love_companion_usecase.dart';
import '../../domain/usecases/evolve_companion_usecase.dart';

// States
abstract class CompanionDetailState extends Equatable {
  const CompanionDetailState();
  
  @override
  List<Object?> get props => [];
}

class CompanionDetailInitial extends CompanionDetailState {}

class CompanionDetailLoaded extends CompanionDetailState {
  final CompanionEntity companion;
  
  const CompanionDetailLoaded({required this.companion});
  
  @override
  List<Object> get props => [companion];
}

class CompanionDetailUpdating extends CompanionDetailState {
  final CompanionEntity companion;
  final String action; // 'feeding', 'loving', 'evolving'
  
  const CompanionDetailUpdating({
    required this.companion,
    required this.action,
  });
  
  @override
  List<Object> get props => [companion, action];
}

class CompanionDetailSuccess extends CompanionDetailState {
  final CompanionEntity companion;
  final String message;
  
  const CompanionDetailSuccess({
    required this.companion,
    required this.message,
  });
  
  @override
  List<Object> get props => [companion, message];
}

class CompanionDetailError extends CompanionDetailState {
  final String message;
  final CompanionEntity? companion;
  
  const CompanionDetailError({
    required this.message,
    this.companion,
  });
  
  @override
  List<Object?> get props => [message, companion];
}

// Cubit
@injectable
class CompanionDetailCubit extends Cubit<CompanionDetailState> {
  final FeedCompanionUseCase feedCompanionUseCase;
  final LoveCompanionUseCase loveCompanionUseCase;
  final EvolveCompanionUseCase evolveCompanionUseCase;
  final TokenManager tokenManager;
  
  static const String _defaultUserId = 'user_123';
  
  CompanionDetailCubit({
    required this.feedCompanionUseCase,
    required this.loveCompanionUseCase,
    required this.evolveCompanionUseCase,
    required this.tokenManager,
  }) : super(CompanionDetailInitial());
  
  void loadCompanion(CompanionEntity companion) {
    emit(CompanionDetailLoaded(companion: companion));
  }
  
  Future<void> feedCompanion(CompanionEntity companion) async {
    if (state is CompanionDetailUpdating) return;
    
    emit(CompanionDetailUpdating(companion: companion, action: 'feeding'));
    
    final result = await feedCompanionUseCase(
      FeedCompanionParams(
        userId: _defaultUserId,
        companionId: companion.id,
      ),
    );
    
    result.fold(
      (failure) => emit(CompanionDetailError(
        message: failure.message,
        companion: companion,
      )),
      (updatedCompanion) => emit(CompanionDetailSuccess(
        companion: updatedCompanion,
        message: '¡${updatedCompanion.displayName} ha sido alimentado!',
      )),
    );
    
    // Volver al estado loaded después de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (state is CompanionDetailSuccess) {
      final currentState = state as CompanionDetailSuccess;
      emit(CompanionDetailLoaded(companion: currentState.companion));
    }
  }
  
  Future<void> loveCompanion(CompanionEntity companion) async {
    if (state is CompanionDetailUpdating) return;
    
    emit(CompanionDetailUpdating(companion: companion, action: 'loving'));
    
    final result = await loveCompanionUseCase(
      LoveCompanionParams(
        userId: _defaultUserId,
        companionId: companion.id,
      ),
    );
    
    result.fold(
      (failure) => emit(CompanionDetailError(
        message: failure.message,
        companion: companion,
      )),
      (updatedCompanion) => emit(CompanionDetailSuccess(
        companion: updatedCompanion,
        message: '¡${updatedCompanion.displayName} se siente amado!',
      )),
    );
    
    // Volver al estado loaded después de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    if (state is CompanionDetailSuccess) {
      final currentState = state as CompanionDetailSuccess;
      emit(CompanionDetailLoaded(companion: currentState.companion));
    }
  }
  
  Future<void> evolveCompanion(CompanionEntity companion) async {
    if (state is CompanionDetailUpdating) return;
    
    if (!companion.canEvolve) {
      emit(CompanionDetailError(
        message: 'Tu compañero necesita más experiencia para evolucionar',
        companion: companion,
      ));
      return;
    }
    
    emit(CompanionDetailUpdating(companion: companion, action: 'evolving'));
    
    final result = await evolveCompanionUseCase(
      EvolveCompanionParams(
        userId: _defaultUserId,
        companionId: companion.id,
      ),
    );
    
    result.fold(
      (failure) => emit(CompanionDetailError(
        message: failure.message,
        companion: companion,
      )),
      (evolvedCompanion) => emit(CompanionDetailSuccess(
        companion: evolvedCompanion,
        message: '¡${evolvedCompanion.displayName} ha evolucionado a ${evolvedCompanion.stageDisplayName}!',
      )),
    );
    
    // Volver al estado loaded después de 3 segundos para evolución
    await Future.delayed(const Duration(seconds: 3));
    if (state is CompanionDetailSuccess) {
      final currentState = state as CompanionDetailSuccess;
      emit(CompanionDetailLoaded(companion: currentState.companion));
    }
  }
}