// lib/features/companion/presentation/cubit/companion_shop_cubit.dart - Pet IDs DINÁMICOS
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:xuma_a/core/services/token_manager.dart';
import 'package:xuma_a/di/injection.dart';
import 'package:xuma_a/features/companion/data/models/api_pet_response_model.dart';
import 'package:xuma_a/features/companion/data/models/companion_model.dart';
import '../../domain/entities/companion_entity.dart';
import '../../domain/entities/companion_stats_entity.dart';
import '../../domain/usecases/get_companion_shop_usecase.dart';
import '../../domain/usecases/purchase_companion_usecase.dart';

// ==================== STATES (sin cambios) ====================
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
  final Map<String, String> availablePetIds; // 🆕 MAPEO DINÁMICO
  
  const CompanionShopLoaded({
    required this.availableCompanions,
    required this.purchasableCompanions,
    required this.userStats,
    required this.availablePetIds, // 🆕
  });
  
  @override
  List<Object> get props => [availableCompanions, purchasableCompanions, userStats, availablePetIds];
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

// ==================== CUBIT CON PET IDs DINÁMICOS ====================
@injectable
class CompanionShopCubit extends Cubit<CompanionShopState> {
  final GetCompanionShopUseCase getCompanionShopUseCase;
  final PurchaseCompanionUseCase purchaseCompanionUseCase;
  
  // 🆕 MAPEO DINÁMICO QUE SE LLENA DESDE LA API
  Map<String, String> _localIdToApiPetId = {};
  Map<String, Map<String, dynamic>> _apiPetIdToInfo = {};
  
  CompanionShopCubit({
    required this.getCompanionShopUseCase,
    required this.purchaseCompanionUseCase,
  }) : super(CompanionShopInitial());
  
