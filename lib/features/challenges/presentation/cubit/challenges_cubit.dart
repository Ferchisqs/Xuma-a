// lib/features/challenges/presentation/cubit/challenges_cubit.dart - CORREGIDO CON USER ID REAL
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/user_challenge_stats_entity.dart';
import '../../domain/usecases/get_challenges_usecase.dart';
import '../../domain/usecases/get_user_challenge_stats_usecase.dart';
import '../../domain/usecases/get_challenge_categories_usecase.dart';
import '../../../learning/data/models/topic_model.dart';
import '../../../auth/domain/services/auth_service.dart'; // 🆕 IMPORT AUTH SERVICE

// ==================== STATES ACTUALIZADOS ====================

abstract class ChallengesState extends Equatable {
  const ChallengesState();

  @override
  List<Object?> get props => [];
}

class ChallengesInitial extends ChallengesState {}

class ChallengesLoading extends ChallengesState {}

class ChallengesLoaded extends ChallengesState {
  final List<ChallengeEntity> allChallenges;
  final List<ChallengeEntity> activeChallenges;
  final UserChallengeStatsEntity userStats;
  final List<TopicModel> categories;
  final ChallengeType? currentFilter;
  final String? currentCategory;

  const ChallengesLoaded({
    required this.allChallenges,
    required this.activeChallenges,
    required this.userStats,
    required this.categories,
    this.currentFilter,
    this.currentCategory,
  });

  List<ChallengeEntity> get filteredChallenges {
    var filtered = allChallenges;
    
    // Filtrar por tipo
    if (currentFilter != null) {
      filtered = filtered.where((c) => c.type == currentFilter).toList();
    }
    
    // Filtrar por categoría
    if (currentCategory != null && currentCategory!.isNotEmpty) {
      filtered = filtered.where((c) => 
        c.category.toLowerCase() == currentCategory!.toLowerCase()).toList();
    }
    
    return filtered;
  }

  List<ChallengeEntity> get dailyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.daily).toList();
  
  List<ChallengeEntity> get weeklyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.weekly).toList();
  
  List<ChallengeEntity> get monthlyChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.monthly).toList();

  List<ChallengeEntity> get specialChallenges => 
      allChallenges.where((c) => c.type == ChallengeType.special).toList();

  @override
  List<Object?> get props => [
    allChallenges, 
    activeChallenges, 
    userStats, 
    categories,
    currentFilter,
    currentCategory,
  ];
}

class ChallengesError extends ChallengesState {
  final String message;

  const ChallengesError({required this.message});

  @override
  List<Object> get props => [message];
}

class ChallengesRefreshing extends ChallengesLoaded {
  const ChallengesRefreshing({
    required List<ChallengeEntity> allChallenges,
    required List<ChallengeEntity> activeChallenges,
    required UserChallengeStatsEntity userStats,
    required List<TopicModel> categories,
    ChallengeType? currentFilter,
    String? currentCategory,
  }) : super(
    allChallenges: allChallenges,
    activeChallenges: activeChallenges,
    userStats: userStats,
    categories: categories,
    currentFilter: currentFilter,
    currentCategory: currentCategory,
  );
}

// 🆕 ESTADO PARA FALTA DE AUTENTICACIÓN
class ChallengesNotAuthenticated extends ChallengesState {
  final String message;

  const ChallengesNotAuthenticated({
    this.message = 'Inicia sesión para ver tus estadísticas de desafíos',
  });

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ACTUALIZADO ====================

@injectable
class ChallengesCubit extends Cubit<ChallengesState> {
  final GetChallengesUseCase getChallengesUseCase;
  final GetUserChallengeStatsUseCase getUserStatsUseCase;
  final GetChallengeCategoriesUseCase getCategoriesUseCase;
  final AuthService authService; // 🆕 AUTH SERVICE

  ChallengesCubit({
    required this.getChallengesUseCase,
    required this.getUserStatsUseCase,
    required this.getCategoriesUseCase,
    required this.authService, // 🆕 INYECCIÓN DE AUTH SERVICE
  }) : super(ChallengesInitial()) {
    print('✅ [CHALLENGES CUBIT] Constructor - Now using REAL API endpoints with real user authentication');
  }

