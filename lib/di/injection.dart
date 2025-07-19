// lib/di/injection.dart - DEPENDENCY INJECTION CORREGIDO PARA MEDIA
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

// ✅ IMPORTACIÓN CRÍTICA - API CLIENT
import '../core/network/api_client.dart';

// Content imports
import '../features/learning/data/datasources/content_remote_datasource.dart';
import '../features/learning/data/repositories/content_repository_impl.dart';
import '../features/learning/domain/repositories/content_repository.dart';
import '../features/learning/domain/usecases/get_topics_usecase.dart';
import '../features/learning/domain/usecases/get_content_by_id_usecase.dart';
import '../features/learning/domain/usecases/get_contents_by_topic_usecase.dart';
import '../features/learning/presentation/cubit/content_cubit.dart';
import '../features/learning/presentation/cubit/topic_contents_cubit.dart';

// Learning imports (solo los necesarios - SIN LearningLocalDataSource)
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

// 🔧 IMPORTACIÓN CORREGIDA - MediaRemoteDataSource
import '../features/learning/data/datasources/media_remote_datasource.dart';

// News feature imports
import '../features/news/data/datasources/news_remote_datasource.dart';
import '../features/news/data/datasources/news_local_datasource.dart';
import '../features/news/data/repositories/news_repository_impl.dart';
import '../features/news/domain/repositories/news_repository.dart';
import '../features/news/domain/usecases/get_climate_news_usecase.dart';
import '../features/news/domain/usecases/get_cached_news_usecase.dart';
import '../features/news/domain/usecases/refresh_news_usecase.dart';
import '../features/news/presentation/cubit/news_cubit.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  print('🔧 [INJECTION] === STARTING DEPENDENCY CONFIGURATION ===');
  
  try {
    // 1. PRIMERO: Configurar dependencias básicas con @injectable
    print('🔧 [INJECTION] Step 1: Configuring auto-generated dependencies...');
    await getIt.init();
    print('✅ [INJECTION] Step 1: Auto-generated dependencies configured');
    
    // 2. SEGUNDO: Registrar MediaRemoteDataSource ANTES de usarlo
    print('🔧 [INJECTION] Step 2: Registering media dependencies...');
    _registerMediaDependencies();
    print('✅ [INJECTION] Step 2: Media dependencies registered');
    
    // 3. TERCERO: Registrar dependencias de contenido con media
    print('🔧 [INJECTION] Step 3: Registering content dependencies with media...');
    _registerContentDependencies();
    print('✅ [INJECTION] Step 3: Content dependencies registered');
    
    // 4. CUARTO: Registrar dependencias de learning modificadas
    print('🔧 [INJECTION] Step 4: Registering learning dependencies...');
    _registerLearningDependencies();
    print('✅ [INJECTION] Step 4: Learning dependencies registered');
    
    // 5. QUINTO: Registrar dependencias de news
    print('🔧 [INJECTION] Step 5: Registering news dependencies...');
    _registerNewsDependencies();
    print('✅ [INJECTION] Step 5: News dependencies registered');
    
    // 6. VERIFICACIÓN FINAL
    print('🔍 [INJECTION] Step 6: Final verification...');
    _verifyDependencies();
    print('✅ [INJECTION] Step 6: All dependencies verified');
    
    print('🎉 [INJECTION] === DEPENDENCY CONFIGURATION COMPLETED ===');
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] CRITICAL ERROR in configureDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== MEDIA DEPENDENCIES - PRIMERO ====================

