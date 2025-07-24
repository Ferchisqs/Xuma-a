// lib/features/challenges/presentation/cubit/challenge_detail_cubit.dart - CORREGIDO CON USER ID REAL
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/usecases/start_challenge_usecase.dart';
import '../../domain/usecases/complete_challenge_usecase.dart';
import '../../domain/usecases/update_challenge_progress_usecase.dart';
import '../../domain/usecases/submit_evidence_usecase.dart';
import '../../../auth/domain/services/auth_service.dart'; // 🆕 IMPORT AUTH SERVICE

// ==================== STATES ACTUALIZADOS ====================

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
  final String action;

  const ChallengeDetailUpdating({
    required this.challenge,
    this.action = 'Actualizando...',
  });

  @override
  List<Object> get props => [challenge, action];
}

class ChallengeDetailError extends ChallengeDetailState {
  final String message;

  const ChallengeDetailError({required this.message});

  @override
  List<Object> get props => [message];
}

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

// 🆕 NUEVOS ESTADOS PARA EVIDENCIA
class ChallengeEvidenceRequired extends ChallengeDetailState {
  final ChallengeEntity challenge;
  final String userChallengeId;

  const ChallengeEvidenceRequired({
    required this.challenge,
    required this.userChallengeId,
  });

  @override
  List<Object> get props => [challenge, userChallengeId];
}

class ChallengeEvidenceSubmitted extends ChallengeDetailState {
  final ChallengeEntity challenge;
  final String message;

  const ChallengeEvidenceSubmitted({
    required this.challenge,
    this.message = 'Evidencia enviada. Esperando validación.',
  });

  @override
  List<Object> get props => [challenge, message];
}

class ChallengePendingValidation extends ChallengeDetailState {
  final ChallengeEntity challenge;
  final DateTime submissionDate;

  const ChallengePendingValidation({
    required this.challenge,
    required this.submissionDate,
  });

  @override
  List<Object> get props => [challenge, submissionDate];
}

// 🆕 NUEVO ESTADO PARA FALTA DE AUTENTICACIÓN
class ChallengeNotAuthenticated extends ChallengeDetailState {
  final String message;

  const ChallengeNotAuthenticated({
    this.message = 'Debes iniciar sesión para participar en desafíos',
  });

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ACTUALIZADO ====================

@injectable
class ChallengeDetailCubit extends Cubit<ChallengeDetailState> {
  final StartChallengeUseCase startChallengeUseCase;
  final CompleteChallengeUseCase completeChallengeUseCase;
  final UpdateChallengeProgressUseCase updateChallengeProgressUseCase;
  final SubmitEvidenceUseCase submitEvidenceUseCase;
  final AuthService authService; // 🆕 AUTH SERVICE

  ChallengeDetailCubit({
    required this.startChallengeUseCase,
    required this.completeChallengeUseCase,
    required this.updateChallengeProgressUseCase,
    required this.submitEvidenceUseCase,
    required this.authService, // 🆕 INYECCIÓN DE AUTH SERVICE
  }) : super(ChallengeDetailInitial()) {
    print('✅ [CHALLENGE DETAIL CUBIT] Constructor - Now with real user authentication');
  }

  void loadChallenge(ChallengeEntity challenge) {
    print('🎯 [CHALLENGE DETAIL CUBIT] Loading challenge: ${challenge.title}');
    emit(ChallengeDetailLoaded(challenge: challenge));
  }

