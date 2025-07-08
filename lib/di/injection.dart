// lib/di/injection.dart - ACTUALIZACIÓN CORREGIDA
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

// Learning imports (existentes)
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

// 🆕 Challenges imports CORREGIDOS
import '../features/challenges/data/datasources/challenges_local_datasource.dart';
import '../features/challenges/data/datasources/challenges_remote_datasource.dart';
import '../features/challenges/data/repositories/challenges_repository_impl.dart';
import '../features/challenges/domain/repositories/challenges_repository.dart';
import '../features/challenges/domain/usecases/get_challenges_usecase.dart';
import '../features/challenges/domain/usecases/get_user_progress_usecase.dart'; // 🔧 CAMBIADO
import '../features/challenges/domain/usecases/start_challenge_usecase.dart'; // 🔧 CAMBIADO
import '../features/challenges/domain/usecases/complete_challenge_usecase.dart'; // 🔧 AGREGADO
import '../features/challenges/domain/usecases/update_challenge_progress_usecase.dart';
import '../features/challenges/presentation/cubit/challenges_cubit.dart';
import '../features/challenges/presentation/cubit/challenge_detail_cubit.dart';

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

// 🆕 Configuración de dependencias para Challenges CORREGIDA
void setupChallengesDependencies() {
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
        remoteDataSource: getIt(), // 🔧 CORREGIR parámetros nombrados
        localDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
  }
  
  // Use Cases
  if (!getIt.isRegistered<GetChallengesUseCase>()) {
    getIt.registerLazySingleton(() => GetChallengesUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<GetUserProgressUseCase>()) { // 🔧 CAMBIADO
    getIt.registerLazySingleton(() => GetUserProgressUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<StartChallengeUseCase>()) { // 🔧 CAMBIADO
    getIt.registerLazySingleton(() => StartChallengeUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<CompleteChallengeUseCase>()) { // 🔧 AGREGADO
    getIt.registerLazySingleton(() => CompleteChallengeUseCase(getIt()));
  }
  
  if (!getIt.isRegistered<UpdateChallengeProgressUseCase>()) {
    getIt.registerLazySingleton(() => UpdateChallengeProgressUseCase(getIt()));
  }
  
  // Cubits
  getIt.registerFactory(() => ChallengesCubit(
    getChallengesUseCase: getIt(),
    getUserProgressUseCase: getIt(), // 🔧 CAMBIADO
  ));
  
  getIt.registerFactory(() => ChallengeDetailCubit(
    startChallengeUseCase: getIt(), // 🔧 CAMBIADO
    completeChallengeUseCase: getIt(), // 🔧 AGREGADO
    updateChallengeProgressUseCase: getIt(),
  ));
}