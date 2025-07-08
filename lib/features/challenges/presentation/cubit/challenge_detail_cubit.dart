import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/usecases/start_challenge_usecase.dart';
import '../../domain/usecases/complete_challenge_usecase.dart';
import '../../domain/usecases/update_challenge_progress_usecase.dart';

// States CORREGIDOS - Agregar el estado que faltaba
abstract class ChallengeDetailState extends Equatable {
  const ChallengeDetailState();

  @override
  List<Object?> get props => [];
}

class ChallengeDetailInitial extends ChallengeDetailState {}

class ChallengeDetailLoaded extends ChallengeDetailState {
  final ChallengeEntity challenge;

  const ChallengeDetailLoaded({required this.challenge});

  @override
  List<Object> get props => [challenge];
}

class ChallengeDetailUpdating extends ChallengeDetailState {
  final ChallengeEntity challenge;

  const ChallengeDetailUpdating({required this.challenge});

  @override
  List<Object> get props => [challenge];
}

class ChallengeDetailError extends ChallengeDetailState {
  final String message;

  const ChallengeDetailError({required this.message});

  @override
  List<Object> get props => [message];
}

// 🔧 AGREGAR ESTADO QUE FALTABA
class ChallengeJoinSuccess extends ChallengeDetailState {
  final ChallengeEntity challenge;

  const ChallengeJoinSuccess({required this.challenge});

  @override
  List<Object> get props => [challenge];
}

class ChallengeCompleted extends ChallengeDetailState {
  final ChallengeEntity challenge;
  final int pointsEarned;

  const ChallengeCompleted({
    required this.challenge,
    required this.pointsEarned,
  });

  @override
  List<Object> get props => [challenge, pointsEarned];
}

// Cubit CORREGIDO
@injectable
class ChallengeDetailCubit extends Cubit<ChallengeDetailState> {
  final StartChallengeUseCase startChallengeUseCase;
  final CompleteChallengeUseCase completeChallengeUseCase;
  final UpdateChallengeProgressUseCase updateChallengeProgressUseCase;

  static const String _defaultUserId = 'user_123';

  ChallengeDetailCubit({
    required this.startChallengeUseCase,
    required this.completeChallengeUseCase,
    required this.updateChallengeProgressUseCase,
  }) : super(ChallengeDetailInitial());

  void loadChallenge(ChallengeEntity challenge) {
    emit(ChallengeDetailLoaded(challenge: challenge));
  }

  Future<void> joinChallenge(ChallengeEntity challenge) async {
    emit(ChallengeDetailUpdating(challenge: challenge));

    final result = await startChallengeUseCase(
      StartChallengeParams(
        challengeId: challenge.id,
        userId: _defaultUserId,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeDetailError(message: failure.message)),
      (_) {
        final updatedChallenge = ChallengeEntity(
          id: challenge.id,
          title: challenge.title,
          description: challenge.description,
          category: challenge.category,
          imageUrl: challenge.imageUrl,
          iconCode: challenge.iconCode,
          type: challenge.type,
          difficulty: challenge.difficulty,
          totalPoints: challenge.totalPoints,
          currentProgress: 0,
          targetProgress: challenge.targetProgress,
          status: ChallengeStatus.active,
          startDate: challenge.startDate,
          endDate: challenge.endDate,
          requirements: challenge.requirements,
          rewards: challenge.rewards,
          isParticipating: true,
          completedAt: challenge.completedAt,
          createdAt: challenge.createdAt,
        );
        // 🔧 EMITIR EL ESTADO CORRECTO
        emit(ChallengeJoinSuccess(challenge: updatedChallenge));
      },
    );
  }

  Future<void> updateProgress(ChallengeEntity challenge, int progress) async {
    emit(ChallengeDetailUpdating(challenge: challenge));

    final result = await updateChallengeProgressUseCase(
      UpdateChallengeProgressParams(
        challengeId: challenge.id,
        userId: _defaultUserId,
        progress: progress,
      ),
    );

    result.fold(
      (failure) => emit(ChallengeDetailError(message: failure.message)),
      (_) {
        final isCompleted = progress >= challenge.targetProgress;
        final updatedChallenge = ChallengeEntity(
          id: challenge.id,
          title: challenge.title,
          description: challenge.description,
          category: challenge.category,
          imageUrl: challenge.imageUrl,
          iconCode: challenge.iconCode,
          type: challenge.type,
          difficulty: challenge.difficulty,
          totalPoints: challenge.totalPoints,
          currentProgress: progress,
          targetProgress: challenge.targetProgress,
          status: isCompleted ? ChallengeStatus.completed : challenge.status,
          startDate: challenge.startDate,
          endDate: challenge.endDate,
          requirements: challenge.requirements,
          rewards: challenge.rewards,
          isParticipating: challenge.isParticipating,
          completedAt: isCompleted ? DateTime.now() : challenge.completedAt,
          createdAt: challenge.createdAt,
        );

        if (isCompleted) {
          emit(ChallengeCompleted(
            challenge: updatedChallenge,
            pointsEarned: challenge.totalPoints,
          ));
        } else {
          emit(ChallengeDetailLoaded(challenge: updatedChallenge));
        }
      },
    );
  }

  void incrementProgress(ChallengeEntity challenge) {
    final newProgress = (challenge.currentProgress + 1)
        .clamp(0, challenge.targetProgress);
    updateProgress(challenge, newProgress);
  }

  // 🔧 AGREGAR MÉTODO QUE FALTABA
  void resetToLoaded() {
    final currentState = state;
    if (currentState is ChallengeJoinSuccess) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    } else if (currentState is ChallengeCompleted) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    }
  }
}