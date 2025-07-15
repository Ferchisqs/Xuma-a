// lib/di/injection.dart - CON REGISTRO MANUAL TEMPORAL
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

// Existing imports...
import '../features/learning/data/datasources/learning_local_datasource.dart';
import '../features/learning/data/datasources/learning_remote_datasource.dart';
import '../features/learning/data/repositories/learning_repository_impl.dart';
import '../features/learning/domain/repositories/learning_repository.dart';
import '../features/learning/domain/usecases/get_categories_usecase.dart';
import '../features/learning/domain/usecases/get_lessons_by_category_usecase.dart';
import '../features/learning/domain/usecases/get_lesson_content_usecase.dart';
import '../features/learning/domain/usecases/update_lesson_progress_usecase.dart';
import '../features/learning/domain/usecases/complete_lesson_usecase.dart';
import '../features/learning/domain/usecases/search_lessons_usecase.dart';
import '../features/learning/presentation/cubit/learning_cubit.dart';
import '../features/learning/presentation/cubit/lesson_list_cubit.dart';
import '../features/learning/presentation/cubit/lesson_content_cubit.dart';

// 🆕 CONTENT IMPORTS PARA TOPICS Y CONTENIDOS
import '../features/learning/data/datasources/content_remote_datasource.dart';
import '../features/learning/data/repositories/content_repository_impl.dart';
import '../features/learning/domain/repositories/content_repository.dart';
import '../features/learning/domain/usecases/get_topics_usecase.dart';
import '../features/learning/domain/usecases/get_content_by_id_usecase.dart';
import '../features/learning/domain/usecases/get_contents_by_topic_usecase.dart'; // 🆕 NUEVO
import '../features/learning/presentation/cubit/content_cubit.dart';
import '../features/learning/presentation/cubit/topic_contents_cubit.dart'; // 🆕 NUEVO

// Challenges imports (existentes)
import '../features/challenges/data/datasources/challenges_local_datasource.dart';
import '../features/challenges/data/datasources/challenges_remote_datasource.dart';
import '../features/challenges/data/repositories/challenges_repository_impl.dart';
import '../features/challenges/domain/repositories/challenges_repository.dart';
import '../features/challenges/domain/usecases/get_challenges_usecase.dart';
import '../features/challenges/domain/usecases/get_user_progress_usecase.dart';
import '../features/challenges/domain/usecases/start_challenge_usecase.dart';
import '../features/challenges/domain/usecases/complete_challenge_usecase.dart';
import '../features/challenges/domain/usecases/update_challenge_progress_usecase.dart';
import '../features/challenges/presentation/cubit/challenges_cubit.dart';
import '../features/challenges/presentation/cubit/challenge_detail_cubit.dart';

// Tips imports (existentes)
import '../features/tips/data/datasources/tips_remote_datasource.dart';
import '../features/tips/data/repositories/tips_repository_impl.dart';
import '../features/tips/domain/repositories/tips_repository.dart';
import '../features/tips/domain/usecases/get_random_tip_usecase.dart';
import '../features/tips/presentation/cubit/tips_cubit.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

// ==================== CONTENT DEPENDENCIES (REGISTRO MANUAL) ====================

