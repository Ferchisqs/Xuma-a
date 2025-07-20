// lib/features/companion/presentation/cubit/welcome_companion_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/usecases/get_user_companions_usecase.dart';
import '../../../../core/services/token_manager.dart';

// ==================== STATES ====================
abstract class WelcomeCompanionState extends Equatable {
  const WelcomeCompanionState();
  
  @override
  List<Object?> get props => [];
}

class WelcomeCompanionInitial extends WelcomeCompanionState {}

class WelcomeCompanionChecking extends WelcomeCompanionState {}

class WelcomeCompanionShowDexterWelcome extends WelcomeCompanionState {
  final CompanionEntity dexterBaby;
  
  const WelcomeCompanionShowDexterWelcome({required this.dexterBaby});
  
  @override
  List<Object> get props => [dexterBaby];
}

class WelcomeCompanionNoWelcomeNeeded extends WelcomeCompanionState {}

class WelcomeCompanionError extends WelcomeCompanionState {
  final String message;
  
  const WelcomeCompanionError({required this.message});
  
  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ====================
@injectable
class WelcomeCompanionCubit extends Cubit<WelcomeCompanionState> {
  final GetUserCompanionsUseCase getUserCompanionsUseCase;
  final TokenManager tokenManager;
  
  WelcomeCompanionCubit({
    required this.getUserCompanionsUseCase,
    required this.tokenManager,
  }) : super(WelcomeCompanionInitial());
  
  /// 🔧 VERIFICAR SI ES PRIMERA VEZ Y MOSTRAR BIENVENIDA DE DEXTER
  Future<void> checkAndShowWelcomeIfNeeded() async {
    try {
      debugPrint('🎉 [WELCOME_CUBIT] === VERIFICANDO PRIMERA VEZ ===');
      emit(WelcomeCompanionChecking());
      
      // Obtener user ID real
      final userId = await tokenManager.getUserId();
      if (userId == null) {
        debugPrint('❌ [WELCOME_CUBIT] No hay usuario logueado');
        emit(WelcomeCompanionNoWelcomeNeeded());
        return;
      }
      
      debugPrint('👤 [WELCOME_CUBIT] Usuario: $userId');
      
      // Obtener mascotas del usuario
      final result = await getUserCompanionsUseCase(
        GetUserCompanionsParams(userId: userId),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [WELCOME_CUBIT] Error: ${failure.message}');
          
          // Si es la primera vez (error porque no tiene mascotas), mostrar bienvenida
          if (failure.message.contains('not found') || 
              failure.message.contains('no encontrado') ||
              failure.message.contains('empty')) {
            debugPrint('🎉 [WELCOME_CUBIT] Primera vez detectada - mostrando bienvenida');
            final dexterBaby = _createDexterBabyWelcome();
            emit(WelcomeCompanionShowDexterWelcome(dexterBaby: dexterBaby));
          } else {
            emit(WelcomeCompanionError(message: failure.message));
          }
        },
        (companions) {
          debugPrint('✅ [WELCOME_CUBIT] Mascotas obtenidas: ${companions.length}');
          
          // Verificar si tiene Dexter baby
          final hasDexterBaby = companions.any((c) => 
            c.type == CompanionType.dexter && 
            c.stage == CompanionStage.baby &&
            c.isOwned
          );
          
          if (!hasDexterBaby) {
            debugPrint('🎉 [WELCOME_CUBIT] No tiene Dexter baby - mostrando bienvenida');
            final dexterBaby = _createDexterBabyWelcome();
            emit(WelcomeCompanionShowDexterWelcome(dexterBaby: dexterBaby));
          } else {
            debugPrint('✅ [WELCOME_CUBIT] Ya tiene Dexter baby - no mostrar bienvenida');
            emit(WelcomeCompanionNoWelcomeNeeded());
          }
        },
      );
      
    } catch (e) {
      debugPrint('❌ [WELCOME_CUBIT] Error inesperado: $e');
      emit(WelcomeCompanionError(message: 'Error verificando bienvenida: ${e.toString()}'));
    }
  }
  
  /// 🔧 CREAR DEXTER BABY PARA LA BIENVENIDA
  CompanionEntity _createDexterBabyWelcome() {
    return CompanionEntity(
      id: 'dexter_baby',
      type: CompanionType.dexter,
      stage: CompanionStage.baby,
      name: 'Dexter',
      description: 'Un pequeño chihuahua mexicano que enseña sobre el reciclaje y los hábitos urbanos sostenibles.',
      level: 1,
      experience: 0,
      happiness: 100,
      hunger: 100,
      energy: 100,
      isOwned: true,
      isSelected: true,
      purchasedAt: DateTime.now(),
      currentMood: CompanionMood.happy,
      purchasePrice: 0, // Gratis
      evolutionPrice: 50,
      unlockedAnimations: ['idle', 'blink', 'happy'],
      createdAt: DateTime.now(),
    );
  }
  
  /// 🔧 MARCAR BIENVENIDA COMO COMPLETADA
  void completeWelcome() {
    debugPrint('✅ [WELCOME_CUBIT] Bienvenida completada');
    emit(WelcomeCompanionNoWelcomeNeeded());
  }
}