  Future<void> loadShop() async {
    try {
      debugPrint('🏪 [SHOP_CUBIT] === CARGANDO TIENDA DESDE API REAL ===');
      emit(CompanionShopLoading());
      
      final result = await getCompanionShopUseCase(
        const GetCompanionShopParams(userId: ''),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error API: ${failure.message}');
          emit(CompanionShopError(message: failure.message));
        },
        (shopData) {
          debugPrint('✅ [SHOP_CUBIT] === TIENDA API CARGADA ===');
          debugPrint('💰 [SHOP_CUBIT] Puntos usuario: ${shopData.userStats.availablePoints}');
          debugPrint('🛍️ [SHOP_CUBIT] Mascotas: ${shopData.availableCompanions.length}');
          
          // 🆕 EXTRAER MAPEO DINÁMICO DESDE LOS COMPANIONS
          _buildDynamicMapping(shopData.availableCompanions);
          
          final purchasableCompanions = _filterCompanionsForShop(shopData.availableCompanions);
          
          debugPrint('🛒 [SHOP_CUBIT] En tienda: ${purchasableCompanions.length}');
          debugPrint('🗺️ [SHOP_CUBIT] Pet IDs encontrados: ${_localIdToApiPetId.length}');
          
          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: purchasableCompanions,
            userStats: shopData.userStats,
            availablePetIds: Map.from(_localIdToApiPetId), // 🆕 EXPONER EL MAPEO
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Error inesperado: $e');
      emit(CompanionShopError(message: 'Error inesperado: ${e.toString()}'));
    }
  }
  
  // 🆕 CONSTRUIR MAPEO DINÁMICO DESDE LA API
  void _buildDynamicMapping(List<CompanionEntity> companions) {
    debugPrint('🗺️ [MAPPING] === CONSTRUYENDO MAPEO DINÁMICO ===');
    
    _localIdToApiPetId.clear();
    _apiPetIdToInfo.clear();
    
    for (final companion in companions) {
      // 🔧 OBTENER EL API PET ID DESDE EL COMPANION
      final apiPetId = _extractApiPetIdFromCompanion(companion);
      
      if (apiPetId != null && apiPetId.isNotEmpty) {
        final localId = companion.id;
        
        // Mapear local ID -> API Pet ID
        _localIdToApiPetId[localId] = apiPetId;


        // Mapear API Pet ID -> Info del companion
        _apiPetIdToInfo[apiPetId] = {
          'name': companion.name,
          'type': companion.type.name,
          'description': companion.description,
          'stage': companion.stage.name,
        };
        
        debugPrint('🗺️ [MAPPING] $localId -> $apiPetId (${companion.name})');
      } else {
        debugPrint('⚠️ [MAPPING] No se pudo extraer Pet ID para: ${companion.id}');
      }
    }
    
    debugPrint('✅ [MAPPING] Mapeo dinámico completado: ${_localIdToApiPetId.length} entries');
  }
  
  String? _extractApiPetIdFromCompanion(CompanionEntity companion) {
    debugPrint('🔍 [MAPPING] Extrayendo Pet ID de: ${companion.id} (${companion.name})');
    
    if (companion is CompanionModelWithPetId) {
      debugPrint('✅ [MAPPING] Pet ID encontrado en CompanionModelWithPetId: ${companion.petId}');
      return companion.petId;
    }
    
    // 🔧 OPCIÓN 2: Si el companion tiene petId en su JSON
    if (companion is CompanionModel) {
      try {
        final json = companion.toJson();
        if (json.containsKey('petId') && json['petId'] != null) {
          final petId = json['petId'] as String;
          debugPrint('✅ [MAPPING] Pet ID encontrado en JSON: $petId');
          return petId;
        }
      } catch (e) {
        debugPrint('⚠️ [MAPPING] Error accediendo JSON: $e');
      }
    }
    
    // 🔧 OPCIÓN 3: Si el ID del companion parece un UUID (fallback)
    if (companion.id.length > 20 && companion.id.contains('-')) {
      debugPrint('🔍 [MAPPING] ID parece UUID, usando como Pet ID: ${companion.id}');
      return companion.id;
    }
  
    
    debugPrint('❌ [MAPPING] No se pudo determinar Pet ID para: ${companion.id}');
    return null;
  }
  
  
  
  Future<void> purchaseCompanion(CompanionEntity companion) async {
    debugPrint('🛒 [SHOP_CUBIT] === INICIANDO ADOPCIÓN REAL ===');
    debugPrint('🐾 [SHOP_CUBIT] Companion Local ID: ${companion.id}');
    debugPrint('💰 [SHOP_CUBIT] Precio: ${companion.purchasePrice}★');
    
    if (state is! CompanionShopLoaded) {
      debugPrint('❌ [SHOP_CUBIT] Estado incorrecto para adopción');
      emit(CompanionShopError(message: 'Error: Estado de tienda no válido'));
      return;
    }
    
    final currentState = state as CompanionShopLoaded;
    
    // Verificar puntos suficientes
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
      // Obtener user ID real del token
      final tokenManager = getIt<TokenManager>();
      final userId = await tokenManager.getUserId();
      
      if (userId == null || userId.isEmpty) {
        debugPrint('❌ [SHOP_CUBIT] Sin usuario autenticado');
        emit(CompanionShopError(message: 'Debes estar autenticado para adoptar mascotas'));
        return;
      }
      
      debugPrint('👤 [SHOP_CUBIT] Usuario autenticado: $userId');
      
      // 🆕 OBTENER PET ID DINÁMICAMENTE
      final apiPetId = currentState.availablePetIds[companion.id];
      debugPrint('🗺️ [SHOP_CUBIT] Buscando Pet ID para: ${companion.id}');
      debugPrint('🔄 [SHOP_CUBIT] Pet ID encontrado: $apiPetId');
      
      if (apiPetId == null || apiPetId.isEmpty) {
        debugPrint('❌ [SHOP_CUBIT] No se encontró Pet ID para: ${companion.id}');
        debugPrint('🗺️ [SHOP_CUBIT] Pet IDs disponibles: ${currentState.availablePetIds.keys.toList()}');
        emit(CompanionShopError(message: 'Error: No se pudo obtener Pet ID desde la API'));
        return;
      }
      
      // 🚀 LLAMADA A LA API CON PET ID REAL OBTENIDO DINÁMICAMENTE
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: apiPetId, // 🔥 PET ID REAL OBTENIDO DE LA API
          nickname: companion.displayName,
        ),
      );
      