void setupContentDependencies() {
  print('🔧 [INJECTION] === STARTING CONTENT DEPENDENCIES SETUP (MANUAL) ===');
  
  try {
    // Data Sources
    if (!getIt.isRegistered<ContentRemoteDataSource>()) {
      getIt.registerLazySingleton<ContentRemoteDataSource>(
        () => ContentRemoteDataSourceImpl(getIt()),
      );
      print('✅ [INJECTION] ContentRemoteDataSource registered');
    }
    
    // Repository
    if (!getIt.isRegistered<ContentRepository>()) {
      getIt.registerLazySingleton<ContentRepository>(
        () => ContentRepositoryImpl(
          remoteDataSource: getIt(),
          localDataSource: getIt(),
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] ContentRepository registered');
    }
    
    // Use Cases - REGISTRO MANUAL
    if (!getIt.isRegistered<GetTopicsUseCase>()) {
      getIt.registerLazySingleton<GetTopicsUseCase>(
        () => GetTopicsUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetTopicsUseCase registered manually');
    }
    
    if (!getIt.isRegistered<GetContentByIdUseCase>()) {
      getIt.registerLazySingleton<GetContentByIdUseCase>(
        () => GetContentByIdUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentByIdUseCase registered manually');
    }
    
    // 🆕 REGISTRO MANUAL DEL NUEVO USE CASE
    if (!getIt.isRegistered<GetContentsByTopicUseCase>()) {
      print('🔧 [INJECTION] Manually registering GetContentsByTopicUseCase...');
      getIt.registerLazySingleton<GetContentsByTopicUseCase>(
        () => GetContentsByTopicUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentsByTopicUseCase registered manually');
    }
    
    // Cubits - REGISTRO MANUAL
    if (!getIt.isRegistered<ContentCubit>()) {
      getIt.registerFactory<ContentCubit>(
        () => ContentCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(),
          getContentByIdUseCase: getIt<GetContentByIdUseCase>(),
        ),
      );
      print('✅ [INJECTION] ContentCubit registered manually');
    }
    
    // 🆕 REGISTRO MANUAL DEL TOPIC CONTENTS CUBIT
    if (!getIt.isRegistered<TopicContentsCubit>()) {
      print('🔧 [INJECTION] Manually registering TopicContentsCubit...');
      print('🔧 [INJECTION] Dependencies check:');
      print('   - GetContentsByTopicUseCase: ${getIt.isRegistered<GetContentsByTopicUseCase>()}');
      
      getIt.registerFactory<TopicContentsCubit>(
        () {
          print('🏭 [INJECTION] Creating TopicContentsCubit instance manually...');
          return TopicContentsCubit(
            getContentsByTopicUseCase: getIt<GetContentsByTopicUseCase>(),
          );
        },
      );
      print('✅ [INJECTION] TopicContentsCubit registered manually as factory');
    }
    
    print('✅ [INJECTION] === CONTENT DEPENDENCIES SETUP COMPLETED ===');
    
    // 🔍 VERIFICACIÓN FINAL
    print('🔍 [INJECTION] Final verification...');
    print('🔍 GetContentsByTopicUseCase registered: ${getIt.isRegistered<GetContentsByTopicUseCase>()}');
    print('🔍 TopicContentsCubit registered: ${getIt.isRegistered<TopicContentsCubit>()}');
    
    // Test de resolución
    try {
      final testUseCase = getIt<GetContentsByTopicUseCase>();
      print('✅ [INJECTION] GetContentsByTopicUseCase can be resolved');
      
      final testCubit = getIt<TopicContentsCubit>();
      print('✅ [INJECTION] TopicContentsCubit can be resolved successfully');
      testCubit.close(); // Cerrar el cubit de prueba
    } catch (e) {
      print('❌ [INJECTION] ERROR resolving dependencies: $e');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] CRITICAL ERROR in setupContentDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== LEARNING DEPENDENCIES MODIFICADO ====================

void setupLearningDependencies() {
  print('🔧 [INJECTION] Setting up Learning dependencies...');
  
  // Data Sources (mantener existentes para compatibilidad)
  if (!getIt.isRegistered<LearningLocalDataSource>()) {
    getIt.registerLazySingleton<LearningLocalDataSource>(
      () => LearningLocalDataSourceImpl(getIt()),
    );
  }
  
  if (!getIt.isRegistered<LearningRemoteDataSource>()) {
    getIt.registerLazySingleton<LearningRemoteDataSource>(
      () => LearningRemoteDataSourceImpl(getIt()),
    );
  }
  
  // Repository (mantener existente)
  if (!getIt.isRegistered<LearningRepository>()) {
    getIt.registerLazySingleton<LearningRepository>(
      () => LearningRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }
  
  // Use Cases (mantener existentes para otras funcionalidades)
  if (!getIt.isRegistered<GetCategoriesUseCase>()) {
    getIt.registerLazySingleton(() => GetCategoriesUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<GetLessonsByCategoryUseCase>()) {
    getIt.registerLazySingleton(() => GetLessonsByCategoryUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<GetLessonContentUseCase>()) {
    getIt.registerLazySingleton(() => GetLessonContentUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<UpdateLessonProgressUseCase>()) {
    getIt.registerLazySingleton(() => UpdateLessonProgressUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<CompleteLessonUseCase>()) {
    getIt.registerLazySingleton(() => CompleteLessonUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<SearchLessonsUseCase>()) {
    getIt.registerLazySingleton(() => SearchLessonsUseCase(getIt()));
  }
  
  // 🔄 LEARNING CUBIT MODIFICADO - AHORA USA TOPICS
  getIt.registerFactory(() => LearningCubit(
    getTopicsUseCase: getIt<GetTopicsUseCase>(), // ESPECÍFICO PARA USAR TOPICS
  ));
  
  // Otros cubits mantienen su funcionalidad original
  getIt.registerFactory(() => LessonListCubit(
    getLessonsByCategoryUseCase: getIt(),
    searchLessonsUseCase: getIt(),
  ));
  
  getIt.registerFactory(() => LessonContentCubit(
    getLessonContentUseCase: getIt(),
    updateLessonProgressUseCase: getIt(),
    completeLessonUseCase: getIt(),
  ));
  
  print('✅ [INJECTION] Learning dependencies setup completed');
}

// ==================== CHALLENGES DEPENDENCIES (EXISTENTE) ====================

void setupChallengesDependencies() {
  print('🔧 [INJECTION] Setting up Challenges dependencies...');
  
  // Data Sources
  if (!getIt.isRegistered<ChallengesLocalDataSource>()) {
    getIt.registerLazySingleton<ChallengesLocalDataSource>(
      () => ChallengesLocalDataSourceImpl(getIt()),
    );
  }
  
  if (!getIt.isRegistered<ChallengesRemoteDataSource>()) {
    getIt.registerLazySingleton<ChallengesRemoteDataSource>(
      () => ChallengesRemoteDataSourceImpl(getIt()),
    );
  }
  
  // Repository
  if (!getIt.isRegistered<ChallengesRepository>()) {
    getIt.registerLazySingleton<ChallengesRepository>(
      () => ChallengesRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }
  
  // Use Cases
  if (!getIt.isRegistered<GetChallengesUseCase>()) {
    getIt.registerLazySingleton(() => GetChallengesUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<GetUserProgressUseCase>()) {
    getIt.registerLazySingleton(() => GetUserProgressUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<StartChallengeUseCase>()) {
    getIt.registerLazySingleton(() => StartChallengeUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<CompleteChallengeUseCase>()) {
    getIt.registerLazySingleton(() => CompleteChallengeUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<UpdateChallengeProgressUseCase>()) {
    getIt.registerLazySingleton(() => UpdateChallengeProgressUseCase(getIt()));
  }
  
  // Cubits
  getIt.registerFactory(() => ChallengesCubit(
    getChallengesUseCase: getIt(),
    getUserProgressUseCase: getIt(),
  ));
  
  getIt.registerFactory(() => ChallengeDetailCubit(
    startChallengeUseCase: getIt(),
    completeChallengeUseCase: getIt(),
    updateChallengeProgressUseCase: getIt(),
  ));
  
  print('✅ [INJECTION] Challenges dependencies setup completed');
}

// ==================== TIPS DEPENDENCIES (EXISTENTE) ====================

void setupTipsDependencies() {
  print('🔧 [INJECTION] Setting up Tips dependencies...');
  
  // Data Sources
  if (!getIt.isRegistered<TipsRemoteDataSource>()) {
    getIt.registerLazySingleton<TipsRemoteDataSource>(
      () => TipsRemoteDataSourceImpl(getIt()),
    );
    print('✅ [INJECTION] TipsRemoteDataSource registered');
  }
  
  // Repository
  if (!getIt.isRegistered<TipsRepository>()) {
    getIt.registerLazySingleton<TipsRepository>(
      () => TipsRepositoryImpl(
        getIt(), // TipsRemoteDataSource
        getIt(), // CacheService
      ),
    );
    print('✅ [INJECTION] TipsRepository registered');
  }
  
  // Use Cases
  if (!getIt.isRegistered<GetRandomTipUseCase>()) {
    getIt.registerLazySingleton(() => GetRandomTipUseCase(getIt()));
    print('✅ [INJECTION] GetRandomTipUseCase registered');
  }
  
  // Cubit
  getIt.registerFactory(() => TipsCubit(getIt()));
  print('✅ [INJECTION] TipsCubit registered');
  
  print('✅ [INJECTION] Tips dependencies setup completed');
}

// ==================== DEBUG HELPER ====================

void debugDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY DEBUG ===');
  
  // Content dependencies (para topics)
  print('🔍 [INJECTION] ContentRemoteDataSource: ${getIt.isRegistered<ContentRemoteDataSource>()}');
  print('🔍 [INJECTION] ContentRepository: ${getIt.isRegistered<ContentRepository>()}');
  print('🔍 [INJECTION] GetTopicsUseCase: ${getIt.isRegistered<GetTopicsUseCase>()}');
  print('🔍 [INJECTION] GetContentByIdUseCase: ${getIt.isRegistered<GetContentByIdUseCase>()}');
  print('🔍 [INJECTION] GetContentsByTopicUseCase: ${getIt.isRegistered<GetContentsByTopicUseCase>()}'); // 🆕
  print('🔍 [INJECTION] ContentCubit: ${getIt.isRegistered<ContentCubit>()}');
  print('🔍 [INJECTION] TopicContentsCubit: ${getIt.isRegistered<TopicContentsCubit>()}'); // 🆕
  
  // Learning dependencies (modificado para usar topics)
  print('🔍 [INJECTION] LearningRepository: ${getIt.isRegistered<LearningRepository>()}');
  print('🔍 [INJECTION] LearningCubit: ${getIt.isRegistered<LearningCubit>()}');
  
  // Tips dependencies
  print('🔍 [INJECTION] TipsRemoteDataSource: ${getIt.isRegistered<TipsRemoteDataSource>()}');
  print('🔍 [INJECTION] TipsRepository: ${getIt.isRegistered<TipsRepository>()}');
  print('🔍 [INJECTION] GetRandomTipUseCase: ${getIt.isRegistered<GetRandomTipUseCase>()}');
  print('🔍 [INJECTION] TipsCubit: ${getIt.isRegistered<TipsCubit>()}');
  
  print('🔍 [INJECTION] === END DEBUG ===');
}

// ==================== CLEANUP ====================

void clearAllDependencies() {
  getIt.reset();
  print('🧹 [INJECTION] All dependencies cleared');
}