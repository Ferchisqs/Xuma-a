import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

// Learning imports
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

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

// Configuración manual adicional si es necesaria
void setupLearningDependencies() {
  // Data Sources
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
  
  // Repository
  if (!getIt.isRegistered<LearningRepository>()) {
    getIt.registerLazySingleton<LearningRepository>(
      () => LearningRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }
  
  // Use Cases
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
  
  // Cubits
  getIt.registerFactory(() => LearningCubit(getCategoriesUseCase: getIt()));
  
  getIt.registerFactory(() => LessonListCubit(
    getLessonsByCategoryUseCase: getIt(),
    searchLessonsUseCase: getIt(),
  ));
  
  getIt.registerFactory(() => LessonContentCubit(
    getLessonContentUseCase: getIt(),
    updateLessonProgressUseCase: getIt(),
    completeLessonUseCase: getIt(),
  ));
}