      result.fold(
        (failure) {
          debugPrint('❌ [SHOP_CUBIT] Error en adopción API: ${failure.message}');
          
          String userMessage;
          if (failure.message.contains('ya adoptada') || 
              failure.message.contains('already adopted')) {
            userMessage = 'Ya tienes esta mascota';
          } else if (failure.message.contains('insufficient') || 
                     failure.message.contains('insuficientes')) {
            userMessage = 'No tienes suficientes puntos';
          } else if (failure.message.contains('not found') || 
                     failure.message.contains('no encontrada') ||
                     failure.message.contains('Mascota no encontrada')) {
            userMessage = 'Esta mascota no está disponible en el servidor';
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
          
          emit(CompanionShopPurchaseSuccess(
            purchasedCompanion: adoptedCompanion,
            message: '¡Felicidades! Has adoptado a ${adoptedCompanion.displayName} 🎉',
          ));
          
          // Recargar tienda después de adopción
          debugPrint('🔄 [SHOP_CUBIT] Recargando tienda...');
          _reloadShopAfterPurchase();
        },
      );
    } catch (e) {
      debugPrint('❌ [SHOP_CUBIT] Excepción durante adopción: $e');
      emit(CompanionShopError(message: 'Error inesperado durante la adopción: ${e.toString()}'));
    }
  }

  // 🔧 MÉTODO DE TESTING CON LOS PET IDs REALES DE LA API
  Future<void> testAdoptionWithRealApi({String? specificPetId}) async {
    try {
      debugPrint('🧪 [SHOP_CUBIT] === TESTING ADOPCIÓN CON PET IDs REALES ===');
      
      if (state is! CompanionShopLoaded) {
        debugPrint('❌ [TEST] Estado incorrecto, necesita cargar tienda primero');
        emit(CompanionShopError(message: 'Necesitas cargar la tienda primero'));
        return;
      }
      
      final currentState = state as CompanionShopLoaded;
      
      // 🔧 USAR PET ID ESPECÍFICO O EL PRIMERO DISPONIBLE
      String? testPetId = specificPetId;
      if (testPetId == null || testPetId.isEmpty) {
        if (currentState.availablePetIds.isNotEmpty) {
          testPetId = currentState.availablePetIds.values.first;
        } else {
          emit(CompanionShopError(message: 'No hay Pet IDs disponibles para test'));
          return;
        }
      }
      
      debugPrint('🆔 [TEST] Pet ID a usar: $testPetId');
      
      emit(CompanionShopLoading());
      
      final tokenManager = getIt<TokenManager>();
      final userId = await tokenManager.getUserId();
      
      if (userId == null) {
        emit(CompanionShopError(message: 'No hay usuario autenticado para test'));
        return;
      }
      
      debugPrint('👤 [TEST] Testing con usuario: $userId');
      
      // 🔥 USAR PET ID REAL OBTENIDO DE LA API
      final result = await purchaseCompanionUseCase(
        PurchaseCompanionParams(
          userId: userId,
          companionId: testPetId, // PET ID REAL DE LA API
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

  /// Recargar tienda después de una adopción exitosa
  Future<void> _reloadShopAfterPurchase() async {
    try {
      debugPrint('🔄 [SHOP_CUBIT] Iniciando recarga post-adopción...');
      
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

  /// Filtrar companions para mostrar en la tienda
  List<CompanionEntity> _filterCompanionsForShop(List<CompanionEntity> allCompanions) {
    debugPrint('🔧 [SHOP_CUBIT] Filtrando companions para tienda');
    
    final filtered = allCompanions.where((companion) {
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

  // 🆕 MÉTODO PARA OBTENER PET IDs DISPONIBLES (PARA DEBUG)
  List<String> getAvailablePetIds() {
    if (state is CompanionShopLoaded) {
      final currentState = state as CompanionShopLoaded;
      return currentState.availablePetIds.values.toList();
    }
    return [];
  }

  // Método para testing/debug de la API
  Future<void> testApiConnection() async {
    try {
      debugPrint('🧪 [SHOP_CUBIT] === TESTING API CONNECTION ===');
      
      emit(CompanionShopLoading());
      
      final result = await getCompanionShopUseCase(
        const GetCompanionShopParams(userId: ''),
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
          
          // Construir mapeo dinámico
          _buildDynamicMapping(shopData.availableCompanions);
          
          emit(CompanionShopLoaded(
            availableCompanions: shopData.availableCompanions,
            purchasableCompanions: _filterCompanionsForShop(shopData.availableCompanions),
            userStats: shopData.userStats,
            availablePetIds: Map.from(_localIdToApiPetId),
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ [API_TEST] Exception: $e');
      emit(CompanionShopError(message: 'API Test Exception: ${e.toString()}'));
    }
  }
}