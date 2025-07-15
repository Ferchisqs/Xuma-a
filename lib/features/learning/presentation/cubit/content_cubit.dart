// lib/features/learning/presentation/cubit/content_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/content_entity.dart';
import '../../domain/usecases/get_topics_usecase.dart';
import '../../domain/usecases/get_content_by_id_usecase.dart';

// ==================== STATES ====================

abstract class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class TopicsLoaded extends ContentState {
  final List<TopicEntity> topics;

  const TopicsLoaded({required this.topics});

  @override
  List<Object> get props => [topics];
}

class ContentLoaded extends ContentState {
  final ContentEntity content;

  const ContentLoaded({required this.content});

  @override
  List<Object> get props => [content];
}

class ContentError extends ContentState {
  final String message;

  const ContentError({required this.message});

  @override
  List<Object> get props => [message];
}

// ==================== CUBIT ====================

@injectable
class ContentCubit extends Cubit<ContentState> {
  final GetTopicsUseCase getTopicsUseCase;
  final GetContentByIdUseCase getContentByIdUseCase;

  ContentCubit({
    required this.getTopicsUseCase,
    required this.getContentByIdUseCase,
  }) : super(ContentInitial());

  // ==================== LOAD TOPICS ====================
  
  Future<void> loadTopics() async {
    print('🎯 [CONTENT CUBIT] Loading topics...');
    emit(ContentLoading());

    final result = await getTopicsUseCase(NoParams());

    result.fold(
      (failure) {
        print('❌ [CONTENT CUBIT] Failed to load topics: ${failure.message}');
        emit(ContentError(message: failure.message));
      },
      (topics) {
        print('✅ [CONTENT CUBIT] Loaded ${topics.length} topics');
        emit(TopicsLoaded(topics: topics));
      },
    );
  }

  // ==================== LOAD CONTENT BY ID ====================
  
  Future<void> loadContentById(String id) async {
    print('🎯 [CONTENT CUBIT] Loading content by ID: $id');
    emit(ContentLoading());

    final result = await getContentByIdUseCase(GetContentByIdParams(id: id));

    result.fold(
      (failure) {
        print('❌ [CONTENT CUBIT] Failed to load content: ${failure.message}');
        emit(ContentError(message: failure.message));
      },
      (content) {
        print('✅ [CONTENT CUBIT] Loaded content: ${content.title}');
        emit(ContentLoaded(content: content));
      },
    );
  }

  // ==================== HELPERS ====================
  
  void refreshTopics() => loadTopics();
  
  void reset() => emit(ContentInitial());
}