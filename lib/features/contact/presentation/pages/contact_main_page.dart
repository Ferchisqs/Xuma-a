import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xuma_a/features/companion/presentation/cubit/companion_cubit.dart';
import 'package:xuma_a/features/companion/presentation/cubit/companion_shop_cubit.dart';
import 'package:xuma_a/features/companion/presentation/pages/companion_detail_page.dart';
import 'package:xuma_a/features/companion/presentation/pages/companion_shop_page.dart';
import 'package:xuma_a/features/companion/presentation/widgets/companion_animation_widget.dart';
import 'package:xuma_a/features/companion/presentation/widgets/companion_stats_widget.dart';
import '../../../../di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../../../companion/presentation/widgets/companion_card_widget.dart';  

class CompanionMainPage extends StatelessWidget {
  const CompanionMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<CompanionCubit>()..loadCompanions(),
        ),
        BlocProvider(
          create: (context) => getIt<CompanionShopCubit>(),
        ),
      ],
      child: const _CompanionMainView(),
    );
  }
}

class _CompanionMainView extends StatelessWidget {
  const _CompanionMainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SideNavBar(),
      appBar: AppBar(
        title: const Text('Compañeros'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white), 
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        // 🔧 SIN BOTÓN DE RESET - SOLO REFRESH NORMAL
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: () {
              debugPrint('🔄 [MAIN] Refresh normal solicitado');
              context.read<CompanionCubit>().refreshCompanions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CompanionCubit, CompanionState>(
          builder: (context, state) {
            if (state is CompanionLoading) {
              return const _LoadingView();
            } else if (state is CompanionError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CompanionCubit>().loadCompanions(),
              );
            } else if (state is CompanionLoaded) {
              return _LoadedView(state: state);
            }

            return const _LoadingView();
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando tus compañeros...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    Key? key,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops, algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CompanionLoaded state;

  const _LoadedView({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 [MAIN] Mostrando vista cargada con ${state.ownedCompanions.length} compañeros');

    return CustomScrollView(
      slivers: [
        // 📊 ESTADÍSTICAS DEL USUARIO (CON BOTÓN TIENDA)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CompanionStatsWidget(
              stats: state.userStats,
              onShopTap: () => _navigateToShop(context),
            ),
          ),
        ),

        // 🐾 COMPAÑERO ACTIVO (SI EXISTE)
        if (state.activeCompanion != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tu Compañero Activo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      // 🛍️ BOTÓN TIENDA MÁS PROMINENTE
                      ElevatedButton.icon(
                        onPressed: () => _navigateToShop(context),
                        icon: const Icon(Icons.store, size: 18),
                        label: const Text('Tienda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActiveCompanionCard(context, state.activeCompanion!),
                ],
              ),
            ),
          ),
        ],

        // 🏠 LISTA DE COMPAÑEROS PROPIOS
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Compañeros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // 🛍️ BOTÓN OBTENER MÁS
                TextButton.icon(
                  onPressed: () => _navigateToShop(context),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Obtener más',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 📋 GRID DE COMPAÑEROS O MENSAJE VACÍO
        if (state.ownedCompanions.isNotEmpty)
          _buildCompanionsGrid(context, state.ownedCompanions)
        else
          _buildEmptyCompanionsView(context),
      ],
    );
  }

  // 🔧 TARJETA DEL COMPAÑERO ACTIVO (SOLO MASCOTA PNG)
  Widget _buildActiveCompanionCard(BuildContext context, companion) {
    return GestureDetector(
      onTap: () => _navigateToDetail(context, companion),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 🏷️ NOMBRE
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  companion.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // 📊 INFO
            Positioned(
              top: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${companion.typeDescription} ${companion.stageDisplayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel ${companion.level} • ${companion.experience}/${companion.experienceNeededForNextStage} EXP',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // 🐾 MASCOTA (SOLO PNG - SIN FONDO)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: CompanionAnimationWidget(
                  companion: companion,
                  size: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),

            // ➡️ FLECHA PARA IR AL DETALLE
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionsGrid(BuildContext context, List companions) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final companion = companions[index];
            return CompanionCardWidget(
              companion: companion,
              onTap: () => _navigateToDetail(context, companion),
              isSelected: companion.isSelected,
            );
          },
          childCount: companions.length,
        ),
      ),
    );
  }

  Widget _buildEmptyCompanionsView(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes compañeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Visita la tienda para conseguir tu primer compañero!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            // 🛍️ BOTÓN PROMINENTE PARA IR A LA TIENDA
            ElevatedButton.icon(
              onPressed: () => _navigateToShop(context),
              icon: const Icon(Icons.store),
              label: const Text('Ir a la Tienda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, companion) {
    debugPrint('🔍 [MAIN] Navegando al detalle de: ${companion.displayName}');
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CompanionDetailPage(companion: companion),
      ),
    )
        .then((_) {
      // 🔄 REFRESCAR CUANDO REGRESE DEL DETALLE
      debugPrint('🔄 [MAIN] Regresando del detalle - refrescando compañeros');
      context.read<CompanionCubit>().refreshCompanions();
    });
  }

  void _navigateToShop(BuildContext context) {
    debugPrint('🏪 [MAIN] === NAVEGANDO A LA TIENDA ===');
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CompanionShopPage(),
      ),
    )
        .then((_) {
      debugPrint('🔄 [MAIN] === REGRESANDO DE LA TIENDA ===');
      debugPrint('🔄 [MAIN] Refrescando compañeros después de tienda...');
      
      // 🔄 REFRESH INMEDIATO
      context.read<CompanionCubit>().refreshCompanions();
      
      // 🔄 REFRESH ADICIONAL DESPUÉS DE UN MOMENTO
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          debugPrint('🔄 [MAIN] Refresh adicional para asegurar sincronización');
          context.read<CompanionCubit>().loadCompanions();
        }
      });
    });
  }
}