  Future<void> loadChallenges({
    ChallengeType? type,
    String? category,
  }) async {
    try {
      print('🎯 [CHALLENGES CUBIT] === LOADING CHALLENGES FROM REAL API ===');
      print('🎯 [CHALLENGES CUBIT] Type: $type, Category: $category');

      emit(ChallengesLoading());

      // 🔧 VERIFICAR SI EL USUARIO ESTÁ AUTENTICADO
      final isAuthenticated = await _isUserAuthenticated();
      final currentUserId = await _getCurrentUserId();

      // Cargar challenges (estos son públicos, no requieren autenticación)
      final challengesResult = await getChallengesUseCase(
        GetChallengesParams(type: type, category: category)
      );

      // Cargar estadísticas del usuario (solo si está autenticado)
      UserChallengeStatsEntity stats = _createDefaultStats();
      if (isAuthenticated && currentUserId != null) {
        final statsResult = await getUserStatsUseCase(
          GetUserChallengeStatsParams(userId: currentUserId) // 🔧 USER ID REAL
        );
        
        statsResult.fold(
          (failure) {
            print('⚠️ [CHALLENGES CUBIT] Failed to load user stats: ${failure.message}');
            stats = _createDefaultStats();
          },
          (loadedStats) {
            stats = loadedStats as UserChallengeStatsEntity;
            print('✅ [CHALLENGES CUBIT] Loaded user stats from REAL API');
          },
        );
      } else {
        print('ℹ️ [CHALLENGES CUBIT] User not authenticated, using default stats');
      }

      // Cargar categorías
      final categoriesResult = await getCategoriesUseCase();

      // Procesar resultados
      List<ChallengeEntity> challenges = [];
      List<TopicModel> categories = [];

      // Manejar challenges
      challengesResult.fold(
        (failure) {
          print('⚠️ [CHALLENGES CUBIT] Failed to load challenges: ${failure.message}');
          challenges = [];
        },
        (loadedChallenges) {
          challenges = loadedChallenges as List<ChallengeEntity>;
          print('✅ [CHALLENGES CUBIT] Loaded ${challenges.length} challenges from REAL API');
        },
      );

      // Manejar categorías
      categoriesResult.fold(
        (failure) {
          print('⚠️ [CHALLENGES CUBIT] Failed to load categories: ${failure.message}');
          categories = [];
        },
        (loadedCategories) {
          categories = loadedCategories as List<TopicModel>;
          print('✅ [CHALLENGES CUBIT] Loaded ${categories.length} categories from REAL API');
        },
      );

      // Filtrar desafíos activos (solo para usuarios autenticados)
      List<ChallengeEntity> activeChallenges = [];
      if (isAuthenticated) {
        activeChallenges = challenges.where((c) => 
          c.isParticipating && c.isActive).toList();
      }

      emit(ChallengesLoaded(
        allChallenges: challenges,
        activeChallenges: activeChallenges,
        userStats: stats,
        categories: categories,
        currentFilter: type,
        currentCategory: category,
      ));
      
      print('🎉 [CHALLENGES CUBIT] Successfully loaded all data from REAL API');

    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Unexpected error: $e');
      emit(ChallengesError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> refreshChallenges() async {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      print('🔄 [CHALLENGES CUBIT] Refreshing challenges from REAL API');
      
      emit(ChallengesRefreshing(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        categories: currentState.categories,
        currentFilter: currentState.currentFilter,
        currentCategory: currentState.currentCategory,
      ));
      
      await loadChallenges(
        type: currentState.currentFilter,
        category: currentState.currentCategory,
      );
    } else {
      await loadChallenges();
    }
  }

  void filterByType(ChallengeType? type) {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      print('🔍 [CHALLENGES CUBIT] Filtering by type: $type');
      
      emit(ChallengesLoaded(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        categories: currentState.categories,
        currentFilter: type,
        currentCategory: currentState.currentCategory,
      ));
    }
  }

  void filterByCategory(String? category) {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      print('🔍 [CHALLENGES CUBIT] Filtering by category: $category');
      
      emit(ChallengesLoaded(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        categories: currentState.categories,
        currentFilter: currentState.currentFilter,
        currentCategory: category,
      ));
    }
  }

