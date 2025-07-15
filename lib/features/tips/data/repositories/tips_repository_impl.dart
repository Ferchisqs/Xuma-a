// lib/features/tips/data/repositories/tips_repository_impl.dart
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/services/cache_service.dart';
import '../../domain/entities/tip_entity.dart';
import '../../domain/repositories/tips_repository.dart';
import '../datasources/tips_remote_datasource.dart';
import '../models/tip_model.dart';
import 'dart:math';

@LazySingleton(as: TipsRepository)
class TipsRepositoryImpl implements TipsRepository {
  final TipsRemoteDataSource _remoteDataSource;
  final CacheService _cacheService;
  
  // Cache keys
  static const String _allTipsCacheKey = 'cached_all_tips';
  static const String _tipsCachePrefix = 'cached_tip_';
  
  // Cache duration
  static const Duration _cacheDuration = Duration(hours: 6);

  TipsRepositoryImpl(
    this._remoteDataSource,
    this._cacheService,
  );

  @override
  Future<Either<Failure, List<TipEntity>>> getAllTips({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('📚 [TIPS REPO] Getting all tips...');
      
      // Intentar obtener desde la API
      try {
        final tips = await _remoteDataSource.getAllTips(page: page, limit: limit);
        print('✅ [TIPS REPO] Got ${tips.length} tips from API');
        
        // Guardar en caché
        await _cacheService.setList(
          _allTipsCacheKey,
          tips.map((tip) => tip.toJson()).toList(),
          duration: _cacheDuration,
        );
        print('💾 [TIPS REPO] Tips cached successfully');
        
        return Right(tips.cast<TipEntity>());
      } catch (e) {
        print('⚠️ [TIPS REPO] API failed, trying cache: $e');
        
        // Si falla la API, intentar caché
        final cachedTips = await getCachedTips();
        return cachedTips.fold(
          (failure) {
            print('❌ [TIPS REPO] Cache also failed, using fallback');
            return Right(_getFallbackTips());
          },
          (tips) {
            print('✅ [TIPS REPO] Using cached tips: ${tips.length}');
            return Right(tips);
          },
        );
      }
    } catch (e) {
      print('❌ [TIPS REPO] Exception in getAllTips: $e');
      return const Left(ServerFailure('Error obteniendo tips'));
    }
  }

  @override
  Future<Either<Failure, TipEntity>> getTipById(String id) async {
    try {
      print('🔍 [TIPS REPO] Getting tip by ID: $id');
      
      // Verificar caché primero
      final cachedTip = await _cacheService.get<Map<String, dynamic>>(
        '$_tipsCachePrefix$id',
      );
      
      if (cachedTip != null) {
        print('💾 [TIPS REPO] Found tip in cache');
        return Right(TipModel.fromJson(cachedTip));
      }
      
      // Si no está en caché, obtener de la API
      final tip = await _remoteDataSource.getTipById(id);
      
      // Guardar en caché
      await _cacheService.set(
        '$_tipsCachePrefix$id',
        tip.toJson(),
        duration: _cacheDuration,
      );
      
      print('✅ [TIPS REPO] Got tip from API and cached');
      return Right(tip);
    } on ServerException catch (e) {
      print('❌ [TIPS REPO] Server exception: $e');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('❌ [TIPS REPO] Exception getting tip by ID: $e');
      return const Left(ServerFailure('Error obteniendo tip'));
    }
  }

  @override
  Future<Either<Failure, List<TipEntity>>> getTipsByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('📂 [TIPS REPO] Getting tips by category: $category');
      
      // Primero intentar obtener todos los tips
      final allTipsResult = await getAllTips(limit: 100); // Obtener más para filtrar
      