  Future<void> joinChallenge(ChallengeEntity challenge) async {
    try {
      print('🎯 [CHALLENGE DETAIL CUBIT] === JOINING CHALLENGE VIA REAL API ===');
      print('🎯 [CHALLENGE DETAIL CUBIT] Challenge: ${challenge.title}');
      
      // 🔧 OBTENER USER ID REAL
      final userIdResult = await _getCurrentUserId();
      if (userIdResult == null) {
        emit(const ChallengeNotAuthenticated());
        return;
      }

      emit(ChallengeDetailUpdating(
        challenge: challenge,
        action: 'Uniéndose al desafío...',
      ));

      final result = await startChallengeUseCase(
        StartChallengeParams(
          challengeId: challenge.id,
          userId: userIdResult, // 🔧 USER ID REAL
        ),
      );

      result.fold(
        (failure) {
          print('❌ [CHALLENGE DETAIL CUBIT] Failed to join challenge: ${failure.message}');
          emit(ChallengeDetailError(message: failure.message));
        },
        (_) {
          print('✅ [CHALLENGE DETAIL CUBIT] Successfully joined challenge via REAL API');
          
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
          
          emit(ChallengeJoinSuccess(challenge: updatedChallenge));
        },
      );

    } catch (e) {
      print('❌ [CHALLENGE DETAIL CUBIT] Unexpected error joining challenge: $e');
      emit(ChallengeDetailError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> updateProgress(ChallengeEntity challenge, int progress) async {
    try {
      print('🎯 [CHALLENGE DETAIL CUBIT] Updating progress: $progress/${challenge.targetProgress}');
      
      // 🔧 OBTENER USER ID REAL
      final userIdResult = await _getCurrentUserId();
      if (userIdResult == null) {
        emit(const ChallengeNotAuthenticated());
        return;
      }
      
      emit(ChallengeDetailUpdating(
        challenge: challenge,
        action: 'Actualizando progreso...',
      ));

      final result = await updateChallengeProgressUseCase(
        UpdateChallengeProgressParams(
          challengeId: challenge.id,
          userId: userIdResult, // 🔧 USER ID REAL
          progress: progress,
        ),
      );

      result.fold(
        (failure) {
          print('❌ [CHALLENGE DETAIL CUBIT] Failed to update progress: ${failure.message}');
          emit(ChallengeDetailError(message: failure.message));
        },
        (_) {
          print('✅ [CHALLENGE DETAIL CUBIT] Progress updated successfully');
          
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
            // 🆕 SI SE COMPLETA, REQUERIR EVIDENCIA EN LUGAR DE COMPLETAR DIRECTAMENTE
            final userChallengeId = '${userIdResult}_${challenge.id}_${DateTime.now().millisecondsSinceEpoch}';
            
            emit(ChallengeEvidenceRequired(
              challenge: updatedChallenge,
              userChallengeId: userChallengeId,
            ));
          } else {
            emit(ChallengeDetailLoaded(challenge: updatedChallenge));
          }
        },
      );

    } catch (e) {
      print('❌ [CHALLENGE DETAIL CUBIT] Unexpected error updating progress: $e');
      emit(ChallengeDetailError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  // 🆕 MÉTODO PARA ENVIAR EVIDENCIA
  Future<void> submitEvidence(SubmitEvidenceParams evidenceParams) async {
    try {
      print('🎯 [CHALLENGE DETAIL CUBIT] === SUBMITTING EVIDENCE VIA REAL API ===');
      print('🎯 [CHALLENGE DETAIL CUBIT] User Challenge ID: ${evidenceParams.userChallengeId}');
      
      // 🔧 VERIFICAR AUTENTICACIÓN
      final userIdResult = await _getCurrentUserId();
      if (userIdResult == null) {
        emit(const ChallengeNotAuthenticated());
        return;
      }
      
      final currentState = state;
      if (currentState is! ChallengeEvidenceRequired) {
        emit(const ChallengeDetailError(message: 'Estado inválido para envío de evidencia'));
        return;
      }

      emit(ChallengeDetailUpdating(
        challenge: currentState.challenge,
        action: 'Enviando evidencia...',
      ));

      final result = await submitEvidenceUseCase(evidenceParams);

      result.fold(
        (failure) {
          print('❌ [CHALLENGE DETAIL CUBIT] Failed to submit evidence: ${failure.message}');
          emit(ChallengeDetailError(message: failure.message));
        },
        (_) {
          print('✅ [CHALLENGE DETAIL CUBIT] Evidence submitted successfully via REAL API');
          
          // Actualizar el desafío a estado pendiente de validación
          final updatedChallenge = ChallengeEntity(
            id: currentState.challenge.id,
            title: currentState.challenge.title,
            description: currentState.challenge.description,
            category: currentState.challenge.category,
            imageUrl: currentState.challenge.imageUrl,
            iconCode: currentState.challenge.iconCode,
            type: currentState.challenge.type,
            difficulty: currentState.challenge.difficulty,
            totalPoints: currentState.challenge.totalPoints,
            currentProgress: currentState.challenge.currentProgress,
            targetProgress: currentState.challenge.targetProgress,
            status: ChallengeStatus.completed, // Marcado como completado pero pendiente de validación
            startDate: currentState.challenge.startDate,
            endDate: currentState.challenge.endDate,
            requirements: currentState.challenge.requirements,
            rewards: currentState.challenge.rewards,
            isParticipating: currentState.challenge.isParticipating,
            completedAt: DateTime.now(),
            createdAt: currentState.challenge.createdAt,
          );
          
          emit(ChallengePendingValidation(
            challenge: updatedChallenge,
            submissionDate: DateTime.now(),
          ));
        },
      );

    } catch (e) {
      print('❌ [CHALLENGE DETAIL CUBIT] Unexpected error submitting evidence: $e');
      emit(ChallengeDetailError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  // 🆕 MÉTODO PARA MANEJAR VALIDACIÓN APROBADA
  void markValidationApproved(ChallengeEntity challenge, int pointsAwarded) {
    print('🎉 [CHALLENGE DETAIL CUBIT] Challenge validation approved!');
    
    emit(ChallengeCompleted(
      challenge: challenge,
      pointsEarned: pointsAwarded,
    ));
  }

  // 🆕 MÉTODO PARA MANEJAR VALIDACIÓN RECHAZADA
  void markValidationRejected(ChallengeEntity challenge, String reason) async {
    print('❌ [CHALLENGE DETAIL CUBIT] Challenge validation rejected: $reason');
    
    // 🔧 OBTENER USER ID REAL PARA RETRY
    final userIdResult = await _getCurrentUserId();
    if (userIdResult == null) {
      emit(const ChallengeNotAuthenticated());
      return;
    }
    
    // Volver a estado que requiere evidencia
    final userChallengeId = '${userIdResult}_${challenge.id}_retry_${DateTime.now().millisecondsSinceEpoch}';
    
    emit(ChallengeEvidenceRequired(
      challenge: challenge,
      userChallengeId: userChallengeId,
    ));

    // Mostrar mensaje de rechazo
    Future.delayed(const Duration(milliseconds: 100), () {
      emit(ChallengeDetailError(
        message: 'Evidencia rechazada: $reason. Por favor, envía nueva evidencia.',
      ));
    });
  }

  void incrementProgress(ChallengeEntity challenge) {
    final newProgress = (challenge.currentProgress + 1)
        .clamp(0, challenge.targetProgress);
    updateProgress(challenge, newProgress);
  }

  void resetToLoaded() {
    final currentState = state;
    if (currentState is ChallengeJoinSuccess) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    } else if (currentState is ChallengeCompleted) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    } else if (currentState is ChallengeEvidenceSubmitted) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    } else if (currentState is ChallengePendingValidation) {
      emit(ChallengeDetailLoaded(challenge: currentState.challenge));
    }
  }

  // 🆕 MÉTODO PARA CANCELAR ENVÍO DE EVIDENCIA
  void cancelEvidenceSubmission() {
    final currentState = state;
    if (currentState is ChallengeEvidenceRequired) {
      // Volver al estado anterior (progreso incompleto)
      final challengeWithReducedProgress = ChallengeEntity(
        id: currentState.challenge.id,
        title: currentState.challenge.title,
        description: currentState.challenge.description,
        category: currentState.challenge.category,
        imageUrl: currentState.challenge.imageUrl,
        iconCode: currentState.challenge.iconCode,
        type: currentState.challenge.type,
        difficulty: currentState.challenge.difficulty,
        totalPoints: currentState.challenge.totalPoints,
        currentProgress: currentState.challenge.targetProgress - 1, // Reducir progreso
        targetProgress: currentState.challenge.targetProgress,
        status: ChallengeStatus.active,
        startDate: currentState.challenge.startDate,
        endDate: currentState.challenge.endDate,
        requirements: currentState.challenge.requirements,
        rewards: currentState.challenge.rewards,
        isParticipating: currentState.challenge.isParticipating,
        completedAt: null,
        createdAt: currentState.challenge.createdAt,
      );
      
      emit(ChallengeDetailLoaded(challenge: challengeWithReducedProgress));
    }
  }

  // ==================== 🔧 MÉTODO HELPER PARA OBTENER USER ID REAL ====================
  
  /// Obtiene el user ID del usuario autenticado actual
  Future<String?> _getCurrentUserId() async {
    try {
      print('🔍 [CHALLENGE DETAIL CUBIT] Getting current user ID...');
      
      final userResult = await authService.getCurrentUser();
      
      return userResult.fold(
        (failure) {
          print('❌ [CHALLENGE DETAIL CUBIT] Failed to get current user: ${failure.message}');
          return null;
        },
        (user) {
          if (user != null) {
            print('✅ [CHALLENGE DETAIL CUBIT] Current user ID: ${user.id}');
            return user.id;
          } else {
            print('⚠️ [CHALLENGE DETAIL CUBIT] No authenticated user found');
            return null;
          }
        },
      );
    } catch (e) {
      print('❌ [CHALLENGE DETAIL CUBIT] Error getting current user ID: $e');
      return null;
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> _isUserAuthenticated() async {
    try {
      final isLoggedInResult = await authService.isLoggedIn();
      
      return isLoggedInResult.fold(
        (failure) {
          print('❌ [CHALLENGE DETAIL CUBIT] Error checking authentication: ${failure.message}');
          return false;
        },
        (isLoggedIn) {
          print('🔍 [CHALLENGE DETAIL CUBIT] User authenticated: $isLoggedIn');
          return isLoggedIn;
        },
      );
    } catch (e) {
      print('❌ [CHALLENGE DETAIL CUBIT] Error checking authentication: $e');
      return false;
    }
  }

  // ==================== GETTERS DE ESTADO ====================

  bool get isLoading => state is ChallengeDetailUpdating;
  bool get isLoaded => state is ChallengeDetailLoaded;
  bool get hasError => state is ChallengeDetailError;
  bool get isCompleted => state is ChallengeCompleted;
  bool get requiresEvidence => state is ChallengeEvidenceRequired;
  bool get isPendingValidation => state is ChallengePendingValidation;
  bool get isNotAuthenticated => state is ChallengeNotAuthenticated;

  ChallengeEntity? get currentChallenge {
    final currentState = state;
    if (currentState is ChallengeDetailLoaded) return currentState.challenge;
    if (currentState is ChallengeDetailUpdating) return currentState.challenge;
    if (currentState is ChallengeJoinSuccess) return currentState.challenge;
    if (currentState is ChallengeCompleted) return currentState.challenge;
    if (currentState is ChallengeEvidenceRequired) return currentState.challenge;
    if (currentState is ChallengePendingValidation) return currentState.challenge;
    return null;
  }

  String? get userChallengeId {
    final currentState = state;
    if (currentState is ChallengeEvidenceRequired) {
      return currentState.userChallengeId;
    }
    return null;
  }

  // ==================== HELPER METHODS ====================

  /// Crear un ID único para el user challenge
  String _generateUserChallengeId(String challengeId, String userId) {
    return '${userId}_${challengeId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Verificar si el desafío requiere evidencia obligatoria
  bool _requiresEvidence(ChallengeEntity challenge) {
    // Categorías que siempre requieren evidencia
    const evidenceRequiredCategories = [
      'reciclaje',
      'compostaje',
      'limpieza',
      'plantacion',
    ];
    
    return evidenceRequiredCategories.contains(challenge.category.toLowerCase()) ||
           challenge.difficulty == ChallengeDifficulty.hard ||
           challenge.totalPoints >= 200;
  }

  /// Obtener mensaje motivacional según el progreso
  String _getProgressMessage(ChallengeEntity challenge) {
    final percentage = challenge.progressPercentage;
    
    if (percentage >= 1.0) {
      return '¡Excelente! Ahora envía tu evidencia para completar el desafío';
    } else if (percentage >= 0.75) {
      return '¡Casi terminas! Solo un poco más';
    } else if (percentage >= 0.5) {
      return '¡Vas por buen camino! Ya llevas la mitad';
    } else if (percentage > 0) {
      return '¡Buen inicio! Sigue así';
    } else {
      return '¡Comienza tu desafío ecológico!';
    }
  }

  // 🆕 MÉTODO PARA MANEJAR REDIRECCIONAMIENTO A LOGIN
  void redirectToLogin() {
    print('🔐 [CHALLENGE DETAIL CUBIT] User needs to login to participate in challenges');
    emit(const ChallengeNotAuthenticated(
      message: 'Inicia sesión para participar en desafíos ecológicos',
    ));
  }

  // 🆕 MÉTODO PARA VERIFICAR AUTENTICACIÓN ANTES DE ACCIONES
  Future<bool> checkAuthenticationForAction(String action) async {
    final isAuthenticated = await _isUserAuthenticated();
    
    if (!isAuthenticated) {
      print('⚠️ [CHALLENGE DETAIL CUBIT] User not authenticated for action: $action');
      emit(ChallengeNotAuthenticated(
        message: 'Debes iniciar sesión para $action',
      ));
      return false;
    }
    
    return true;
  }
}