  void clearFilters() {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      print('🔄 [CHALLENGES CUBIT] Clearing all filters');
      
      emit(ChallengesLoaded(
        allChallenges: currentState.allChallenges,
        activeChallenges: currentState.activeChallenges,
        userStats: currentState.userStats,
        categories: currentState.categories,
        currentFilter: null,
        currentCategory: null,
      ));
    }
  }

  Future<void> loadActiveChallenges() async {
    try {
      print('🎯 [CHALLENGES CUBIT] Loading only active challenges');
      
      // 🔧 VERIFICAR AUTENTICACIÓN
      final isAuthenticated = await _isUserAuthenticated();
      if (!isAuthenticated) {
        emit(const ChallengesNotAuthenticated(
          message: 'Inicia sesión para ver tus desafíos activos',
        ));
        return;
      }
      
      final result = await getChallengesUseCase(
        const GetChallengesParams(), // Sin filtros para obtener todos
      );

      result.fold(
        (failure) {
          print('❌ [CHALLENGES CUBIT] Failed to load active challenges: ${failure.message}');
          emit(ChallengesError(message: failure.message));
        },
        (challenges) {
          final activeChallenges = challenges.where((c) => c.isActive).toList();
          print('✅ [CHALLENGES CUBIT] Loaded ${activeChallenges.length} active challenges');
          
          // Si ya tenemos un estado cargado, actualizar solo los challenges activos
          final currentState = state;
          if (currentState is ChallengesLoaded) {
            emit(ChallengesLoaded(
              allChallenges: challenges,
              activeChallenges: activeChallenges,
              userStats: currentState.userStats,
              categories: currentState.categories,
              currentFilter: currentState.currentFilter,
              currentCategory: currentState.currentCategory,
            ));
          }
        },
      );

    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Error loading active challenges: $e');
      emit(ChallengesError(message: 'Error cargando desafíos activos: ${e.toString()}'));
    }
  }

  Future<void> loadChallengesByCategory(String categoryId) async {
    try {
      print('🎯 [CHALLENGES CUBIT] Loading challenges for category: $categoryId');
      
      await loadChallenges(category: categoryId);
      
    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Error loading challenges by category: $e');
      emit(ChallengesError(message: 'Error cargando desafíos por categoría: ${e.toString()}'));
    }
  }

