// lib/features/learning/presentation/cubit/topic_contents_cubit.dart - CORREGIDO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/usecases/get_contents_by_topic_usecase.dart';

// States
abstract class TopicContentsState extends Equatable {
  const TopicContentsState();

  @override
  List<Object?> get props => [];
}

class TopicContentsInitial extends TopicContentsState {}

class TopicContentsLoading extends TopicContentsState {}

class TopicContentsLoaded extends TopicContentsState {
  final TopicEntity topic;
  final List<ContentEntity> contents;
  final int currentPage;
  final int limit;
  final bool hasMorePages;
  final bool isLoadingMore;

  const TopicContentsLoaded({
    required this.topic,
    required this.contents,
    required this.currentPage,
    required this.limit,
    required this.hasMorePages,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [
        topic,
        contents,
        currentPage,
        limit,
        hasMorePages,
        isLoadingMore,
      ];

  TopicContentsLoaded copyWith({
    TopicEntity? topic,
    List<ContentEntity>? contents,
    int? currentPage,
    int? limit,
    bool? hasMorePages,
    bool? isLoadingMore,
  }) {
    return TopicContentsLoaded(
      topic: topic ?? this.topic,
      contents: contents ?? this.contents,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TopicContentsError extends TopicContentsState {
  final String message;

  const TopicContentsError({required this.message});

  @override
  List<Object> get props => [message];
}

// 🔧 CUBIT SIN @injectable - REGISTRO MANUAL EN injection.dart
class TopicContentsCubit extends Cubit<TopicContentsState> {
  final GetContentsByTopicUseCase getContentsByTopicUseCase;

  TopicContentsCubit({
    required this.getContentsByTopicUseCase,
  }) : super(TopicContentsInitial()) {
    print('✅ [TOPIC CONTENTS CUBIT] Constructor called - Cubit created successfully');
    print('✅ [TOPIC CONTENTS CUBIT] UseCase type: ${getContentsByTopicUseCase.runtimeType}');
  }

  // Cargar contenidos de un topic (primera página)
  Future<void> loadTopicContents(TopicEntity topic, {int limit = 10}) async {
    print('🎯 [TOPIC CONTENTS CUBIT] Loading contents for topic: ${topic.title} (ID: ${topic.id})');
    emit(TopicContentsLoading());

    try {
      final result = await getContentsByTopicUseCase(
        GetContentsByTopicParams(
          topicId: topic.id,
          page: 1,
          limit: limit,
        ),
      );

      result.fold(
        (failure) {
          print('❌ [TOPIC CONTENTS CUBIT] Failed to load contents: ${failure.message}');
          emit(TopicContentsError(message: failure.message));
        },
        (contents) {
          print('✅ [TOPIC CONTENTS CUBIT] Loaded ${contents.length} contents for topic: ${topic.title}');
          emit(TopicContentsLoaded(
            topic: topic,
            contents: contents,
            currentPage: 1,
            limit: limit,
            hasMorePages: contents.length == limit, // Si recibimos todos los que pedimos, probablemente hay más
          ));
        },
      );
    } catch (e, stackTrace) {
      print('❌ [TOPIC CONTENTS CUBIT] Exception loading contents: $e');
      print('❌ [TOPIC CONTENTS CUBIT] Stack trace: $stackTrace');
      emit(TopicContentsError(message: 'Error inesperado al cargar contenidos: $e'));
    }
  }

  // Cargar más contenidos (paginación)
  Future<void> loadMoreContents() async {
    final currentState = state;
    if (currentState is! TopicContentsLoaded || 
        currentState.isLoadingMore || 
        !currentState.hasMorePages) {
      print('ℹ️ [TOPIC CONTENTS CUBIT] Skipping loadMoreContents - Invalid state or already loading');
      return;
    }

    print('🎯 [TOPIC CONTENTS CUBIT] Loading more contents (page ${currentState.currentPage + 1})');
    
    // Mostrar indicador de carga
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await getContentsByTopicUseCase(
        GetContentsByTopicParams(
          topicId: currentState.topic.id,
          page: currentState.currentPage + 1,
          limit: currentState.limit,
        ),
      );

      result.fold(
        (failure) {
          print('❌ [TOPIC CONTENTS CUBIT] Failed to load more contents: ${failure.message}');
          // Mantener el estado actual pero quitar el loading
          emit(currentState.copyWith(isLoadingMore: false));
        },
        (newContents) {
          print('✅ [TOPIC CONTENTS CUBIT] Loaded ${newContents.length} more contents');
          
          // Combinar contenidos existentes con los nuevos
          final allContents = List<ContentEntity>.from(currentState.contents)
            ..addAll(newContents);

          emit(TopicContentsLoaded(
            topic: currentState.topic,
            contents: allContents,
            currentPage: currentState.currentPage + 1,
            limit: currentState.limit,
            hasMorePages: newContents.length == currentState.limit, // Si recibimos todos los que pedimos, hay más
            isLoadingMore: false,
          ));
        },
      );
    } catch (e, stackTrace) {
      print('❌ [TOPIC CONTENTS CUBIT] Exception loading more contents: $e');
      print('❌ [TOPIC CONTENTS CUBIT] Stack trace: $stackTrace');
      // Mantener el estado actual pero quitar el loading
      final currentState = state;
      if (currentState is TopicContentsLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  // Refrescar contenidos
  Future<void> refreshContents() async {
    final currentState = state;
    if (currentState is TopicContentsLoaded) {
      print('🔄 [TOPIC CONTENTS CUBIT] Refreshing contents for topic: ${currentState.topic.title}');
      await loadTopicContents(currentState.topic, limit: currentState.limit);
    } else {
      print('ℹ️ [TOPIC CONTENTS CUBIT] Cannot refresh - No topic loaded');
    }
  }

  // Buscar contenido específico en la lista actual
  ContentEntity? findContentById(String contentId) {
    final currentState = state;
    if (currentState is TopicContentsLoaded) {
      try {
        return currentState.contents.firstWhere((content) => content.id == contentId);
      } catch (e) {
        print('⚠️ [TOPIC CONTENTS CUBIT] Content not found: $contentId');
        return null;
      }
    }
    return null;
  }

  // Obtener información del estado actual
  Map<String, dynamic> getCurrentInfo() {
    final currentState = state;
    if (currentState is TopicContentsLoaded) {
      return {
        'topic': currentState.topic.title,
        'topicId': currentState.topic.id,
        'totalContents': currentState.contents.length,
        'currentPage': currentState.currentPage,
        'hasMorePages': currentState.hasMorePages,
        'isLoadingMore': currentState.isLoadingMore,
        'limit': currentState.limit,
      };
    }
    return {'state': state.runtimeType.toString()};
  }

  @override
  void onChange(Change<TopicContentsState> change) {
    super.onChange(change);
    print('🔄 [TOPIC CONTENTS CUBIT] State changed: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
  }

  @override
  Future<void> close() {
    print('🔚 [TOPIC CONTENTS CUBIT] Closing cubit');
    return super.close();
  }
}