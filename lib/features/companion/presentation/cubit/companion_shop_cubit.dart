
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// States (sin cambios)
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
  final Map<String, String> availablePetIds;
  final List<CompanionEntity> userOwnedCompanions;

  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
    required this.availablePetIds,
    required this.userOwnedCompanions,
  });

  @override
  List<Object> get props => [
    availableCompanions, 
    purchasableCompanions, 
    userStats, 
    availablePetIds, 
    userOwnedCompanions
  ];
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

@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  final TokenManager tokenManager;

  Map<String, String> _localIdToApiPetId = {};
  List<CompanionEntity> _userOwnedCompanions = [];
  Set<CompanionType> _ownedTypes = {};

  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
    required this.tokenManager,
  }) : super(CompanionShopInitial());

 Future<void> loadShop() async {
    try {
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA CON LÓGICA DE TIPOS ===');
      emit(CompanionShopLoading());

      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        emit(CompanionShopError(message: '🔐 Usuario no autenticado'));
        return;
      }

      final result = await getCompanionShopUseCase(
        GetCompanionShopParams(userId: userId),
      );

      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error API: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [SHOP_CUBIT] === TIENDA API CARGADA ===');
          
          final availableCompanions = shopData.availableCompanions;
          debugPrint('🛍️ [SHOP_CUBIT] Mascotas disponibles desde API: ${availableCompanions.length}');
          
          // 🔥 EXTRAER MASCOTAS YA ADOPTADAS Y TIPOS ADOPTADOS
          _userOwnedCompanions = availableCompanions.where((c) => c.isOwned).toList();
          _ownedTypes = _userOwnedCompanions.map((c) => c.type).toSet();
          
          debugPrint('🏠 [SHOP_CUBIT] Mascotas ya adoptadas: ${_userOwnedCompanions.length}');
          debugPrint('🐾 [SHOP_CUBIT] Tipos adoptados: ${_ownedTypes.map((t) => t.name).toList()}');
          
          // 🔥 MASCOTAS DISPONIBLES PARA COMPRAR (isOwned = false)
          final purchasableCompanions = availableCompanions.where((c) => !c.isOwned).toList();
          debugPrint('🛒 [SHOP_CUBIT] Mascotas disponibles para comprar: ${purchasableCompanions.length}');

          // 🔥 CONSTRUIR MAPEO DE PET IDS
          _buildPetIdMapping(availableCompanions);

          // 🔥 ORDENAR POR PRECIO (MÁS BARATOS PRIMERO)
          purchasableCompanions.sort((a, b) => a.purchasePrice.compareTo(b.purchasePrice));

          debugPrint('🛒 [SHOP_CUBIT] === TIENDA FINAL (TIPOS CORRECTOS) ===');
          for (final companion in purchasableCompanions) {
            debugPrint('🏪 [SHOP_CUBIT] ${companion.displayName} ${companion.stage.name}: ${companion.purchasePrice}★ (${companion.isOwned ? "YA TIENE" : "DISPONIBLE"})');
          }

          emit(CompanionShopLoaded(
            availableCompanions: availableCompanions,
            purchasableCompanions: purchasableCompanions,
            userStats: shopData.userStats,
            availablePetIds: Map.from(_localIdToApiPetId),
            userOwnedCompanions: _userOwnedCompanions,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

   Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === ADOPTANDO CON VERIFICACIÓN DE TIPOS ===');
    debugPrint('🐾 [SHOP_CUBIT] Companion: ${companion.displayName} ${companion.stage.name}');
    debugPrint('🔍 [SHOP_CUBIT] Tipo: ${companion.type.name}');
    debugPrint('💰 [SHOP_CUBIT] Precio: ${companion.purchasePrice}★');

    if (state is! CompanionShopLoaded) {
      emit(CompanionShopError(message: '❌ Error: Estado de tienda no válido'));
      return;
    }

    final currentState = state as CompanionShopLoaded;

    // 🔥 VALIDACIÓN MEJORADA: Verificar si ya tiene este tipo
    if (_ownedTypes.contains(companion.type)) {
      emit(CompanionShopError(
        message: '✅ Ya tienes una mascota ${companion.typeDescription}. No puedes adoptar más del mismo tipo.',
      ));
      return;
    }

    // 🔥 VALIDACIÓN: También verificar isOwned (por si acaso)
    if (companion.isOwned) {
      emit(CompanionShopError(
        message: '✅ Ya tienes a ${companion.displayName} ${companion.stage.name}.',
      ));
      return;
    }

    // 🔥 VALIDACIÓN: Puntos suficientes
    if (currentState.userStats.availablePoints < companion.purchasePrice) {
      final faltantes = companion.purchasePrice - currentState.userStats.availablePoints;
      emit(CompanionShopError(
        message: '💰 No tienes suficientes puntos. Necesitas $faltantes puntos más.',
      ));
      return;
    }

    emit(CompanionShopPurchasing(companion: companion));

    try {
      final userId = await tokenManager.getUserId();
      if (userId == null || userId.isEmpty) {
        emit(CompanionShopError(message: '🔐 Usuario no autenticado'));
        return;
      }

      // 🔥 USAR EL PET ID REAL DE LA API
      String apiPetId = _extractRealPetId(companion);
      
      debugPrint('🗺️ [SHOP_CUBIT] Pet ID para adopción: $apiPetId');
      debugPrint('🚀 [SHOP_CUBIT] Llamando API de adopción...');

      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: apiPetId,
          nickname: companion.displayName,
        ),
      );

      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error en adopción: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (adoptedCompanion) {
          debugPrint('🎉 [SHOP_CUBIT] === ADOPCIÓN EXITOSA ===');
          debugPrint('✅ [SHOP_CUBIT] Mascota adoptada: ${adoptedCompanion.displayName}');
          
          // 🔥 ACTUALIZAR EL SET DE TIPOS ADOPTADOS
          _ownedTypes.add(companion.type);
          debugPrint('🐾 [SHOP_CUBIT] Tipo ${companion.type.name} marcado como adoptado');
          
          final message = '🎉 ¡Has adoptado a ${adoptedCompanion.displayName} ${companion.stage.name}!\n\n'
                         '📝 Nota: Todas las etapas de ${companion.typeDescription} ahora están marcadas como adoptadas.';
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: message,
          ));

          // Recargar tienda después de adopción exitosa
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error: $e');
      emit(CompanionShopError(message: '❌ Error adoptando: ${e.toString()}'));
    }
  }

  // 🔥 EXTRAER PET ID REAL DE LA API (SIN FALLBACKS LOCALES)
   String _extractRealPetId(CompanionEntity companion) {
    debugPrint('🔍 [SHOP_CUBIT] === EXTRAYENDO PET ID REAL ===');
    debugPrint('🐾 [SHOP_CUBIT] Companion: ${companion.displayName}');
    debugPrint('🆔 [SHOP_CUBIT] Local ID: ${companion.id}');
    
    // 1. 🔥 INTENTAR EXTRAER DE CompanionModelWithPetId
    if (companion is CompanionModelWithPetId) {
      final apiPetId = companion.petId;
      debugPrint('✅ [SHOP_CUBIT] Pet ID desde CompanionModelWithPetId: $apiPetId');
      
      if (apiPetId.isNotEmpty && apiPetId != 'unknown') {
        return apiPetId;
      }
    }
    
    // 2. 🔥 BUSCAR EN EL MAPEO
    if (_localIdToApiPetId.containsKey(companion.id)) {
      final mappedPetId = _localIdToApiPetId[companion.id]!;
      debugPrint('✅ [SHOP_CUBIT] Pet ID desde mapeo: $mappedPetId');
      return mappedPetId;
    }
    
    // 3. 🔥 INTENTAR EXTRAER DEL JSON
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          final jsonPetId = json['petId'] as String;
          debugPrint('✅ [SHOP_CUBIT] Pet ID desde JSON: $jsonPetId');
          
          if (jsonPetId.isNotEmpty && jsonPetId != 'unknown') {
            return jsonPetId;
          }
        }
      } catch (e) {
        debugPrint('❌ [SHOP_CUBIT] Error extrayendo del JSON: $e');
      }
    }
    
    // 4. 🆘 SI NO SE ENCUENTRA, USAR EL ID LOCAL COMO ÚLTIMO RECURSO
    debugPrint('⚠️ [SHOP_CUBIT] No se encontró Pet ID específico, usando ID local: ${companion.id}');
    return companion.id;
  }

  void _buildPetIdMapping(List<CompanionEntity> companions) {
    _localIdToApiPetId.clear();
    debugPrint('🗺️ [SHOP_CUBIT] === CONSTRUYENDO MAPEO DE PET IDS ===');
    
    for (final companion in companions) {
      String? apiPetId;
      
      // Extraer Pet ID real
      if (companion is CompanionModelWithPetId) {
        apiPetId = companion.petId;
      } else if (companion is CompanionModel) {
        try {
          final json = companion.toJson();
          apiPetId = json['petId'] as String?;
        } catch (e) {
          debugPrint('❌ [SHOP_CUBIT] Error extrayendo Pet ID de JSON: $e');
        }
      }
      
      if (apiPetId != null && apiPetId.isNotEmpty && apiPetId != 'unknown') {
        _localIdToApiPetId[companion.id] = apiPetId;
        debugPrint('🗺️ [SHOP_CUBIT] Mapeo: ${companion.id} -> $apiPetId');
      } else {
        debugPrint('⚠️ [SHOP_CUBIT] Sin Pet ID para: ${companion.id}');
      }
    }
    
    debugPrint('✅ [SHOP_CUBIT] Mapeo completado: ${_localIdToApiPetId.length} entries');
  }

  Future<void> _reloadShopAfterPurchase() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (isClosed) return;
    await loadShop();
  }

  void refreshShop() {
    loadShop();
  }


  
}