      return allTipsResult.fold(
        (failure) => Left(failure),
        (allTips) {
          // Filtrar por categoría
          final filteredTips = allTips
              .where((tip) => tip.category.toLowerCase() == category.toLowerCase())
              .take(limit)
              .toList();
          
          print('✅ [TIPS REPO] Found ${filteredTips.length} tips for category: $category');
          return Right(filteredTips);
        },
      );
    } catch (e) {
      print('❌ [TIPS REPO] Exception getting tips by category: $e');
      return const Left(ServerFailure('Error obteniendo tips por categoría'));
    }
  }

  @override
  Future<Either<Failure, TipEntity>> getRandomTip({String? category}) async {
    try {
      print('🎲 [TIPS REPO] Getting random tip...');
      
      // Obtener tips (filtrados por categoría si se especifica)
      final tipsResult = category != null
          ? await getTipsByCategory(category)
          : await getAllTips(limit: 100);
      
      return tipsResult.fold(
        (failure) => Left(failure),
        (tips) {
          if (tips.isEmpty) {
            print('⚠️ [TIPS REPO] No tips available, using fallback');
            return Right(_getFallbackTips().first);
          }
          
          // Seleccionar tip aleatorio
          final random = Random();
          final randomTip = tips[random.nextInt(tips.length)];
          
          print('✅ [TIPS REPO] Selected random tip: ${randomTip.title}');
          return Right(randomTip);
        },
      );
    } catch (e) {
      print('❌ [TIPS REPO] Exception getting random tip: $e');
      return const Left(ServerFailure('Error obteniendo tip aleatorio'));
    }
  }

  @override
  Future<Either<Failure, List<TipEntity>>> getCachedTips() async {
    try {
      print('💾 [TIPS REPO] Getting cached tips...');
      
      final cachedData = await _cacheService.getList<Map<String, dynamic>>(
        _allTipsCacheKey,
      );
      
      if (cachedData != null && cachedData.isNotEmpty) {
        final tips = cachedData
            .map((tipData) => TipModel.fromJson(tipData))
            .cast<TipEntity>()
            .toList();
        
        print('✅ [TIPS REPO] Found ${tips.length} cached tips');
        return Right(tips);
      } else {
        print('⚠️ [TIPS REPO] No cached tips found');
        return const Left(CacheFailure('No hay tips en caché'));
      }
    } catch (e) {
      print('❌ [TIPS REPO] Exception getting cached tips: $e');
      return const Left(CacheFailure('Error accediendo a tips en caché'));
    }
  }

  @override
  Future<Either<Failure, bool>> cacheTips(List<TipEntity> tips) async {
    try {
      print('💾 [TIPS REPO] Caching ${tips.length} tips...');
      
      final tipsData = tips
          .map((tip) => TipModel.fromEntity(tip).toJson())
          .toList();
      
      final success = await _cacheService.setList(
        _allTipsCacheKey,
        tipsData,
        duration: _cacheDuration,
      );
      
      if (success) {
        print('✅ [TIPS REPO] Tips cached successfully');
        return const Right(true);
      } else {
        print('❌ [TIPS REPO] Failed to cache tips');
        return const Left(CacheFailure('Error guardando tips en caché'));
      }
    } catch (e) {
      print('❌ [TIPS REPO] Exception caching tips: $e');
      return const Left(CacheFailure('Error guardando tips en caché'));
    }
  }

  // Tips de respaldo cuando falla todo
  List<TipEntity> _getFallbackTips() {
    return [
      TipEntity(
        id: 'fallback_1',
        title: 'Consejo de Xico',
        content: '💡 Apaga luces y dispositivos que no uses. ¡Pequeños cambios, gran impacto!',
        category: 'energia',
        icon: '💡',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      TipEntity(
        id: 'fallback_2',
        title: 'Consejo de Xico',
        content: '🚿 Cierra la llave mientras te cepillas los dientes. Ahorras hasta 6 litros por minuto.',
        category: 'agua',
        icon: '🚿',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      TipEntity(
        id: 'fallback_3',
        title: 'Consejo de Xico',
        content: '♻️ Separa tu basura: orgánica, inorgánica y reciclables. ¡La Tierra te lo agradece!',
        category: 'reciclaje',
        icon: '♻️',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      TipEntity(
        id: 'fallback_4',
        title: 'Consejo de Xico',
        content: '🌱 Planta una semilla hoy. En el futuro será un árbol que purifique el aire.',
        category: 'naturaleza',
        icon: '🌱',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      TipEntity(
        id: 'fallback_5',
        title: 'Consejo de Xico',
        content: '🚗 Camina, usa bici o transporte público. ¡Tu planeta y tu salud lo agradecerán!',
        category: 'transporte',
        icon: '🚗',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }
}