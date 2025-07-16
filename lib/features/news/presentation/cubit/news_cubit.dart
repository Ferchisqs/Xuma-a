// lib/features/news/presentation/cubit/news_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/news_entity.dart';
import '../../domain/usecases/get_climate_news_usecase.dart';
import '../../domain/usecases/get_cached_news_usecase.dart';
import '../../domain/usecases/refresh_news_usecase.dart';

// States
abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {
  final String? message;
  
  const NewsLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class NewsLoaded extends NewsState {
  final List<NewsEntity> news;
  final bool isFromCache;
  final bool hasReachedMax;
  final int currentPage;

  const NewsLoaded({
    required this.news,
    this.isFromCache = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [news, isFromCache, hasReachedMax, currentPage];

  NewsLoaded copyWith({
    List<NewsEntity>? news,
    bool? isFromCache,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return NewsLoaded(
      news: news ?? this.news,
      isFromCache: isFromCache ?? this.isFromCache,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class NewsRefreshing extends NewsLoaded {
  const NewsRefreshing({
    required List<NewsEntity> news,
    bool isFromCache = false,
    bool hasReachedMax = false,
    int currentPage = 1,
  }) : super(
    news: news,
    isFromCache: isFromCache,
    hasReachedMax: hasReachedMax,
    currentPage: currentPage,
  );
}

class NewsLoadingMore extends NewsLoaded {
  const NewsLoadingMore({
    required List<NewsEntity> news,
    bool isFromCache = false,
    bool hasReachedMax = false,
    int currentPage = 1,
  }) : super(
    news: news,
    isFromCache: isFromCache,
    hasReachedMax: hasReachedMax,
    currentPage: currentPage,
  );
}

class NewsError extends NewsState {
  final String message;
  final List<NewsEntity>? cachedNews;

  const NewsError({
    required this.message,
    this.cachedNews,
  });

  @override
  List<Object?> get props => [message, cachedNews];
}

// Cubit
@injectable
class NewsCubit extends Cubit<NewsState> {
  final GetClimateNewsUseCase _getClimateNewsUseCase;
  final GetCachedNewsUseCase _getCachedNewsUseCase;
  final RefreshNewsUseCase _refreshNewsUseCase;

  NewsCubit({
    required GetClimateNewsUseCase getClimateNewsUseCase,
    required GetCachedNewsUseCase getCachedNewsUseCase,
    required RefreshNewsUseCase refreshNewsUseCase,
  })  : _getClimateNewsUseCase = getClimateNewsUseCase,
        _getCachedNewsUseCase = getCachedNewsUseCase,
        _refreshNewsUseCase = refreshNewsUseCase,
        super(NewsInitial());

  // Cargar noticias iniciales
  Future<void> loadNews() async {
    emit(const NewsLoading(message: 'Cargando noticias...'));
    
    final result = await _getClimateNewsUseCase.call(
      const GetClimateNewsParams(page: 1, limit: 20),
    );
    
    result.fold(
      (failure) async {
        print('❌ [NEWS CUBIT] Error loading news: ${failure.message}');
        
        // Intentar cargar noticias del cache como fallback
        final cachedResult = await _getCachedNewsUseCase.call();
        cachedResult.fold(
          (cacheFailure) {
            emit(NewsError(message: failure.message));
          },
          (cachedNews) {
            if (cachedNews.isNotEmpty) {
              emit(NewsLoaded(
                news: cachedNews,
                isFromCache: true,
                currentPage: 1,
              ));
            } else {
              emit(NewsError(message: failure.message));
            }
          },
        );
      },
      (news) {
        print('✅ [NEWS CUBIT] News loaded successfully: ${news.length} articles');
        emit(NewsLoaded(
          news: news,
          isFromCache: false,
          hasReachedMax: news.length < 20,
          currentPage: 1,
        ));
      },
    );
  }

  // Refrescar noticias
  Future<void> refreshNews() async {
    if (state is NewsLoaded) {
      final currentState = state as NewsLoaded;
      emit(NewsRefreshing(
        news: currentState.news,
        isFromCache: currentState.isFromCache,
        hasReachedMax: currentState.hasReachedMax,
        currentPage: currentState.currentPage,
      ));
    } else {
      emit(const NewsLoading(message: 'Actualizando noticias...'));
    }
    
    final refreshResult = await _refreshNewsUseCase.call();
    
    refreshResult.fold(
      (failure) {
        print('❌ [NEWS CUBIT] Error refreshing news: ${failure.message}');
        
        if (state is NewsRefreshing) {
          final currentState = state as NewsRefreshing;
          emit(currentState.copyWith()); // Volver al estado normal
        } else {
          emit(NewsError(message: failure.message));
        }
      },
      (success) async {
        // Después de refrescar, cargar las nuevas noticias
        final result = await _getClimateNewsUseCase.call(
          const GetClimateNewsParams(page: 1, limit: 20),
        );
        
        result.fold(
          (failure) {
            emit(NewsError(message: failure.message));
          },
          (news) {
            print('✅ [NEWS CUBIT] News refreshed successfully: ${news.length} articles');
            emit(NewsLoaded(
              news: news,
              isFromCache: false,
              hasReachedMax: news.length < 20,
              currentPage: 1,
            ));
          },
        );
      },
    );
  }

  // Cargar más noticias (paginación)
  Future<void> loadMoreNews() async {
    if (state is! NewsLoaded) return;
    
    final currentState = state as NewsLoaded;
    
    if (currentState.hasReachedMax) {
      print('📄 [NEWS CUBIT] Already reached max pages');
      return;
    }
    
    emit(NewsLoadingMore(
      news: currentState.news,
      isFromCache: currentState.isFromCache,
      hasReachedMax: currentState.hasReachedMax,
      currentPage: currentState.currentPage,
    ));
    
    final nextPage = currentState.currentPage + 1;
    
    final result = await _getClimateNewsUseCase.call(
      GetClimateNewsParams(page: nextPage, limit: 20),
    );
    
    result.fold(
      (failure) {
        print('❌ [NEWS CUBIT] Error loading more news: ${failure.message}');
        emit(currentState.copyWith()); // Volver al estado anterior
      },
      (newNews) {
        final allNews = [...currentState.news, ...newNews];
        
        print('✅ [NEWS CUBIT] More news loaded: ${newNews.length} new articles, total: ${allNews.length}');
        
        emit(NewsLoaded(
          news: allNews,
          isFromCache: false,
          hasReachedMax: newNews.length < 20,
          currentPage: nextPage,
        ));
      },
    );
  }

  // Cargar solo noticias del cache
  Future<void> loadCachedNews() async {
    emit(const NewsLoading(message: 'Cargando noticias guardadas...'));
    
    final result = await _getCachedNewsUseCase.call();
    
    result.fold(
      (failure) {
        emit(NewsError(message: failure.message));
      },
      (cachedNews) {
        if (cachedNews.isNotEmpty) {
          print('✅ [NEWS CUBIT] Cached news loaded: ${cachedNews.length} articles');
          emit(NewsLoaded(
            news: cachedNews,
            isFromCache: true,
            currentPage: 1,
          ));
        } else {
          emit(const NewsError(message: 'No hay noticias guardadas'));
        }
      },
    );
  }

  // Retry cuando hay error
  Future<void> retry() async {
    await loadNews();
  }

  // Helper methods
  bool get hasNews => state is NewsLoaded && (state as NewsLoaded).news.isNotEmpty;
  
  List<NewsEntity> get currentNews {
    if (state is NewsLoaded) {
      return (state as NewsLoaded).news;
    }
    return [];
  }
  
  bool get isLoading => state is NewsLoading;
  bool get isRefreshing => state is NewsRefreshing;
  bool get isLoadingMore => state is NewsLoadingMore;
  bool get hasError => state is NewsError;
  
  void debugCurrentState() {
    print('🔍 [NEWS CUBIT] Current state: ${state.runtimeType}');
    if (state is NewsLoaded) {
      final loadedState = state as NewsLoaded;
      print('   - Articles: ${loadedState.news.length}');
      print('   - From cache: ${loadedState.isFromCache}');
      print('   - Current page: ${loadedState.currentPage}');
      print('   - Has reached max: ${loadedState.hasReachedMax}');
    }
  }
}