  void updateChallengeInList(ChallengeEntity updatedChallenge) {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      print('🔄 [CHALLENGES CUBIT] Updating challenge in list: ${updatedChallenge.id}');
      
      final updatedChallenges = currentState.allChallenges.map((challenge) {
        return challenge.id == updatedChallenge.id ? updatedChallenge : challenge;
      }).toList();

      final updatedActiveChallenges = updatedChallenges.where((c) => 
        c.isParticipating && c.isActive).toList();

      emit(ChallengesLoaded(
        allChallenges: updatedChallenges,
        activeChallenges: updatedActiveChallenges,
        userStats: currentState.userStats,
        categories: currentState.categories,
        currentFilter: currentState.currentFilter,
        currentCategory: currentState.currentCategory,
      ));
    }
  }

  // 🆕 MÉTODO PARA RECARGAR ESTADÍSTICAS DEL USUARIO
  Future<void> refreshUserStats() async {
    try {
      print('🔄 [CHALLENGES CUBIT] Refreshing user stats');
      
      // 🔧 VERIFICAR AUTENTICACIÓN Y OBTENER USER ID REAL
      final isAuthenticated = await _isUserAuthenticated();
      final currentUserId = await _getCurrentUserId();
      
      if (!isAuthenticated || currentUserId == null) {
        print('⚠️ [CHALLENGES CUBIT] User not authenticated for stats refresh');
        return;
      }

      final currentState = state;
      if (currentState is ChallengesLoaded) {
        final statsResult = await getUserStatsUseCase(
          GetUserChallengeStatsParams(userId: currentUserId) // 🔧 USER ID REAL
        );

        statsResult.fold(
          (failure) {
            print('❌ [CHALLENGES CUBIT] Failed to refresh user stats: ${failure.message}');
          },
          (newStats) {
            print('✅ [CHALLENGES CUBIT] User stats refreshed successfully');
            
            emit(ChallengesLoaded(
              allChallenges: currentState.allChallenges,
              activeChallenges: currentState.activeChallenges,
              userStats: newStats as UserChallengeStatsEntity,
              categories: currentState.categories,
              currentFilter: currentState.currentFilter,
              currentCategory: currentState.currentCategory,
            ));
          },
        );
      }
    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Error refreshing user stats: $e');
    }
  }

  // ==================== 🔧 MÉTODOS HELPER PARA AUTENTICACIÓN ====================
  
  /// Obtiene el user ID del usuario autenticado actual
  Future<String?> _getCurrentUserId() async {
    try {
      print('🔍 [CHALLENGES CUBIT] Getting current user ID...');
      
      final userResult = await authService.getCurrentUser();
      
      return userResult.fold(
        (failure) {
          print('❌ [CHALLENGES CUBIT] Failed to get current user: ${failure.message}');
          return null;
        },
        (user) {
          if (user != null) {
            print('✅ [CHALLENGES CUBIT] Current user ID: ${user.id}');
            return user.id;
          } else {
            print('⚠️ [CHALLENGES CUBIT] No authenticated user found');
            return null;
          }
        },
      );
    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Error getting current user ID: $e');
      return null;
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> _isUserAuthenticated() async {
    try {
      final isLoggedInResult = await authService.isLoggedIn();
      
      return isLoggedInResult.fold(
        (failure) {
          print('❌ [CHALLENGES CUBIT] Error checking authentication: ${failure.message}');
          return false;
        },
        (isLoggedIn) {
          print('🔍 [CHALLENGES CUBIT] User authenticated: $isLoggedIn');
          return isLoggedIn;
        },
      );
    } catch (e) {
      print('❌ [CHALLENGES CUBIT] Error checking authentication: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  UserChallengeStatsEntity _createDefaultStats() {
    return const UserChallengeStatsEntity(
      totalChallengesCompleted: 0,
      currentActiveChallenges: 0,
      totalPointsEarned: 0,
      currentStreak: 0,
      bestStreak: 0,
      currentRank: 'Eco Principiante',
      rankPosition: 1000,
      achievedBadges: [],
      categoryProgress: {},
      lastActivityDate: null,
    );
  }

  int get totalChallenges {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      return currentState.allChallenges.length;
    }
    return 0;
  }

  int get activeChallengesCount {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      return currentState.activeChallenges.length;
    }
    return 0;
  }

  int get completedChallengesCount {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      return currentState.allChallenges.where((c) => c.isCompleted).length;
    }
    return 0;
  }

  List<ChallengeEntity> getChallengesByCategory(String category) {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      return currentState.allChallenges.where((c) => 
        c.category.toLowerCase() == category.toLowerCase()).toList();
    }
    return [];
  }

  bool get hasCategories {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      return currentState.categories.isNotEmpty;
    }
    return false;
  }

  bool get isLoading => state is ChallengesLoading;
  bool get isRefreshing => state is ChallengesRefreshing;
  bool get hasError => state is ChallengesError;
  bool get isLoaded => state is ChallengesLoaded;
  bool get isNotAuthenticated => state is ChallengesNotAuthenticated;

  // 🆕 MÉTODO PARA MANEJAR REDIRECCIÓN A LOGIN
  void handleNotAuthenticated() {
    emit(const ChallengesNotAuthenticated(
      message: 'Inicia sesión para acceder a todas las funciones de desafíos',
    ));
  }

  // 🆕 MÉTODO PARA VERIFICAR PERMISOS ANTES DE CARGAR DATOS DE USUARIO
  Future<void> loadWithAuthCheck() async {
    final isAuthenticated = await _isUserAuthenticated();
    
    if (!isAuthenticated) {
      // Cargar solo challenges públicos sin estadísticas de usuario
      await loadChallenges();
    } else {
      // Cargar todo incluidas las estadísticas del usuario
      await loadChallenges();
    }
  }
}