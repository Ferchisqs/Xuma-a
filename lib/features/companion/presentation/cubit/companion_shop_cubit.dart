// lib/features/companion/presentation/cubit/companion_shop_cubit.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/di/injection.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// ==================== STATES ====================
abstract class CompanionShopState extends Equatable {
  const CompanionShopState();
  
  @override
  List<Object?> get props => [];
}

class CompanionShopInitial extends CompanionShopState {}

class CompanionShopLoading extends CompanionShopState {}

class CompanionShopLoaded extends CompanionShopState {
  final List<CompanionEntity> availableCompanions;
  final List<CompanionEntity> purchasableCompanions;
  final CompanionStatsEntity userStats;
  
  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
  });
  
  @override
  List<Object> get props => [availableCompanions, purchasableCompanions, userStats];
}

class CompanionShopPurchasing extends CompanionShopState {
  final CompanionEntity companion;
  
  const CompanionShopPurchasing({required this.companion});
  
  @override
  List<Object> get props => [companion];
}

class CompanionShopPurchaseSuccess extends CompanionShopState {
  final CompanionEntity purchasedCompanion;
  final String message;
  
  const CompanionShopPurchaseSuccess({
    required this.purchasedCompanion,
    required this.message,
  });
  
  @override
  List<Object> get props => [purchasedCompanion, message];
}

class CompanionShopError extends CompanionShopState {
  final String message;
  
  const CompanionShopError({required this.message});
  
  @override
  List<Object> get props => [message];
}

