// lib/features/tips/presentation/cubit/tips_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/tip_entity.dart';
import '../../domain/repositories/tips_repository.dart';
import 'dart:math';

// States
abstract class TipsState extends Equatable {
  const TipsState();
  
  @override
  List<Object?> get props => [];
}

class TipsInitial extends TipsState {}

class TipsLoading extends TipsState {
  final String message;
  
  const TipsLoading([this.message = 'Cargando tips...']);
  
  @override
  List<Object?> get props => [message];
}

class TipsLoaded extends TipsState {
  final List<TipEntity> tips;
  final TipEntity? currentTip;
  final int currentIndex;
  
  const TipsLoaded({
    required this.tips,
    this.currentTip,
    this.currentIndex = 0,
  });
  
  @override
  List<Object?> get props => [tips, currentTip, currentIndex];
  
  TipsLoaded copyWith({
    List<TipEntity>? tips,
    TipEntity? currentTip,
    int? currentIndex,
  }) {
    return TipsLoaded(
      tips: tips ?? this.tips,
      currentTip: currentTip ?? this.currentTip,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class TipsError extends TipsState {
  final String message;
  final List<TipEntity>? fallbackTips;
  
  const TipsError(this.message, {this.fallbackTips});
  
  @override
  List<Object?> get props => [message, fallbackTips];
}

// Cubit
@injectable
class TipsCubit extends Cubit<TipsState> {
  final TipsRepository _repository;
  
  // OPCIÓN 1: Remover el parámetro innecesario
  TipsCubit(this._repository) : super(TipsInitial());
  
  // OPCIÓN 2: Si tienes un use case, úsalo así:
  // final GetRandomTipUseCase _getRandomTipUseCase;
  // TipsCubit(this._repository, this._getRandomTipUseCase) : super(TipsInitial());

  // ==================== LOAD ALL TIPS ====================
  
  Future<void> loadTips({bool forceRefresh = false}) async {
    try {
      emit(const TipsLoading('Cargando consejos de Xico...'));
      print('🎯 [TIPS CUBIT] Loading tips...');
      
      final result = await _repository.getAllTips(limit: 100);
      
      result.fold(
        (failure) {
          print('❌ [TIPS CUBIT] Failed to load tips: ${failure.message}');
          emit(TipsError(failure.message));
        },
        (tips) {
          print('✅ [TIPS CUBIT] Tips loaded successfully: ${tips.length}');
          
          if (tips.isNotEmpty) {
            // Seleccionar primer tip como actual
            emit(TipsLoaded(
              tips: tips,
              currentTip: tips.first,
              currentIndex: 0,
            ));
          } else {
            emit(const TipsError('No se encontraron tips disponibles'));
          }
        },
      );
    } catch (e) {
      print('❌ [TIPS CUBIT] Exception loading tips: $e');
      emit(TipsError('Error inesperado: $e'));
    }
  }

  // ==================== GET RANDOM TIP ====================
  
  Future<void> getRandomTip({String? category}) async {
    try {
      print('🎲 [TIPS CUBIT] Getting random tip...');
      
      // Si ya tenemos tips cargados, usar uno de ellos
      if (state is TipsLoaded) {
        final currentState = state as TipsLoaded;
        final availableTips = category != null
            ? currentState.tips.where((tip) => 
                tip.category.toLowerCase() == category.toLowerCase()).toList()
            : currentState.tips;
        
        if (availableTips.isNotEmpty) {
          final random = Random();
          final randomIndex = random.nextInt(availableTips.length);
          final randomTip = availableTips[randomIndex];
          
          // Encontrar el índice en la lista completa
          final originalIndex = currentState.tips.indexOf(randomTip);
          
          emit(currentState.copyWith(
            currentTip: randomTip,
            currentIndex: originalIndex >= 0 ? originalIndex : 0,
          ));
          
          print('✅ [TIPS CUBIT] Random tip selected: ${randomTip.title}');
          return;
        }
      }
      
      // Si no tenemos tips cargados, obtener uno de la API
      emit(const TipsLoading('Obteniendo consejo...'));
      
      final result = await _repository.getRandomTip(category: category);
      
      result.fold(
        (failure) {
          print('❌ [TIPS CUBIT] Failed to get random tip: ${failure.message}');
          emit(TipsError(failure.message));
        },
        (tip) {
          print('✅ [TIPS CUBIT] Random tip obtained: ${tip.title}');
          emit(TipsLoaded(
            tips: [tip],
            currentTip: tip,
            currentIndex: 0,
          ));
        },
      );
    } catch (e) {
      print('❌ [TIPS CUBIT] Exception getting random tip: $e');
      emit(TipsError('Error obteniendo consejo: $e'));
    }
  }

  // ==================== NAVIGATION METHODS ====================
  
  void nextTip() {
    if (state is TipsLoaded) {
      final currentState = state as TipsLoaded;
      if (currentState.tips.isNotEmpty) {
        final nextIndex = (currentState.currentIndex + 1) % currentState.tips.length;
        final nextTip = currentState.tips[nextIndex];
        
        emit(currentState.copyWith(
          currentTip: nextTip,
          currentIndex: nextIndex,
        ));
        
        print('➡️ [TIPS CUBIT] Next tip: ${nextTip.title}');
      }
    }
  }
  
  void previousTip() {
    if (state is TipsLoaded) {
      final currentState = state as TipsLoaded;
      if (currentState.tips.isNotEmpty) {
        final prevIndex = currentState.currentIndex <= 0 
            ? currentState.tips.length - 1 
            : currentState.currentIndex - 1;
        final prevTip = currentState.tips[prevIndex];
        
        emit(currentState.copyWith(
          currentTip: prevTip,
          currentIndex: prevIndex,
        ));
        
        print('⬅️ [TIPS CUBIT] Previous tip: ${prevTip.title}');
      }
    }
  }

  // ==================== CATEGORY METHODS ====================
  
  Future<void> loadTipsByCategory(String category) async {
    try {
      emit(const TipsLoading('Cargando consejos por categoría...'));
      print('📂 [TIPS CUBIT] Loading tips by category: $category');
      
      final result = await _repository.getTipsByCategory(category);
      
      result.fold(
        (failure) {
          print('❌ [TIPS CUBIT] Failed to load tips by category: ${failure.message}');
          emit(TipsError(failure.message));
        },
        (tips) {
          print('✅ [TIPS CUBIT] Tips by category loaded: ${tips.length}');
          
          if (tips.isNotEmpty) {
            emit(TipsLoaded(
              tips: tips,
              currentTip: tips.first,
              currentIndex: 0,
            ));
          } else {
            emit(TipsError('No se encontraron consejos para la categoría: $category'));
          }
        },
      );
    } catch (e) {
      print('❌ [TIPS CUBIT] Exception loading tips by category: $e');
      emit(TipsError('Error cargando consejos por categoría: $e'));
    }
  }

  // ==================== UTILITY METHODS ====================
  
  void selectTip(TipEntity tip) {
    if (state is TipsLoaded) {
      final currentState = state as TipsLoaded;
      final index = currentState.tips.indexOf(tip);
      
      emit(currentState.copyWith(
        currentTip: tip,
        currentIndex: index >= 0 ? index : 0,
      ));
      
      print('🎯 [TIPS CUBIT] Tip selected: ${tip.title}');
    }
  }
  
  void refreshTips() {
    print('🔄 [TIPS CUBIT] Refreshing tips...');
    loadTips(forceRefresh: true);
  }
  
  // ==================== GETTERS ====================
  
  List<TipEntity> get allTips {
    if (state is TipsLoaded) {
      return (state as TipsLoaded).tips;
    }
    return [];
  }
  
  TipEntity? get currentTip {
    if (state is TipsLoaded) {
      return (state as TipsLoaded).currentTip;
    }
    return null;
  }
  
  int get currentIndex {
    if (state is TipsLoaded) {
      return (state as TipsLoaded).currentIndex;
    }
    return 0;
  }
  
  bool get hasTips => allTips.isNotEmpty;
  
  bool get isLoading => state is TipsLoading;
  
  bool get hasError => state is TipsError;
  
  String? get errorMessage {
    if (state is TipsError) {
      return (state as TipsError).message;
    }
    return null;
  }
  
  // ==================== CATEGORIES ====================
  
  List<String> get availableCategories {
    if (state is TipsLoaded) {
      final tips = (state as TipsLoaded).tips;
      return tips.map((tip) => tip.category).toSet().toList()..sort();
    }
    return [];
  }
  
  List<TipEntity> getTipsByCategory(String category) {
    if (state is TipsLoaded) {
      final tips = (state as TipsLoaded).tips;
      return tips.where((tip) => 
        tip.category.toLowerCase() == category.toLowerCase()).toList();
    }
    return [];
  }

  // ==================== DEBUG ====================
  
  void debugState() {
    print('🔍 [TIPS CUBIT] Current state: ${state.runtimeType}');
    if (state is TipsLoaded) {
      final loadedState = state as TipsLoaded;
      print('🔍 [TIPS CUBIT] Tips count: ${loadedState.tips.length}');
      print('🔍 [TIPS CUBIT] Current tip: ${loadedState.currentTip?.title}');
      print('🔍 [TIPS CUBIT] Current index: ${loadedState.currentIndex}');
    } else if (state is TipsError) {
      final errorState = state as TipsError;
      print('🔍 [TIPS CUBIT] Error: ${errorState.message}');
    }
  }
}