void _registerMediaDependencies() {
  try {
    // 🆕 REGISTRAR MediaRemoteDataSource PRIMERO
    if (!getIt.isRegistered<MediaRemoteDataSource>()) {
      getIt.registerLazySingleton<MediaRemoteDataSource>(
        () => MediaRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] MediaRemoteDataSource registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerMediaDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== CONTENT DEPENDENCIES - CON MEDIA ====================

void _registerContentDependencies() {
  try {
    // Data Sources - AHORA CON MEDIA DEPENDENCY
    if (!getIt.isRegistered<ContentRemoteDataSource>()) {
      getIt.registerLazySingleton<ContentRemoteDataSource>(
        () => ContentRemoteDataSourceImpl(
          getIt<ApiClient>(),
          getIt<MediaRemoteDataSource>(), // 🆕 INYECTAR MEDIA DATASOURCE
        ),
      );
      print('✅ [INJECTION] ContentRemoteDataSource registered WITH MEDIA');
    }
    
    // Repository
    if (!getIt.isRegistered<ContentRepository>()) {
      getIt.registerLazySingleton<ContentRepository>(
        () => ContentRepositoryImpl(
          remoteDataSource: getIt<ContentRemoteDataSource>(),
          localDataSource: getIt(),
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] ContentRepository registered');
    }
    
    // Use Cases
    if (!getIt.isRegistered<GetTopicsUseCase>()) {
      getIt.registerLazySingleton<GetTopicsUseCase>(
        () => GetTopicsUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetTopicsUseCase registered');
    }
    
    if (!getIt.isRegistered<GetContentByIdUseCase>()) {
      getIt.registerLazySingleton<GetContentByIdUseCase>(
        () => GetContentByIdUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentByIdUseCase registered');
    }
    
    if (!getIt.isRegistered<GetContentsByTopicUseCase>()) {
      getIt.registerLazySingleton<GetContentsByTopicUseCase>(
        () => GetContentsByTopicUseCase(getIt<ContentRepository>()),
      );
      print('✅ [INJECTION] GetContentsByTopicUseCase registered');
    }
    
    // Cubits
    if (!getIt.isRegistered<ContentCubit>()) {
      getIt.registerFactory<ContentCubit>(
        () => ContentCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(),
          getContentByIdUseCase: getIt<GetContentByIdUseCase>(),
        ),
      );
      print('✅ [INJECTION] ContentCubit registered');
    }
    
    // 🎯 REGISTRO CRÍTICO: TopicContentsCubit
    if (!getIt.isRegistered<TopicContentsCubit>()) {
      getIt.registerFactory<TopicContentsCubit>(
        () {
          print('🏭 [INJECTION] Creating TopicContentsCubit instance...');
          return TopicContentsCubit(
            getContentsByTopicUseCase: getIt<GetContentsByTopicUseCase>(),
          );
        },
      );
      print('✅ [INJECTION] TopicContentsCubit registered as factory');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerContentDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== LEARNING DEPENDENCIES ====================

void _registerLearningDependencies() {
  try {
    // ⚠️ IMPORTANTE: NO registrar LearningLocalDataSource manualmente
    // Ya está registrado por @injectable en injection.config.dart
    
    // Data Sources - Solo remote
    if (!getIt.isRegistered<LearningRemoteDataSource>()) {
      getIt.registerLazySingleton<LearningRemoteDataSource>(
        () => LearningRemoteDataSourceImpl(getIt<ApiClient>()),
      );
      print('✅ [INJECTION] LearningRemoteDataSource registered');
    }
    
    // Repository
    if (!getIt.isRegistered<LearningRepository>()) {
      getIt.registerLazySingleton<LearningRepository>(
        () => LearningRepositoryImpl(
          remoteDataSource: getIt<LearningRemoteDataSource>(),
          localDataSource: getIt(), // Obtenido de injection.config.dart
          networkInfo: getIt(),
        ),
      );
      print('✅ [INJECTION] LearningRepository registered');
    }
    
    // Use Cases (solo si no están registrados por @injectable)
    if (!getIt.isRegistered<GetCategoriesUseCase>()) {
      getIt.registerLazySingleton<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetCategoriesUseCase registered');
    }
    
    if (!getIt.isRegistered<GetLessonsByCategoryUseCase>()) {
      getIt.registerLazySingleton<GetLessonsByCategoryUseCase>(
        () => GetLessonsByCategoryUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetLessonsByCategoryUseCase registered');
    }
    
    if (!getIt.isRegistered<GetLessonContentUseCase>()) {
      getIt.registerLazySingleton<GetLessonContentUseCase>(
        () => GetLessonContentUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] GetLessonContentUseCase registered');
    }
    
    if (!getIt.isRegistered<UpdateLessonProgressUseCase>()) {
      getIt.registerLazySingleton<UpdateLessonProgressUseCase>(
        () => UpdateLessonProgressUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] UpdateLessonProgressUseCase registered');
    }
    
    if (!getIt.isRegistered<CompleteLessonUseCase>()) {
      getIt.registerLazySingleton<CompleteLessonUseCase>(
        () => CompleteLessonUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] CompleteLessonUseCase registered');
    }
    
    if (!getIt.isRegistered<SearchLessonsUseCase>()) {
      getIt.registerLazySingleton<SearchLessonsUseCase>(
        () => SearchLessonsUseCase(getIt<LearningRepository>()),
      );
      print('✅ [INJECTION] SearchLessonsUseCase registered');
    }
    
    // Learning Cubit MODIFICADO para usar topics
    if (!getIt.isRegistered<LearningCubit>()) {
      getIt.registerFactory<LearningCubit>(
        () => LearningCubit(
          getTopicsUseCase: getIt<GetTopicsUseCase>(), // USA TOPICS EN LUGAR DE CATEGORIES
        ),
      );
      print('✅ [INJECTION] LearningCubit registered (using topics)');
    }
    
    // Otros cubits
    if (!getIt.isRegistered<LessonListCubit>()) {
      getIt.registerFactory<LessonListCubit>(
        () => LessonListCubit(
          getLessonsByCategoryUseCase: getIt<GetLessonsByCategoryUseCase>(),
          searchLessonsUseCase: getIt<SearchLessonsUseCase>(),
        ),
      );
      print('✅ [INJECTION] LessonListCubit registered');
    }
    
    if (!getIt.isRegistered<LessonContentCubit>()) {
      getIt.registerFactory<LessonContentCubit>(
        () => LessonContentCubit(
          getLessonContentUseCase: getIt<GetLessonContentUseCase>(),
          updateLessonProgressUseCase: getIt<UpdateLessonProgressUseCase>(),
          completeLessonUseCase: getIt<CompleteLessonUseCase>(),
        ),
      );
      print('✅ [INJECTION] LessonContentCubit registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerLearningDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== NEWS DEPENDENCIES ====================

void _registerNewsDependencies() {
  try {
    // Data Sources
    if (!getIt.isRegistered<NewsRemoteDataSource>()) {
      getIt.registerLazySingleton<NewsRemoteDataSource>(
        () => NewsRemoteDataSourceImpl(),
      );
      print('✅ [INJECTION] NewsRemoteDataSource registered');
    }
    
    if (!getIt.isRegistered<NewsLocalDataSource>()) {
      getIt.registerLazySingleton<NewsLocalDataSource>(
        () => NewsLocalDataSourceImpl(getIt()), // CacheService desde injection.config.dart
      );
      print('✅ [INJECTION] NewsLocalDataSource registered');
    }
    
    // Repository
    if (!getIt.isRegistered<NewsRepository>()) {
      getIt.registerLazySingleton<NewsRepository>(
        () => NewsRepositoryImpl(
          getIt<NewsRemoteDataSource>(),
          getIt<NewsLocalDataSource>(),
          getIt(), // NetworkInfo desde injection.config.dart
        ),
      );
      print('✅ [INJECTION] NewsRepository registered');
    }
    
    // Use Cases
    if (!getIt.isRegistered<GetClimateNewsUseCase>()) {
      getIt.registerLazySingleton<GetClimateNewsUseCase>(
        () => GetClimateNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] GetClimateNewsUseCase registered');
    }
    
    if (!getIt.isRegistered<GetCachedNewsUseCase>()) {
      getIt.registerLazySingleton<GetCachedNewsUseCase>(
        () => GetCachedNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] GetCachedNewsUseCase registered');
    }
    
    if (!getIt.isRegistered<RefreshNewsUseCase>()) {
      getIt.registerLazySingleton<RefreshNewsUseCase>(
        () => RefreshNewsUseCase(getIt<NewsRepository>()),
      );
      print('✅ [INJECTION] RefreshNewsUseCase registered');
    }
    
    // Cubit
    if (!getIt.isRegistered<NewsCubit>()) {
      getIt.registerFactory<NewsCubit>(
        () => NewsCubit(
          getClimateNewsUseCase: getIt<GetClimateNewsUseCase>(),
          getCachedNewsUseCase: getIt<GetCachedNewsUseCase>(),
          refreshNewsUseCase: getIt<RefreshNewsUseCase>(),
        ),
      );
      print('✅ [INJECTION] NewsCubit registered');
    }
    
  } catch (e, stackTrace) {
    print('❌ [INJECTION] Error in _registerNewsDependencies: $e');
    print('❌ [INJECTION] Stack trace: $stackTrace');
    rethrow;
  }
}

// ==================== VERIFICATION ====================

void _verifyDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY VERIFICATION ===');
  
  // Verificar dependencias críticas
  final criticalDeps = [
    'ApiClient',
    'MediaRemoteDataSource', // 🔧 VERIFICAR PRIMERO
    'ContentRemoteDataSource',
    'ContentRepository', 
    'GetTopicsUseCase',
    'GetContentByIdUseCase',
    'GetContentsByTopicUseCase',
    'ContentCubit',
    'TopicContentsCubit', // CRÍTICO
    'LearningCubit',
    'NewsRemoteDataSource',
    'NewsLocalDataSource',
    'NewsRepository',
    'GetClimateNewsUseCase',
    'GetCachedNewsUseCase',
    'RefreshNewsUseCase',
    'NewsCubit',
  ];
  
  for (final dep in criticalDeps) {
    bool isRegistered = false;
    
    switch (dep) {
      case 'ApiClient':
        isRegistered = getIt.isRegistered<ApiClient>();
        break;
      case 'MediaRemoteDataSource': // 🆕 NUEVO
        isRegistered = getIt.isRegistered<MediaRemoteDataSource>();
        break;
      case 'ContentRemoteDataSource':
        isRegistered = getIt.isRegistered<ContentRemoteDataSource>();
        break;
      case 'ContentRepository':
        isRegistered = getIt.isRegistered<ContentRepository>();
        break;
      case 'GetTopicsUseCase':
        isRegistered = getIt.isRegistered<GetTopicsUseCase>();
        break;
      case 'GetContentByIdUseCase':
        isRegistered = getIt.isRegistered<GetContentByIdUseCase>();
        break;
      case 'GetContentsByTopicUseCase':
        isRegistered = getIt.isRegistered<GetContentsByTopicUseCase>();
        break;
      case 'ContentCubit':
        isRegistered = getIt.isRegistered<ContentCubit>();
        break;
      case 'TopicContentsCubit':
        isRegistered = getIt.isRegistered<TopicContentsCubit>();
        break;
      case 'LearningCubit':
        isRegistered = getIt.isRegistered<LearningCubit>();
        break;
      case 'NewsRemoteDataSource':
        isRegistered = getIt.isRegistered<NewsRemoteDataSource>();
        break;
      case 'NewsLocalDataSource':
        isRegistered = getIt.isRegistered<NewsLocalDataSource>();
        break;
      case 'NewsRepository':
        isRegistered = getIt.isRegistered<NewsRepository>();
        break;
      case 'GetClimateNewsUseCase':
        isRegistered = getIt.isRegistered<GetClimateNewsUseCase>();
        break;
      case 'GetCachedNewsUseCase':
        isRegistered = getIt.isRegistered<GetCachedNewsUseCase>();
        break;
      case 'RefreshNewsUseCase':
        isRegistered = getIt.isRegistered<RefreshNewsUseCase>();
        break;
      case 'NewsCubit':
        isRegistered = getIt.isRegistered<NewsCubit>();
        break;
    }
    
    if (isRegistered) {
      print('✅ [INJECTION] $dep: REGISTERED');
    } else {
      print('❌ [INJECTION] $dep: NOT REGISTERED');
      throw Exception('Critical dependency $dep is not registered');
    }
  }
  
  // Test de resolución para TopicContentsCubit
  try {
    final testCubit = getIt<TopicContentsCubit>();
    print('✅ [INJECTION] TopicContentsCubit can be resolved successfully');
    testCubit.close(); // Cerrar el cubit de prueba
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving TopicContentsCubit: $e');
    throw Exception('Cannot resolve TopicContentsCubit: $e');
  }
  
  // Test de resolución para NewsCubit
  try {
    final testNewsCubit = getIt<NewsCubit>();
    print('✅ [INJECTION] NewsCubit can be resolved successfully');
    testNewsCubit.close(); // Cerrar el cubit de prueba
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving NewsCubit: $e');
    throw Exception('Cannot resolve NewsCubit: $e');
  }
  
  // 🆕 Test de resolución para MediaRemoteDataSource
  try {
    final testMediaDataSource = getIt<MediaRemoteDataSource>();
    print('✅ [INJECTION] MediaRemoteDataSource can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving MediaRemoteDataSource: $e');
    throw Exception('Cannot resolve MediaRemoteDataSource: $e');
  }
  
  // 🆕 Test de resolución para ContentRemoteDataSource CON MEDIA
  try {
    final testContentDataSource = getIt<ContentRemoteDataSource>();
    print('✅ [INJECTION] ContentRemoteDataSource can be resolved successfully WITH MEDIA');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving ContentRemoteDataSource: $e');
    throw Exception('Cannot resolve ContentRemoteDataSource: $e');
  }
  
  // 🆕 TEST ESPECÍFICO PARA ENDPOINT DE MEDIA FILES
  try {
    final mediaDataSource = getIt<MediaRemoteDataSource>();
    print('🧪 [INJECTION] Testing media files endpoint resolution...');
    
    // Test con un ID de ejemplo (este fallará pero debe mostrar los logs correctos)
    mediaDataSource.getFileMediaResponse('test-file-id-123').then((response) {
      print('🧪 [INJECTION] Media test completed - Response: ${response?.toString() ?? "null"}');
    }).catchError((error) {
      print('🧪 [INJECTION] Media test completed with expected error: $error');
    });
    
    print('✅ [INJECTION] Media files endpoint test initiated');
  } catch (e) {
    print('❌ [INJECTION] ERROR in media files endpoint test: $e');
  }
  
  print('🔍 [INJECTION] === VERIFICATION COMPLETED ===');

  
  // Test de resolución para TopicContentsCubit
  try {
    final testCubit = getIt<TopicContentsCubit>();
    print('✅ [INJECTION] TopicContentsCubit can be resolved successfully');
    testCubit.close(); // Cerrar el cubit de prueba
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving TopicContentsCubit: $e');
    throw Exception('Cannot resolve TopicContentsCubit: $e');
  }
  
  // Test de resolución para NewsCubit
  try {
    final testNewsCubit = getIt<NewsCubit>();
    print('✅ [INJECTION] NewsCubit can be resolved successfully');
    testNewsCubit.close(); // Cerrar el cubit de prueba
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving NewsCubit: $e');
    throw Exception('Cannot resolve NewsCubit: $e');
  }
  
  // 🆕 Test de resolución para MediaRemoteDataSource
  try {
    final testMediaDataSource = getIt<MediaRemoteDataSource>();
    print('✅ [INJECTION] MediaRemoteDataSource can be resolved successfully');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving MediaRemoteDataSource: $e');
    throw Exception('Cannot resolve MediaRemoteDataSource: $e');
  }
  
  // 🆕 Test de resolución para ContentRemoteDataSource CON MEDIA
  try {
    final testContentDataSource = getIt<ContentRemoteDataSource>();
    print('✅ [INJECTION] ContentRemoteDataSource can be resolved successfully WITH MEDIA');
  } catch (e) {
    print('❌ [INJECTION] ERROR resolving ContentRemoteDataSource: $e');
    throw Exception('Cannot resolve ContentRemoteDataSource: $e');
  }
  
  print('🔍 [INJECTION] === VERIFICATION COMPLETED ===');
}

// ==================== DEBUG HELPERS ====================

void debugDependencies() {
  print('🔍 [INJECTION] === DEPENDENCY DEBUG ===');
  print('🔍 ApiClient: ${getIt.isRegistered<ApiClient>()}');
  print('🔍 MediaRemoteDataSource: ${getIt.isRegistered<MediaRemoteDataSource>()}'); // 🆕 NUEVO
  print('🔍 ContentRemoteDataSource: ${getIt.isRegistered<ContentRemoteDataSource>()}');
  print('🔍 ContentRepository: ${getIt.isRegistered<ContentRepository>()}');
  print('🔍 GetTopicsUseCase: ${getIt.isRegistered<GetTopicsUseCase>()}');
  print('🔍 GetContentByIdUseCase: ${getIt.isRegistered<GetContentByIdUseCase>()}');
  print('🔍 GetContentsByTopicUseCase: ${getIt.isRegistered<GetContentsByTopicUseCase>()}');
  print('🔍 ContentCubit: ${getIt.isRegistered<ContentCubit>()}');
  print('🔍 TopicContentsCubit: ${getIt.isRegistered<TopicContentsCubit>()}');
  print('🔍 LearningCubit: ${getIt.isRegistered<LearningCubit>()}');
  print('🔍 NewsRemoteDataSource: ${getIt.isRegistered<NewsRemoteDataSource>()}');
  print('🔍 NewsLocalDataSource: ${getIt.isRegistered<NewsLocalDataSource>()}');
  print('🔍 NewsRepository: ${getIt.isRegistered<NewsRepository>()}');
  print('🔍 GetClimateNewsUseCase: ${getIt.isRegistered<GetClimateNewsUseCase>()}');
  print('🔍 GetCachedNewsUseCase: ${getIt.isRegistered<GetCachedNewsUseCase>()}');
  print('🔍 RefreshNewsUseCase: ${getIt.isRegistered<RefreshNewsUseCase>()}');
  print('🔍 NewsCubit: ${getIt.isRegistered<NewsCubit>()}');
  print('🔍 [INJECTION] === END DEBUG ===');
}

void clearAllDependencies() {
  getIt.reset();
  print('🧹 [INJECTION] All dependencies cleared');
}