// ==================== CUBIT - VERSIÓN CORREGIDA ====================
@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  
  // ✅ ELIMINADO: static const String _defaultUserId = 'user_123';
  // 🔥 AHORA EL USER ID SE OBTIENE INTERNAMENTE DEL TOKEN
  
  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
  }) : super(CompanionShopInitial());
  
  Future<void> loadShop() async {
    try {
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA DESDE API ===');
      emit(CompanionShopLoading());
      
      // 🔥 CAMBIO PRINCIPAL: YA NO PASAR USER ID - SE OBTIENE INTERNAMENTE
      final result = await getCompanionShopUseCase(
        const GetCompanionShopParams(userId: ''), // ← String vacío, se obtiene internamente del token
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error API: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [SHOP_CUBIT] === TIENDA API CARGADA EXITOSAMENTE ===');
          debugPrint('💰 [SHOP_CUBIT] Puntos usuario desde API: ${shopData.userStats.availablePoints}');
          debugPrint('🛍️ [SHOP_CUBIT] Mascotas desde API: ${shopData.availableCompanions.length}');
          
          // Log de cada mascota para debugging
          for (final companion in shopData.availableCompanions) {
            debugPrint('🐾 [SHOP_CUBIT] - ${companion.displayName}: ${companion.purchasePrice}★ (owned: ${companion.isOwned})');
          }
          
          // 🔧 FILTRAR MASCOTAS PARA LA TIENDA
          final purchasableCompanions = _filterCompanionsForShop(shopData.availableCompanions);
          
          debugPrint('🛒 [SHOP_CUBIT] Mascotas en tienda después de filtrar: ${purchasableCompanions.length}');
          
          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: purchasableCompanions,
            userStats: shopData.userStats,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }
  
  
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO ADOPCIÓN VIA API REAL ===');
    debugPrint('🐾 [SHOP_CUBIT] Mascota: ${companion.displayName}');
    debugPrint('🆔 [SHOP_CUBIT] ID: ${companion.id}');
    debugPrint('💰 [SHOP_CUBIT] Precio: ${companion.purchasePrice}★');
    
    if (state is! CompanionShopLoaded) {
      debugPrint('❌ [SHOP_CUBIT] Estado incorrecto para adopción');
      emit(CompanionShopError(message: 'Error: Estado de tienda no válido'));
      return;
    }
    
    final currentState = state as CompanionShopLoaded;
    
    // 🔧 VERIFICAR PUNTOS SUFICIENTES
    if (currentState.userStats.availablePoints < companion.purchasePrice) {
      final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
      debugPrint('❌ [SHOP_CUBIT] Puntos insuficientes: faltan $faltantes');
      emit(CompanionShopError(
        message: 'No tienes suficientes puntos. Necesitas $faltantes puntos más.',
      ));
      return;
    }
    
    debugPrint('⏳ [SHOP_CUBIT] Enviando adopción a API...');
    emit(CompanionShopPurchasing(companion: companion));
    
    try {
      // 🚀 OBTENER USER ID REAL DEL TOKEN
      final tokenManager = getIt<TokenManager>();
      final userId = await tokenManager.getUserId();
      
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ [SHOP_CUBIT] Sin usuario autenticado');
        emit(CompanionShopError(message: 'Debes estar autenticado para adoptar mascotas'));
        return;
      }
      
      debugPrint('👤 [SHOP_CUBIT] Usuario autenticado: $userId');
      
      // 🔥 MAPEAR COMPANION ID A PET ID DE LA API
      final petId = _mapCompanionIdToPetId(companion.id);
      debugPrint('🔄 [SHOP_CUBIT] Mapeando ${companion.id} -> $petId');
      
      // 🚀 LLAMADA A LA API REAL DE ADOPCIÓN
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: petId, // Pet ID de tu API
          nickname: companion.displayName,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error en adopción API: ${failure.message}');
          
          // 🔧 MENSAJES DE ERROR ESPECÍFICOS PARA TU API
          String userMessage;
          if (failure.message.contains('ya adoptada') || 
              failure.message.contains('already adopted')) {
            userMessage = 'Ya tienes esta mascota';
          } else if (failure.message.contains('insufficient') || 
                     failure.message.contains('insuficientes')) {
            userMessage = 'No tienes suficientes puntos';
          } else if (failure.message.contains('not found') || 
                     failure.message.contains('no encontrada')) {
            userMessage = 'Esta mascota no está disponible';
          } else if (failure.message.contains('authentication') || 
                     failure.message.contains('token')) {
            userMessage = 'Error de autenticación. Reinicia sesión.';
          } else {
            userMessage = 'Error adoptando mascota. Intenta de nuevo.';
          }
          
          emit(CompanionShopError(message: userMessage));
        },
        (adoptedCompanion) {
          debugPrint('🎉 [SHOP_CUBIT] === ADOPCIÓN EXITOSA ===');
          debugPrint('✅ [SHOP_CUBIT] Mascota adoptada: ${adoptedCompanion.displayName}');
          debugPrint('🏠 [SHOP_CUBIT] Ahora es tuya: ${adoptedCompanion.isOwned}');
          debugPrint('📅 [SHOP_CUBIT] Adoptada el: ${adoptedCompanion.purchasedAt}');
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: '¡Felicidades! Has adoptado a ${adoptedCompanion.displayName} 🎉',
          ));
          
          // 🔧 RECARGAR TIENDA DESPUÉS DE ADOPCIÓN
          debugPrint('🔄 [SHOP_CUBIT] Recargando tienda después de adopción...');
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Excepción durante adopción: $e');
      emit(CompanionShopError(message: 'Error inesperado durante la adopción: ${e.toString()}'));
    }
  }

  // 🔧 MAPEAR COMPANION ID INTERNO A PET ID DE TU API
  String _mapCompanionIdToPetId(String companionId) {
    debugPrint('🔄 [SHOP_CUBIT] Mapeando companion ID: $companionId');
    
    // 🔧 AQUÍ NECESITAS DEFINIR EL MAPEO SEGÚN TU API
    // Ejemplo de mapeo basado en tu estructura:
    
    final Map<String, String> companionToPetIdMap = {
      // Dexter
      'dexter_baby': '51a56248-17b5-4861-af11-335f9724f9eb',  // 🔧 USAR TU PET ID REAL
      'dexter_young': 'dexter-young-pet-id',
      'dexter_adult': 'dexter-adult-pet-id',
      
      // Elly (Panda)
      'elly_baby': 'elly-baby-pet-id',
      'elly_young': 'elly-young-pet-id', 
      'elly_adult': 'elly-adult-pet-id',
      
      // Paxolotl (Ajolote)
      'paxolotl_baby': 'paxolotl-baby-pet-id',
      'paxolotl_young': 'paxolotl-young-pet-id',
      'paxolotl_adult': 'paxolotl-adult-pet-id',
      
      // Yami (Jaguar)
      'yami_baby': 'yami-baby-pet-id',
      'yami_young': 'yami-young-pet-id',
      'yami_adult': 'yami-adult-pet-id',
    };
    
    final petId = companionToPetIdMap[companionId];
    
    if (petId != null) {
      debugPrint('✅ [SHOP_CUBIT] Mapeo encontrado: $companionId -> $petId');
      return petId;
    } else {
      debugPrint('⚠️ [SHOP_CUBIT] No hay mapeo para: $companionId, usando ID original');
      return companionId;
    }
  }

  /// Recargar tienda después de una adopción exitosa
  Future<void> _reloadShopAfterPurchase() async {
    try {
      debugPrint('🔄 [SHOP_CUBIT] Iniciando recarga post-adopción...');
      
      // Pausa para asegurar que la API se actualice
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (isClosed) {
        debugPrint('⚠️ [SHOP_CUBIT] Cubit cerrado, saltando recarga');
        return;
      }
      
      debugPrint('🔄 [SHOP_CUBIT] Ejecutando loadShop()...');
      await loadShop();
      
      debugPrint('✅ [SHOP_CUBIT] Recarga completada');
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error durante recarga: $e');
    }
  }
