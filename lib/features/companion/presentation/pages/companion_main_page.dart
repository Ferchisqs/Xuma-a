import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/side_nav_bar.dart';
import '../cubit/companion_cubit.dart';
import '../cubit/companion_shop_cubit.dart';
import '../widgets/companion_animation_widget.dart';
import '../widgets/companion_card_widget.dart';
import '../widgets/companion_stats_widget.dart';
import 'companion_detail_page.dart';
import 'companion_shop_page.dart';

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
        iconTheme: const IconThemeData(
        color: Colors.white), 
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset de Desarrollo - Desbloquear Todo',
            onPressed: () => _resetCompanionSystem(context),
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

  Future<void> _resetCompanionSystem(BuildContext context) async {
    debugPrint('🗑️ [RESET] === REINICIANDO SISTEMA DE COMPAÑEROS ===');

    try {
      final shouldReset = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.blue),
              SizedBox(width: 8),
              Text('🔧 Reset de Desarrollo'),
            ],
          ),
          content: const Text(
            '¿Quieres reiniciar completamente el sistema de compañeros?\n\n'
            'Esto regenerará todos los datos con:\n'
            '• Todos los compañeros desbloqueados\n'
            '• 999,999 puntos disponibles\n'
            '• Todas las animaciones listas\n\n'
            'Perfecto para testing y desarrollo! 🎮',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('🚀 Reset Todo',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldReset == true) {
        debugPrint('🗑️ [RESET] Usuario confirmó reset');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 16),
                Text(
                  '🎮 Desbloqueando todos tus compañeros...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          debugPrint('🔄 [RESET] Recargando CompanionCubit...');
          context.read<CompanionCubit>().loadCompanions();

          await Future.delayed(const Duration(milliseconds: 500));

          // Mostrar  de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.pets, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 ¡Sistema reiniciado! Todos tus pequeñines están listos para jugar!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VER',
                textColor: Colors.white,
                onPressed: () {
                  // Opcional: scrollear al primer compañero o algo así
                },
              ),
            ),
          );
        }

        debugPrint('✅ [RESET] === RESET COMPLETADO EXITOSAMENTE ===');
      } else {
        debugPrint('❌ [RESET] Usuario canceló el reset');
      }
    } catch (e) {
      debugPrint('❌ [RESET] Error durante reset: $e');
      if (context.mounted) {
        // Cerrar cualquier diálogo abierto
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Error durante reset: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Resto de las clases _LoadingView, _ErrorView, _LoadedView permanecen igual...

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
    debugPrint(
        '📱 [MAIN] Mostrando vista cargada con ${state.ownedCompanions.length} compañeros');

    return CustomScrollView(
      slivers: [
        // Estadísticas del usuario
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CompanionStatsWidget(
              stats: state.userStats,
              onShopTap: () => _navigateToShop(context),
            ),
          ),
        ),

        // Compañero activo (si existe)
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
                      TextButton.icon(
                        onPressed: () => _navigateToShop(context),
                        icon: const Icon(Icons.store, color: AppColors.primary),
                        label: const Text(
                          'Tienda',
                          style: TextStyle(color: AppColors.primary),
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

        // Lista de compañeros propios
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

        // Grid de compañeros
        if (state.ownedCompanions.isNotEmpty)
          _buildCompanionsGrid(context, state.ownedCompanions)
        else
          _buildEmptyCompanionsView(context),
      ],
    );
  }

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
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: CompanionAnimationWidget(
                  companion: companion,
                  size: MediaQuery.of(context).size.width * 0.7,
                ),
              ),
            ),

            // Botón para ir al detalle en la parte inferior derecha
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
            ElevatedButton.icon(
              onPressed: () => _navigateToShop(context),
              icon: const Icon(Icons.store),
              label: const Text('Ir a la Tienda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, companion) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CompanionDetailPage(companion: companion),
      ),
    )
        .then((_) {
      // Refrescar cuando regrese del detalle
      context.read<CompanionCubit>().refreshCompanions();
    });
  }

  void _navigateToShop(BuildContext context) {
    debugPrint('🏪 [MAIN] Navegando a la tienda...');
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CompanionShopPage(),
      ),
    )
        .then((_) {
      debugPrint('🔄 [MAIN] Regresando de la tienda - REFRESCANDO TODO...');
      context.read<CompanionCubit>().refreshCompanions();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          debugPrint('🔄 [MAIN] Refresh adicional...');
          context.read<CompanionCubit>().loadCompanions();
        }
      });
    });
  }
}