Future<void> testAdoptionWithRealApi(String petId) async {
    try {
      debugPrint('🧪 [SHOP_CUBIT] === TESTING ADOPCIÓN CON API REAL ===');
      debugPrint('🆔 [SHOP_CUBIT] Pet ID: $petId');
      
      emit(CompanionShopLoading());
      
      final tokenManager = getIt<TokenManager>();
      final userId = await tokenManager.getUserId();
      
      if (userId == null) {
        emit(CompanionShopError(message: 'No hay usuario autenticado para test'));
        return;
      }
      
      debugPrint('👤 [SHOP_CUBIT] Testing con usuario: $userId');
      
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: petId,
          nickname: 'Mascota de Prueba',
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [TEST] Error en adopción: ${failure.message}');
          emit(CompanionShopError(message: 'Test falló: ${failure.message}'));
        },
        (adoptedCompanion) {
          debugPrint('✅ [TEST] Adopción exitosa: ${adoptedCompanion.displayName}');
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: 'Test exitoso: ${adoptedCompanion.displayName} adoptado',
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [TEST] Excepción: $e');
      emit(CompanionShopError(message: 'Test exception: ${e.toString()}'));
    }
  }

  /// Filtrar companions para mostrar en la tienda
  List<CompanionEntity> _filterCompanionsForShop(List<CompanionEntity> allCompanions) {
    debugPrint('🔧 [SHOP_CUBIT] Filtrando companions para tienda');
    
    final filtered = allCompanions.where((companion) {
      // 🔧 MOSTRAR SOLO LOS NO POSEÍDOS
      final shouldShow = !companion.isOwned;
      debugPrint('🔧 [SHOP_CUBIT] ${companion.displayName}: ${shouldShow ? "MOSTRAR" : "OCULTAR"} (owned: ${companion.isOwned})');
      return shouldShow;
    }).toList();
    
    // Ordenar por precio (más baratos primero)
    filtered.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
    
    debugPrint('🔧 [SHOP_CUBIT] Companions filtrados: ${filtered.length}');
    return filtered;
  }
  
  void refreshShop() {
    debugPrint('🔄 [SHOP_CUBIT] Refresh manual solicitado');
    loadShop();
  }
  
  // Método para filtrar companions por tipo
  List<CompanionEntity> getCompanionsByType(CompanionType type) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.purchasableCompanions
          .where((c) => c.type == type)
          .toList();
    }
    return [];
  }
  
  // Verificar si un companion puede ser comprado
  bool canAffordCompanion(CompanionEntity companion) {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.userStats.availablePoints >= companion.purchasePrice;
    }
    return false;
  }
  
  // Obtener mensaje para companion específico
  String getCompanionMessage(CompanionEntity companion) {
    if (companion.isOwned) {
      return 'Ya lo tienes';
    }
    
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      if (currentState.userStats.availablePoints >= companion.purchasePrice) {
        return 'Disponible para adoptar';
      } else {
        final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
        return 'Necesitas $faltantes puntos más';
      }
    }
    
    return 'Cargando...';
  }

  // 🔥 MÉTODO PARA TESTING/DEBUG DE LA API - TAMBIÉN CORREGIDO
  Future<void> testApiConnection() async {
    try {
      debugPrint('🧪 [SHOP_CUBIT] === TESTING API CONNECTION ===');
      
      emit(CompanionShopLoading());
      
      // 🔥 YA NO USAR USER ID HARDCODEADO EN EL TEST
      final result = await getCompanionShopUseCase(
        const GetCompanionShopParams(userId: ''), // ← Se obtiene internamente del token
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [API_TEST] Error: ${failure.message}');
          emit(CompanionShopError(message: 'API Test Failed: ${failure.message}'));
        },
        (shopData) {
          debugPrint('✅ [API_TEST] === API CONNECTION SUCCESSFUL ===');
          debugPrint('📊 [API_TEST] Data received:');
          debugPrint('   - User points: ${shopData.userStats.availablePoints}');
          debugPrint('   - Total companions: ${shopData.availableCompanions.length}');
          debugPrint('   - Owned companions: ${shopData.userStats.ownedCompanions}');
          
          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: _filterCompanionsForShop(shopData.availableCompanions),
            userStats: shopData.userStats,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [API_TEST] Exception: $e');
      emit(CompanionShopError(message: 'API Test Exception: ${e.toString()}'));
    }
  }
}